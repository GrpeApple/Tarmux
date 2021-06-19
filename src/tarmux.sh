#!/data/data/com.termux/files/usr/bin/env bash

# Shellcheck
# shellcheck source=/dev/null

set -eou pipefail

readonly VERSION='v0.4.5.1'

if test \( "${BASH_VERSINFO[0]}" -lt '4' \) -a \( "${BASH_VERSINFO[1]}" -lt '4' \); then
	echo "Bash version ${BASH_VERSION} is too low! Need bash version 4.4 or higher."
	exit 1
elif test "$(id -u)" -eq '0'; then
	echo 'Running this script as root is very dangerous! Try setting the permissions instead.'
	exit 1
fi

# Colors
## Prefixes
### B = Bold
### K = Background
declare -r -A color=(
	['RED']='\e[0;31m'
	['GREEN']='\e[0;32m'
	['CYAN']='\e[0;36m'
	['BRED']='\e[1;31m'
	['BGREEN']='\e[1;32m'
	['BYELLOW']='\e[1;33m'
	['BBLUE']='\e[1;34m'
	['BCYAN']='\e[1;36m'
	['BWHITE']='\e[1;37m'
	['KBLACK']='\e[40m'
	['RESET']='\e[0m'
)

# Implement dry-run principle
colors () {
	## Here is what it does:
	### The first parameter is the color
	### The second and the number of arguments subtracted by 1 (1st is color)
	test "${#}" -lt '3' && last=( "${@: -1}" )
	printf "${color["${1:-}"]}${color['KBLACK']}%s${color['RESET']}" "${2:-}" "${last:+"${@:3:$(("${#}" -1))}"}"; test "${2: -1}" == ':' || printf '\n'
}

# Check shell options
case "${-}" in
	*'r'*) colors 'BYELLOW' 'WARNING: shell in restricted mode.' 1>&2;;
	*'p'*) colors 'BYELLOW' 'WARNING: shell in POSIX mode.' 1>&2;;
esac

# Configuration
## tarmux preferences
declare +r -A config=(
	['INSTALL']="$(realpath "${0:-tarmux}")"
	['TAR_TOOL']='tar'
	['TAR_OPTIONS']=''
	['TAR_ENV']=''
	['BACKUP_TOOL']='tar'
	['BACKUP_OPTIONS']='-z'
	['BACKUP_ENV']=''
	['BACKUP_PIPE']='false'
	['RESTORE_TOOL']='tar'
	['RESTORE_OPTIONS']='-z'
	['RESTORE_ENV']=''
	['RESTORE_PIPE']='false'
	['TARMUX_ROOT']='/data/data/com.termux/files'
	['TARMUX_DATA']='/storage/emulated/0/Download'
	['TARMUX_NAME']='termux_backup_%Y-%m-%d_%H-%M-%S-%N'
	['TARMUX_EXT']='.bak'
	['TARMUX_LIST']='home|usr'
	['TARMUX_IFS']='|'
	['REQUEST_STORAGE']='true'
	['ALWAYS_SAVE']='true'
)

## tarmux preferences name
declare -r -A config_name=(
	['INSTALL']='Installation directory'
	['TAR_TOOL']='tar tool'
	['TAR_OPTIONS']='tar options'
	['TAR_ENV']='tar environment variables'
	['BACKUP_TOOL']='Backup tool'
	['BACKUP_OPTIONS']='Backup options'
	['BACKUP_ENV']='Backup environment variables'
	['BACKUP_PIPE']='Always use pipes for backup'
	['RESTORE_TOOL']='Restore tool'
	['RESTORE_OPTIONS']='Restore options'
	['RESTORE_ENV']='Restore environment variables'
	['RESTORE_PIPE']='Always use pipes for restore'
	['TARMUX_ROOT']='Tarmux backup root directory'
	['TARMUX_DATA']='Tarmux backup data directory'
	['TARMUX_NAME']='Tarmux backup name'
	['TARMUX_EXT']='Tarmux backup extension'
	['TARMUX_LIST']='Tarmux bakup directories'
	['TARMUX_IFS']='Tarmux backup directories separator'
	['REQUEST_STORAGE']='Always ask storage permission'
	['ALWAYS_SAVE']='Always save config'
)

## Config location
readonly CONFIG_DIR="${HOME}/.config/tarmux"
readonly CONFIG_FILE='config'

# Incase if config location does not exist.
mkdir --parents "${CONFIG_DIR}" || exit 1
touch "${CONFIG_DIR}/${CONFIG_FILE}" || exit 1

# Backup variables before sourcing.
INSTALL="${config['INSTALL']}"

# You are responsible for putting dangerous stuff in the config file.
source "${CONFIG_DIR}/${CONFIG_FILE}"

# Check if INSTALL changed
if [[ "${INSTALL}" != "${config['INSTALL']}" ]]; then
	readarray warning <<-EOW
		WARNING: moving ${INSTALL} to ${config['INSTALL']}.
		Use ${0:-tarmux} -c and select 'Installation directory' to move; or use ${0:-tarmux} -c and select 'reset' then move it to the desired location.
		You can also use '--configure' instead of '-c'.
	EOW
	colors 'BYELLOW' "${warning[@]}" 1>&2
	## Do not treat config file as moving to a directory; Always be a file.
	mv --interactive --no-target-directory "${INSTALL}" "${config['INSTALL']}"
fi

# Options for tarmux
read -r -a opt <<< "$(getopt --options 'hvb::r::cV' --alternative --longoptions 'help,verbose,backup::,restore::,configure,version' --name 'tarmux' --shell 'bash' -- "${@:---}")"
eval set -- "${opt[@]}"

# Working directory
CWD="${PWD}"

# Configuration
## Installation
ACTIONS=('install' 'uninstall' 'tarmux')

### Packages
PACKAGES=('tar' 'pigz' 'zstd')

## Configuration for tarmux
CONFIGURATIONS=('Installation directory' 'Tar' 'Backup' 'Restore' 'tarmux backup root directory' 'tarmux backup data directory' 'tarmux backup name' 'tarmux backup extension' 'tarmux backup directories' 'tarmux backup directories separator' 'Always ask storage permission' 'Always save config' 'save' 'reset')
TAR_CONFIGURATIONS=('Tool' 'Options' 'Environment variables')
BACKUP_CONFIGURATIONS=('Backup tool' 'Backup options' 'Backup environment variables' 'Always use pipes for backup')
RESTORE_CONFIGURATIONS=('Restore tool' 'Restore options' 'Restore environment variables' 'Always use pipes for restore')
BACKUP_TOOLS=('tar' 'pigz' 'zstd')
RESTORE_TOOLS=('tar' 'pigz' 'zstd')

# Save configuration
save_config () {
	test "${config['ALWAYS_SAVE']:-false}" == 'true' && cat 1> "${CONFIG_DIR}/${CONFIG_FILE}" <<-EOC
		# $(date +'Saved config on %c %:::z')
		# DO NOT EDIT THIS FILE!
		# Unless, you know what you are doing.
		$(for key in "${!config[@]}"; do echo "config['${key}']='${config[${key}]}'"; done)
	EOC
}

# Option management
options () {
	while true; do
		case "${1:-}" in
			'-h'|'--help') usage; break 1;;
			'-v'|'--verbose')
				TAR_OPTIONS+=( '--verbose' )
				shift 1
				continue 1
				;;

			'-b'|'--backup')
				if test -z "${2:-}"; then
					backup
				elif test \( -w "$(dirname "${2:-}")" \) -o \( -w "${2:-}" \); then
					backup "${2:-}"
				else
					colors 'BRED' "File '${2:-}' is not writable." 1>&2
					return 1
				fi
				shift 2
				continue 1
				;;

			'-r'|'--restore')
				if test -z "${2:-}"; then
					restore
				elif test -r "${2:-}"; then
					restore "${2:-}"
				else
					colors 'BRED' "File '${2:-}' does not exist or unreadable." 1>&2
					return 1
				fi
				shift 2
				continue 1
				;;

			'-c'|'--configure') configure; shift 1; continue 1;;
			'-V'|'--version') version; shift 1; continue 1;;
			'--') test -z "${opt[1]:-}" && usage; shift 1; break 1;; ## Check if no options, then display usage.
			*) colors 'BRED' 'Unknown error' 1>&2; return 1;; ## This should not happen.
		esac
	done
}

# Help message
usage () {
readarray options <<EOU
	-[h|[-]help]			Display this help usage; exit immediately and not parsing the next following options
	-[v|[-]verbose]			Enable verbose output for the next following options
	-[b|[-]backup][=BACKUP]		Backup to BACKUP file
	-[r|[-]restore][=BACKUP]	Restore from RESTORE file
	-[c|[-]configure]		Configure your config
	-[V|[-]version]			Display version and information

		BACKUP			Can be anything; has control characters from date
		RESTORE			Can be anywhere
EOU
	colors 'BCYAN' "Usage: $(basename "${config['INSTALL']}") -[[h|[-]help]|[[v|[-]verbose]]|[b|[-]backup[=BACKUP]]|[r|[-]restore[=BACKUP]]|[c|[-]configure]|[V|[-]version]]"
	colors 'BBLUE' 'Options:'; printf '\n'
	colors 'BWHITE' "${options[@]}"
}

# Backup
backup () {
	if test -n "${1:-}"; then
		backup_name="$(date +"${1:-}")"
	else
		backup_name="${config['TARMUX_DATA']}/$(date +"${config['TARMUX_NAME']}")${config['TARMUX_EXT']}"
	fi
	backup_name="$(realpath "${backup_name}")"

	read -r -a tar_env <<< "${config['TAR_ENV']}"
	read -r -a tar_options <<< "${config['TAR_OPTIONS']} ${TAR_OPTIONS[@]}"
	read -r -a tar_tool <<< "${config['TAR_TOOL']}"
	IFS="${config['TARMUX_IFS']}" read -r -a backup_directories <<< "${config['TARMUX_LIST']}"
	if test "${config['BACKUP_PIPES']:-false}" == 'true'; then
		read -r -a backup_env <<< "${config['BACKUP_ENV']}"
		read -r -a backup_tool <<< "${config['BACKUP_TOOL']}"
		read -r -a backup_options <<< "${config['BACKUP_OPTIONS']}"
	fi
readarray backup_prompt <<EOP
	Tar tool: '${config['TAR_TOOL']}'
	Tar options: '${config['TAR_OPTIONS']}'
	Tar environment variables: '${config['TAR_ENV']}'
	Tool: '${config['BACKUP_TOOL']}'
	Options: '${config['BACKUP_OPTIONS']}'
	Environment variables: '${config['BACKUP_ENV']}'
	Pipe mode: '$(test "${config['BACKUP_PIPES']:-false}" == 'true' && echo 'true' || echo 'false')'
	Root directory: '${config['TARMUX_ROOT']}'
	Backup location: '${config['TARMUX_DATA']}'
	Backup: '${backup_name}'
	Directories: ${backup_directories[@]}
EOP
	colors 'BCYAN' 'Backing up...'
	colors 'CYAN' "${backup_prompt[@]}"

	cd "${config['TARMUX_ROOT']}" || colors 'BRED' 'Terminating...' 1>&2 || exit 1

	case "${config['BACKUP_TOOL']}" in
		'tar')
			"${tar_env[@]}" "${tar_tool}" "${tar_options[@]}" "${config['BACKUP_OPTIONS']}" --create "${backup_directories[@]}" --file="${backup_name}"
			;;

		'pigz'|'zstd'|*)
			if test "${config['BACKUP_PIPES']:-false}" == 'true'; then
				"${tar_env[@]}" "${tar_tool}" "${tar_options[@]}" --create "${backup_directories[@]}" --file='-' | "${backup_env[@]}" "${backup_tool[@]}" "${backup_options[@]}" 1> "${backup_name}"
			else
				"${tar_env[@]}" "${tar_tool}" "${tar_options[@]}" --create "${backup_directories[@]}" --file="${backup_name}" --use-compress-program="${config['BACKUP_ENV']} ${config['BACKUP_TOOL']} ${config['BACKUP_OPTIONS']}"
			fi
			;;

	esac || rm -f "${backup_name}"

	cd "${CWD}" || colors 'BRED' 'Terminating...' 1>&2 || exit 1
}

# Restore
restore () {
	## File explorer
	explorer () {
		cd "$(dirname "${config['TARMUX_DATA']}")" || colors 'BRED' 'Error going to current config tarmux data directory.' 1>&2
		while true; do
			local glob
			glob="$(compgen -G './'* 1>/dev/null 2>&1 && echo '1')"
			select filename in 'clear' 'exit' "${PWD}" '..' ${glob:+*}; do
				case "${filename},${REPLY:-}" in
					'clear',*|*,'clear'|*,) clear; break 1;;
					'exit',*|*,'exit') colors 'BRED' 'Exiting restoring Termux...'; return 1;;
					'/',*|*,'/')
						read -e -i'/' ### No -r to accept escaping
						REPLY="$(echo "${REPLY:-}" | xargs)" ### Trim whitespace
						if test ! -d "${REPLY}"; then
							restore_name="$(realpath "${REPLY}")"
							break 2
						else
							cd "${REPLY}" || true
							break 1
						fi
						;;

					'..',*|*,'..') cd .. || true; break 1;;
					*,*)
						filename="$(echo "${filename:-"${REPLY:-}"}" | xargs)" ### Trim whitespace
						if test ! -d "${filename}"; then
							restore_name="$(realpath "${filename}")"
							break 2
						else
							cd "${filename}" || true
							break 1
						fi
						;;
				esac
			done
		done
		cd "${CWD}" || colors 'BRED' 'Error going to previous working directory.' 1>&2
	}

	if test -n "${1:-}"; then
		restore_name="$(realpath "${1:-/dev/null}")"
	else
		explorer || return 1
	fi

	read -r -a tar_env <<< "${config['TAR_ENV']}"
	read -r -a tar_options <<< "${config['TAR_OPTIONS']} ${TAR_OPTIONS[@]}"
	read -r -a tar_tool <<< "${config['TAR_TOOL']}"
	IFS="${config['TARMUX_IFS']}" read -r -a restore_directories <<< "${config['TARMUX_LIST']}"
	if test "${config['RESTORE_PIPES']:-false}" == 'true'; then
		read -r -a restore_env <<< "${config['RESTORE_ENV']}"
		read -r -a restore_tool <<< "${config['RESTORE_TOOL']}"
		read -r -a restore_options <<< "${config['RESTORE_OPTIONS']}"
	fi
readarray restore_prompt <<EOP
	Tar tool: '${config['TAR_TOOL']}'
	Tar options: '${config['TAR_OPTIONS']}'
	Tar environment variables: '${config['TAR_ENV']}'
	Tool: '${config['RESTORE_TOOL']}'
	Options: '${config['RESTORE_OPTIONS']}'
	Environment variables: '${config['RESTORE_ENV']}'
	Pipe mode: '$(test "${config['RESTORE_PIPES']:-false}" == 'true' && echo 'true' || echo 'false')'
	Root directory: '${config['TARMUX_ROOT']}'
	Restore: '${restore_name}'
	Directories: ${restore_directories[@]}
EOP
	colors 'BCYAN' 'Restoring...'
	colors 'CYAN' "${restore_prompt[@]}"

	cd "${config['TARMUX_ROOT']}" || colors 'BRED' 'Terminating...' 1>&2 || exit 1

	case "${config['RESTORE_TOOL']}" in
		'tar')
			"${tar_env[@]}" "${tar_tool}" "${tar_options[@]}" "${config['RESTORE_OPTIONS']}" --extract "${restore_directories[@]}" --file="${restore_name}"
			;;

		'pigz'|'zstd')
			if test "${config['RESTORE_PIPES']:-false}" == 'true'; then
				"${restore_env[@]}" "${restore_tool[@]}" "${restore_options[@]}" --decompress "${restore_name}" | tar "${tar_options[@]}" --extract "${restore_directories[@]}" --file='-'
			else
				"${tar_env[@]}" "${tar_tool}" "${tar_options[@]}" --extract "${restore_directories[@]}" --file="${restore_name}" --use-compress-program="${config['RESTORE_ENV']} ${config['RESTORE_TOOL']} ${config['RESTORE_OPTIONS']}"
			fi
			;;

		*)
			if test "${config['RESTORE_PIPES']:-false}" == 'true'; then
				"${restore_env[@]}" "${restore_tool[@]}" "${restore_options[@]}" "${restore_name}" | tar "${tar_options[@]}" --extract "${restore_directories[@]}" --file='-'
			else
				"${tar_env[@]}" "${tar_tool}" "${tar_options[@]}" --extract "${restore_directories[@]}" --file="${restore_name}" --use-compress-program="${config['RESTORE_ENV']} ${config['RESTORE_TOOL']} ${config['RESTORE_OPTIONS']}"
			fi
			;;

	esac

	cd "${CWD}" || colors 'BRED' 'Terminating...' 1>&2 || exit 1
}

# Configuration
configure () {
	## Installation
	installPkg () {
		while true; do
			select package in 'update' 'upgrade' 'repository' 'manual' "${PACKAGES[@]}" 'clear' 'exit'; do
				case "${package},${REPLY:-}" in
					'update',*|*,'update') colors 'BWHITE' 'Updating apt...'; apt update && colors 'BGREEN' 'Done!'; break 1;;
					'upgrade',*|*,'upgrade') colors 'BWHITE' 'Upgrading packages...'; apt full-upgrade && colors 'BGREEN' 'Done!'; break 1;;
					'repository',*|*,'repository') colors 'BWHITE' "Changing Termux's repositories..."; termux-change-repo && colors 'BGREEN' 'Done!'; break 1;;
					'manual',*|*,'manual') colors 'BWHITE' 'Package to install? ():'; read -p ' ' -r -e package; apt install "${package}" && colors 'BGREEN' 'Done!'; break 1;;
					'tar',*|*,'tar') colors 'BWHITE' 'Installing tar...'; apt install tar && colors 'BGREEN' 'Done!'; break 1;;
					'pigz',*|*,'pigz') colors 'BWHITE' 'Installing pigz...'; apt install pigz && colors 'BGREEN' 'Done!'; break 1;;
					'zstd',*|*,'zstd') colors 'BWHITE' 'Installing zstd...'; apt install zstd && colors 'BGREEN' 'Done!'; break 1;;
					'clear',*|*,'clear'|*,) clear; break 1;;
					'exit',*|*,'exit') colors 'BRED' 'Exiting installation...'; break 2;;
					*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
				esac
			done
		done
	}
	## Uninstallation
	uninstallPkg () {
		while true; do
			select package in 'manual' "${PACKAGES[@]}" 'clear' 'exit'; do
				case "${package},${REPLY:-}" in
					'manual',*|*,'manual') colors 'BWHITE' 'Package to uninstall? ():'; read -p ' ' -r -e package; apt autoremove "${package}" && colors 'BGREEN' 'Done!'; break 1;;
					'tar',*|*,'tar') colors 'BRED' 'Uninstalling tar (dangerous)...'; apt autoremove tar && colors 'BGREEN' 'Done!'; break 1;;
					'pigz',*|*,'pigz') colors 'BWHITE' 'Uninstalling pigz...'; apt autoremove pigz && colors 'BGREEN' 'Done!'; break 1;;
					'zstd',*|*,'zstd') colors 'BWHITE' 'Uninstalling zstd...'; apt autoremove zstd && colors 'BGREEN' 'Done!'; break 1;;
					'clear',*|*,'clear'|*,) clear; break 1;;
					'exit',*|*,'exit') colors 'BRED' 'Exiting uninstallation...'; break 2;;
					*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
				esac
			done
		done
	}
	## Tar configuration
	tarConf () {
		while true; do
			select configuration in "${TAR_CONFIGURATIONS[@]}" 'clear' 'exit'; do
				case "${configuration},${REPLY:-}" in
					'Tool',*|*,'Tool')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'change',*|*,'change')
										colors 'BWHITE' "Tar tool to use? ('${config['TAR_TOOL']}'):"
										read -p ' ' -r -e TAR_TOOL
										colors 'BWHITE' "Changing tar tool '${config['TAR_TOOL']}' to '${TAR_TOOL:-"${config['TAR_TOOL']}"}'..."
										config['TAR_TOOL']="${TAR_TOOL:-"${config['TAR_TOOL']}"}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['TAR_TOOL']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting tar tool configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Options',*|*,'Options')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'change',*|*,'change')
										colors 'BWHITE' "What tar options? ('${config['TAR_OPTIONS']}'):"
										read -p ' ' -r -e TAR_OPTIONS
										colors 'BWHITE' "Changing tar options '${config['TAR_OPTIONS']}' to '${TAR_OPTIONS-${config['TAR_OPTIONS']}}'..."
										config['TAR_OPTIONS']="${TAR_OPTIONS-${config['TAR_OPTIONS']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['TAR_OPTIONS']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting backup options configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Environment variables',*|*,'Environment variables')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'change',*|*,'change')
										colors 'BWHITE' "What tar environment variables? ('${config['TAR_ENV']}'):"
										read -p ' ' -r -e TAR_ENV
										colors 'BWHITE' "Changing tar environment variables '${config['TAR_ENV']}' to '${TAR_ENV-${config['TAR_ENV']}}'..."
										config['TAR_ENV']="${TAR_ENV-${config['TAR_ENV']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['TAR_ENV']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting tar environment variables configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'clear',*|*,'clear'|*,) clear; break 1;;
					'exit',*|*,'exit') colors 'BRED' 'Exiting tar configuration...'; break 2;;
					*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
				esac
			done
		done
	}
	## Backup configuration
	backupConf () {
		while true; do
			select configuration in "${BACKUP_CONFIGURATIONS[@]}" 'clear' 'exit'; do
				case "${configuration},${REPLY:-}" in
					'Backup tool',*|*,'Backup tool')
						while true; do
							select tool in 'manual' "${BACKUP_TOOLS[@]}" 'view' 'clear' 'exit'; do
								case "${tool},${REPLY:-}" in
									'manual',*|*,'manual')
										colors 'BWHITE' "Backup tool to use? ('${config['BACKUP_TOOL']}'):"
										read -p ' ' -r -e BACKUP_TOOL
										colors 'BWHITE' "Changing backup tool '${config['BACKUP_TOOL']}' to '${BACKUP_TOOL:-"${config['BACKUP_TOOL']}"}'..."
										config['BACKUP_TOOL']="${BACKUP_TOOL:-"${config['BACKUP_TOOL']}"}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'tar',*|*,'tar')
										local BACKUP_TOOL='tar'
										colors 'BWHITE' "Changing backup tool '${config['BACKUP_TOOL']}' to '${BACKUP_TOOL:-"${config['BACKUP_TOOL']}"}'..."
										config['BACKUP_TOOL']="${BACKUP_TOOL:-"${config['BACKUP_TOOL']}"}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'pigz',*|*,'pigz')
										local BACKUP_TOOL='pigz'
										colors 'BWHITE' "Changing backup tool '${config['BACKUP_TOOL']}' to '${BACKUP_TOOL:-"${config['BACKUP_TOOL']}"}'..."
										config['BACKUP_TOOL']="${BACKUP_TOOL:-"${config['BACKUP_TOOL']}"}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'zstd',*|*,'zstd')
										local BACKUP_TOOL='zstd'
										colors 'BWHITE' "Changing backup tool '${config['BACKUP_TOOL']}' to '${BACKUP_TOOL:-"${config['BACKUP_TOOL']}"}'..."
										config['BACKUP_TOOL']="${BACKUP_TOOL:-"${config['BACKUP_TOOL']}"}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['BACKUP_TOOL']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting backup tool configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Backup options',*|*,'Backup options')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'change',*|*,'change')
										colors 'BWHITE' "What backup options? ('${config['BACKUP_OPTIONS']}'):"
										read -p ' ' -r -e BACKUP_OPTIONS
										colors 'BWHITE' "Changing backup options '${config['BACKUP_OPTIONS']}' to '${BACKUP_OPTIONS-${config['BACKUP_OPTIONS']}}'..."
										config['BACKUP_OPTIONS']="${BACKUP_OPTIONS-${config['BACKUP_OPTIONS']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['BACKUP_OPTIONS']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting backup options configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Backup environment variables',*|*,'Backup environment variables')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'change',*|*,'change')
										colors 'BWHITE' "What backup environment variables? ('${config['BACKUP_ENV']}'):"
										read -p ' ' -r -e BACKUP_ENV
										colors 'BWHITE' "Changing backup environment variables '${config['BACKUP_ENV']}' to '${BACKUP_ENV-${config['BACKUP_ENV']}}'..."
										config['BACKUP_ENV']="${BACKUP_ENV-${config['BACKUP_ENV']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['BACKUP_ENV']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting backup environment variables configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Always use pipes for backup',*|*,'Always use pipes for backup')
						while true; do
							select option in 'enable' 'disable' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'enable',*|*,'enable')
										colors 'BGREEN' 'Enabling...'
										config['BACKUP_PIPES']='true'
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'disable',*|*,'disable')
										colors 'BRED' 'Disabling...'
										config['BACKUP_PIPES']='false'
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: $(test "${config['BACKUP_PIPES']:-false}" == 'true' && echo 'true' || echo 'false')"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting using pipes for backing up configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'clear',*|*,'clear'|*,) clear; break 1;;
					'exit',*|*,'exit') colors 'BRED' 'Exiting backup configuration...'; break 2;;
					*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
				esac
			done
		done
	}
	## Restore configuration
	restoreConf () {
		while true; do
			select configuration in "${RESTORE_CONFIGURATIONS[@]}" 'clear' 'exit'; do
				case "${configuration},${REPLY:-}" in
					'Restore tool',*|*,'Restore tool')
						while true; do
							select tool in 'manual' "${RESTORE_TOOLS[@]}" 'view' 'clear' 'exit'; do
								case "${tool},${REPLY:-}" in
									'manual',*|*,'manual')
										colors 'BWHITE' "Restore tool to use? ('${config['RESTORE_TOOL']}'):"
										read -p ' ' -r -e RESTORE_TOOL
										colors 'BWHITE' "Changing restore tool '${config['RESTORE_TOOL']}' to '${RESTORE_TOOL:-"${config['RESTORE_TOOL']}"}'..."
										config['RESTORE_TOOL']="${RESTORE_TOOL:-"${config['RESTORE_TOOL']}"}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'tar',*|*,'tar')
										local RESTORE_TOOL='tar'
										colors 'BWHITE' "Changing restore tool '${config['RESTORE_TOOL']}' to '${RESTORE_TOOL:-"${config['RESTORE_TOOL']}"}'..."
										config['RESTORE_TOOL']="${RESTORE_TOOL:-"${config['RESTORE_TOOL']}"}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'pigz',*|*,'pigz')
										local RESTORE_TOOL='pigz'
										colors 'BWHITE' "Changing restore tool '${config['RESTORE_TOOL']}' to '${RESTORE_TOOL:-"${config['RESTORE_TOOL']}"}'..."
										config['RESTORE_TOOL']="${RESTORE_TOOL:-"${config['RESTORE_TOOL']}"}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'zstd',*|*,'zstd')
										local RESTORE_TOOL='zstd'
										colors 'BWHITE' "Changing restore tool '${config['RESTORE_TOOL']}' to '${RESTORE_TOOL:-"${config['RESTORE_TOOL']}"}'..."
										config['RESTORE_TOOL']="${RESTORE_TOOL:-"${config['RESTORE_TOOL']}"}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['RESTORE_TOOL']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting restore tool configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Restore options',*|*,'Restore options')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'change',*|*,'change')
										colors 'BWHITE' "What options? ('${config['RESTORE_OPTIONS']}'):"
										read -p ' ' -r -e RESTORE_OPTIONS
										colors 'BWHITE' "Changing restore options '${config['RESTORE_OPTIONS']}' to '${RESTORE_OPTIONS-${config['RESTORE_OPTIONS']}}'..."
										config['RESTORE_OPTIONS']="${RESTORE_OPTIONS-${config['RESTORE_OPTIONS']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['RESTORE_OPTIONS']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting restore options configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Restore environment variables',*|*,'Restore environment variables')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'change',*|*,'change')
										colors 'BWHITE' "What restore environment variables? ('${config['RESTORE_ENV']}'):"
										read -p ' ' -r -e RESTORE_ENV
										colors 'BWHITE' "Changing restore environment variables '${config['RESTORE_ENV']}' to '${RESTORE_ENV-${config['RESTORE_ENV']}}'..."
										config['RESTORE_ENV']="${RESTORE_ENV-${config['RESTORE_ENV']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['RESTORE_ENV']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting restore environment variables configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Always use pipes for restore',*|*,'Always use pipes for restore')
						while true; do
							select option in 'enable' 'disable' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'enable',*|*,'enable')
										colors 'BGREEN' 'Enabling...'
										config['RESTORE_PIPES']='true'
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'disable',*|*,'disable')
										colors 'BRED' 'Disabling...'
										config['RESTORE_PIPES']='false'
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: $(test "${config['RESTORE_PIPES']:-false}" == 'true' && echo 'true' || echo 'false')"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting using pipes for restoring configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'clear',*|*,'clear'|*,) clear; break 1;;
					'exit',*|*,'exit') colors 'BRED' 'Exiting restore configuration...'; break 2;;
					*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
				esac
			done
		done
	}
	## tarmux configuration
	tarmuxConf () {
		while true; do
			select configuration in "${CONFIGURATIONS[@]}" 'clear' 'exit'; do
				case "${configuration},${REPLY:-}" in
					'Installation directory',*|*,'Installation directory')
						while true; do
							select option in 'explorer' 'manual' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'explorer',*|*,'explorer')
										cd "$(dirname "${config['INSTALL']}")" || colors 'BRED' 'Error going to current config installation directory.' 1>&2
										while true; do
											local glob
											glob="$(compgen -G './'*'/' 1>/dev/null 2>&1 && echo '1')"
											select directory in 'select' 'clear' 'exit' "${PWD}" '..' ${glob:+*/}; do
												case "${directory},${REPLY:-}" in
													'select',*|*,'select')
														colors 'BWHITE' "Program name? ('$(basename "${config['INSTALL']}")'):"
														read -p ' ' -r -e INSTALL
														colors 'BWHITE' "Moving installation directory '${config['INSTALL']}' to '${PWD}/${INSTALL:-"$(basename "${config['INSTALL']}")"}'..."
														### Do not treat INSTALL as moving to a directory; Always be a file.
														mv --interactive --no-target-directory "${config['INSTALL']}" "${PWD}/${INSTALL:-"$(basename "${config['INSTALL']}")"}" || break 1
														config['INSTALL']="${PWD}/${INSTALL:-"$(basename "${config['INSTALL']}")"}"
														save_config &&
														colors 'BGREEN' 'Done!'
														break 1
														;;

													'clear',*|*,'clear'|*,) clear; break 1;;
													'exit',*|*,'exit') colors 'BRED' 'Exiting installation directory explorer configuration...'; break 2;;
													'/',*|*,'/')
														read -e -i'/' ### No -r to accept escaping
														cd "$(echo "${REPLY:-}" | xargs)" || true ### Trim whitespace
														break 1
														;;

													'..',*|*,'..') cd .. || true; break 1;;
													*,*) cd "./$(echo "${directory:-"${REPLY:-}"}" | xargs)" || true; break 1;; ### Trim whitespace
												esac
											done
										done
										cd "${CWD}" || colors 'BRED' 'Error going to previous working directory.' 1>&2
										break 1
										;;

									'manual',*|*,'manual')
										colors 'BWHITE' "Where? ('${config['INSTALL']}'):"
										read -p ' ' -r -e INSTALL
										colors 'BWHITE' "Moving installation directory '${config['INSTALL']}' to '${INSTALL:-"${config['INSTALL']}"}'..."
										### Do not treat INSTALL as moving to a directory; Always be a file.
										mv --interactive --no-target-directory "${config['INSTALL']}" "${INSTALL:-"${config['INSTALL']}"}" || break 1
										config['INSTALL']="${INSTALL:-"${config['INSTALL']}"}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['INSTALL']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting installation directory configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Tar',*|*,'Tar') tarConf; break 1;;
					'Backup',*|*,'Backup') backupConf; break 1;;
					'Restore',*|*,'Restore') restoreConf; break 1;;
					'tarmux backup root directory',*|*,'tarmux backup root directory')
						while true; do
							select option in 'explorer' 'manual' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'explorer',*|*,'explorer')
										cd "${config['TARMUX_ROOT']}" || colors 'BRED' 'Error going to current config tarmux root directory.' 1>&2
										while true; do
											local glob
											glob="$(compgen -G './'*'/' 1>/dev/null 2>&1 && echo '1')"
											select directory in 'select' 'clear' 'exit' "${PWD}" '..' ${glob:+*/}; do
												case "${directory},${REPLY:-}" in
													'select',*|*,'select')
														local TARMUX_ROOT="${PWD}"
														colors 'BWHITE' "Moving tarmux backup root directory '${config['TARMUX_ROOT']}' to '${TARMUX_ROOT:-"${config['TARMUX_ROOT']}"}'..."
														config['TARMUX_ROOT']="${TARMUX_ROOT:-"${config['TARMUX_ROOT']}"}"
														save_config &&
														colors 'BGREEN' 'Done!'
														break 1
														;;

													'clear',*|*,'clear'|*,) clear; break 1;;
													'exit',*|*,'exit') colors 'BRED' 'Exiting tarmux backup root directory explorer configuration...'; break 2;;
													'/',*|*,'/')
														read -e -i'/' ### No -r to accept escaping
														cd "$(echo "${REPLY:-}" | xargs)" || true ### Trim whitespace
														break 1
														;;

													'..',*|*,'..') cd .. || true; break 1;;
													*,*) cd "./$(echo "${directory:-"${REPLY:-}"}" | xargs)" || true; break 1;; ### Trim whitespace
												esac
											done
										done
										cd "${CWD}" || colors 'BRED' 'Error going to previous working directory.' 1>&2
										break 1
										;;

									'manual',*|*,'manual')
										colors 'BWHITE' "Where? ('${config['TARMUX_ROOT']}'):"
										read -p ' ' -r -e TARMUX_ROOT
										colors 'BWHITE' "Moving tarmux backup root directory '${config['TARMUX_ROOT']}' to '${TARMUX_ROOT:-"${config['TARMUX_ROOT']}"}'..."
										config['TARMUX_ROOT']="${TARMUX_ROOT:-"${config['TARMUX_ROOT']}"}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['TARMUX_ROOT']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting tarmux backup root directory configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'tarmux backup data directory',*|*,'tarmux backup data directory')
						while true; do
							select option in 'explorer' 'manual' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'explorer',*|*,'explorer')
										cd "${config['TARMUX_DATA']}" || colors 'BRED' 'Error going to current config tarmux data directory.' 1>&2
										while true; do
											local glob
											glob="$(compgen -G './'*'/' 1>/dev/null 2>&1 && echo '1')"
											select directory in 'select' 'clear' 'exit' "${PWD}" '..' ${glob:+*/}; do
												case "${directory},${REPLY:-}" in
													'select',*|*,'select')
														local TARMUX_DATA="${PWD}"
														colors 'BWHITE' "Moving tarmux backup data directory '${config['TARMUX_DATA']}' to '${TARMUX_DATA:-"${config['TARMUX_DATA']}"}'..."
														config['TARMUX_DATA']="${TARMUX_DATA:-"${config['TARMUX_DATA']}"}"
														save_config &&
														colors 'BGREEN' 'Done!'
														break 1
														;;

													'clear',*|*,'clear'|*,) clear; break 1;;
													'exit',*|*,'exit') colors 'BRED' 'Exiting tarmux backup data directory explorer configuration...'; break 2;;
													'/',*|*,'/')
														read -e -i'/' ### No -r to accept escaping
														cd "$(echo "${REPLY:-}" | xargs)" || true ### Trim whitespace
														break 1
														;;

													'..',*|*,'..') cd .. || true; break 1;;
													*,*) cd "./$(echo "${directory:-"${REPLY:-}"}" | xargs)" || true; break 1;; ### Trim whitespace
												esac
											done
										done
										cd "${CWD}" || colors 'BRED' 'Error going to previous working directory.' 1>&2
										break 1
										;;

									'manual',*|*,'manual')
										colors 'BWHITE' "Where? ('${config['TARMUX_DATA']}'):"
										read -p ' ' -r -e TARMUX_DATA
										colors 'BWHITE' "Moving tarmux backup data directory '${config['TARMUX_DATA']}' to '${TARMUX_DATA:-"${config['TARMUX_DATA']}"}'..."
										config['TARMUX_DATA']="${TARMUX_DATA:-"${config['TARMUX_DATA']}"}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['TARMUX_DATA']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting tarmux backup data directory configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'tarmux backup name',*|*,'tarmux backup name')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'change',*|*,'change')
										colors 'BWHITE' "Backup name? You can also include date formats like '%Y-%m-%d' ('${config['TARMUX_NAME']}'):"
										read -p ' ' -r -e TARMUX_NAME
										colors 'BWHITE' "Changing tarmux backup name '${config['TARMUX_NAME']}' to '${TARMUX_NAME:-"${config['TARMUX_NAME']}"}'..."
										config['TARMUX_NAME']="${TARMUX_NAME:-"${config['TARMUX_NAME']}"}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['TARMUX_NAME']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting tarmux backup name configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'tarmux backup extension',*|*,'tarmux backup extension')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'change',*|*,'change')
										colors 'BWHITE' "Backup extension? ('${config['TARMUX_EXT']}'):"
										read -p ' ' -r -e TARMUX_EXT
										colors 'BWHITE' "Changing tarmux backup extension '${config['TARMUX_EXT']}' to '${TARMUX_EXT-${config['TARMUX_EXT']}}'..."
										config['TARMUX_EXT']="${TARMUX_EXT-${config['TARMUX_EXT']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['TARMUX_EXT']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting tarmux backup extension configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'tarmux backup directories',*|*,'tarmux backup directories')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'change',*|*,'change')
										colors 'BWHITE' "What tarmux backup directories? Must be separated with '${config['TARMUX_IFS']}' ('${config['TARMUX_LIST']}'):"
										read -p ' ' -r -e TARMUX_LIST
										colors 'BWHITE' "Changing tarmux backup directories '${config['TARMUX_LIST']}' to '${TARMUX_LIST:-"${config['TARMUX_LIST']}"}'..."
										config['TARMUX_LIST']="${TARMUX_LIST:-"${config['TARMUX_LIST']}"}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view')
										IFS="${config['TARMUX_IFS']}" read -r -a backup_directories <<< "${config['TARMUX_LIST']}"
										colors 'BCYAN' 'Current: '
										colors 'BWHITE' "${backup_directories[@]}"
										break 1
										;;

									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting tarmux backup directories configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'tarmux backup directories separator',*|*,'tarmux backup directories separator')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'change',*|*,'change')
										colors 'BWHITE' "Directory Separator ('${config['TARMUX_IFS']}'):"
										read -p ' ' -r -e TARMUX_IFS
										colors 'BWHITE' "Changing tarmux backup directories separator '${config['TARMUX_IFS']}' to '${TARMUX_IFS-${config['TARMUX_IFS']}}'..."
										config['TARMUX_IFS']="${TARMUX_IFS-${config['TARMUX_IFS']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['TARMUX_IFS']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting tarmux backup directories separator configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Always ask storage permission',*|*,'Always ask storage permission')
						while true; do
							select option in 'enable' 'disable' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'enable',*|*,'enable')
										colors 'BGREEN' 'Enabling...'
										config['REQUEST_STORAGE']='true'
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'disable',*|*,'disable')
										colors 'BRED' 'Disabling...'
										config['REQUEST_STORAGE']='false'
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: $(test "${config['REQUEST_STORAGE']:-false}" == 'true' && echo 'true' || echo 'false')"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting request for storage configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Always save config',*|*,'Always save config')
						while true; do
							select option in 'enable' 'disable' 'view' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'enable',*|*,'enable')
										colors 'BGREEN' 'Enabling...'
										config['ALWAYS_SAVE']='true'
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'disable',*|*,'disable')
										colors 'BRED' 'Disabling...'
										config['ALWAYS_SAVE']='false'
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: $(test "${config['ALWAYS_SAVE']:-false}" == 'true' && echo 'true' || echo 'false')"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting always saving configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'save',*|*,'save') colors 'BWHITE' 'Saving configuration...'; save_config && colors 'BGREEN' 'Done!'; break 1;;
					'reset',*|*,'reset')
						while true; do
							select option in 'reset' 'clear' 'exit'; do
								case "${option},${REPLY:-}" in
									'reset',*|*,'reset')
										colors 'RED' "Are you sure to reset the config from '${CONFIG_DIR}/${CONFIG_FILE}'? (y/N):"
										read -p ' ' -r -e ### No -n1 because I am not that evil.
										case "${REPLY:-n}" in
											'y'|'Y')
												colors 'BWHITE' 'Resetting...'
												printf "config['ALWAYS_SAVE']='false'" 1> "${CONFIG_DIR}/${CONFIG_FILE}" &&
												source "${CONFIG_DIR}/${CONFIG_FILE}" &&
												printf '' 1> "${CONFIG_DIR}/${CONFIG_FILE}" &&
												colors 'BGREEN' 'Done!'
												;;

											'n'|'N'|*) colors 'BRED' 'Exiting resetting configuration confirmation...';;
										esac
										break 1
										;;

									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting resetting configuration...'; break 2;;
								esac
							done
						done
						break 1
						;;

					'clear',*|*,'clear'|*,) clear; break 1;;
					'exit',*|*,'exit') colors 'BRED' 'Exiting tarmux configuration...'; break 2;;
					*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
				esac
			done
		done
	}
	while true; do
		select action in "${ACTIONS[@]}" 'clear' 'exit'; do
			case "${action},${REPLY:-}" in
				'install',*|*,'install') installPkg; break 1;;
				'uninstall',*|*,'uninstall') uninstallPkg; break 1;;
				'tarmux',*|*,'tarmux') tarmuxConf; break 1;;
				'clear',*|*,'clear'|*,) clear; break 1;;
				'exit',*|*,'exit') colors 'BRED' 'Exiting...'; break 2;;
				*) colors 'BRED' 'Unknown option' 1>&2; break 1;;
			esac
		done
	done
}

version () {
readarray config_variables <<EOV
$(
for key in "${!config[@]}"; do
	printf '\t%s\n' "'${config_name["${key}"]}': $(
	if test "${key}" == 'TARMUX_LIST'; then
		IFS="${config['TARMUX_IFS']}" read -r -a backup_directories <<< "${config['TARMUX_LIST']}"
		echo "${backup_directories[@]}"
	else
		echo "'${config["${key}"]}'"
	fi
	)"
done
)
EOV
	colors 'BCYAN' "tarmux ${VERSION}"
	colors 'GREEN' "Config: '${CONFIG_DIR}/${CONFIG_FILE}'"
	colors 'CYAN' "${config_variables[@]}"
}


# Check if backup data is not writable and can request permission.
while test \( \! -w "${config['TARMUX_DATA']}" \) -a \( "${config['REQUEST_STORAGE']:-false}" == 'true' \); do
	colors 'BCYAN' "No write permission on ${config['TARMUX_DATA']}. Requesting storage permission..."
	termux-setup-storage
done

options "${@}"
