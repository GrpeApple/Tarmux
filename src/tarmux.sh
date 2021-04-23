#!/data/data/com.termux/files/usr/bin/env bash

VERSION='v0.3.5'

# Colors
## Prefixes
### B = Bold
### K = Background
declare -A color=(
	['RED']='\e[0;31m'
	['BRED']='\e[1;31m'
	['BGREEN']='\e[1;32m'
	['BYELLOW']='\e[1;33m'
	['BBLUE']='\e[1;34m'
	['BPURPLE']='\e[1;35m'
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
	printf "${color["${1}"]}${color['KBLACK']}%s${color['RESET']}" "${2}" "${last:+${@:3:$(("${#}" -1))}}"; test "${2: -2}" != ": " && printf '\n'
}

# Check shell options
case "${-}" in
	*'r'*) colors 'BYELLOW' 'WARNING: shell in restricted mode.' >&2;;
	*'p'*) colors 'BYELLOW' 'WARNING: shell in POSIX mode.' >&2;;
esac

# Configuration
## tarmux preferences
declare -A config=(
	['INSTALL']="$(realpath "${0:-./tarmux}")"
	['BACKUP_TOOL']='tar'
	['BACKUP_OPTIONS']='-z'
	['BACKUP_ENV']='false'
	['RESTORE_TOOL']='tar'
	['RESTORE_OPTIONS']='-z'
	['RESTORE_ENV']='false'
	['DELETE_TARMUX_ROOT']='true'
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
declare -A config_name=(
	['INSTALL']="Installation directory"
	['BACKUP_TOOL']='Backup tool'
	['BACKUP_OPTIONS']='Backup options'
	['BACKUP_ENV']='Backup environmental variables'
	['RESTORE_TOOL']='Restore tool'
	['RESTORE_OPTIONS']='Restore options'
	['RESTORE_ENV']='Restore environmental variables'
	['DELETE_TARMUX_ROOT']='Always delete tarmux root directory before restore'
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
CONFIG_DIR="${HOME:-/data/data/com.termux/files/home}/.config/tarmux"
CONFIG_FILE='config'

# Incase if config location does not exist.
mkdir --parents "${CONFIG_DIR:-/data/data/com.termux/files/home/.config/tarmux}" || exit 1
touch "${CONFIG_DIR:-/data/data/com.termux/files/home/.config/tarmux}/${CONFIG_FILE:-config}" || exit 1

# Backup variables before sourcing.
INSTALL="${config['INSTALL']}"

# shellcheck source=/dev/null # Why not
# You are responsible for putting dangerous stuff in the config file.
source "${CONFIG_DIR:-/data/data/com.termux/files/home/.config/tarmux}/${CONFIG_FILE:-config}"

# Check if INSTALL changed
if [[ "${INSTALL}" != "${config['INSTALL']}" ]]; then
	readarray warning <<-EOW
		WARNING: moving ${INSTALL} to ${config['INSTALL']}.
		Use ${0:-./tarmux} -c and select 'Installation directory' to move; or use ${0:-./tarmux} -c and select 'reset' then move it to the desired location.
	EOW
	colors 'BYELLOW' "${warning[@]}" >&2
	## Do not treat config file as moving to a directory; Always be a file.
	mv --interactive --no-target-directory "${INSTALL}" "${config['INSTALL']}"
fi

# Options for tarmux
read -r -a opt <<< "$(getopt --options 'hcV' --alternative --longoptions 'help,configure,version' --name 'tarmux' --shell 'bash' -- "${@:---}")"

# Working directory
CWD="${PWD}"

# Configuration
## Installation
ACTIONS=('install' 'uninstall' 'tarmux')

### Packages
PACKAGES=('tar' 'pigz' 'zstd')

## Configuration for tarmux
CONFIGURATIONS=('Installation directory' 'Backup' 'Restore' 'tarmux backup root directory' 'tarmux backup data directory' 'tarmux backup name' 'tarmux backup extension' 'tarmux backup directories' 'tarmux backup directories separator' 'Always ask storage permission' 'Always save config' 'save' 'reset')
BACKUP_CONFIGURATIONS=('Backup tool' 'Backup options' 'Backup environmental variables')
RESTORE_CONFIGURATIONS=('Restore tool' 'Restore options' 'Restore environmental variables' 'Always delete tarmux root directory before restore')
BACKUP_TOOLS=('tar' 'tar (pigz)' 'tar (zstd)')
RESTORE_TOOLS=('tar' 'tar (pigz)' 'tar (zstd)')

# Save configuration
save_config () {
	test "${config['ALWAYS_SAVE']}" == 'true' && cat > "${CONFIG_DIR:-/data/data/com.termux/files/home/.config/tarmux}/${CONFIG_FILE:-config}" <<-EOC
		# $(date +'Saved config on %c %:::z')
		# DO NOT EDIT THIS FILE!
		# Unless, you know what you are doing.
		$(for key in "${!config[@]}"; do echo "config['${key}']='${config[${key}]}'"; done)
	EOC
}

# Option management
options () {
	while true; do
		case "${1:---}" in
			'-h'|'--help') usage; break 1;;
			'-c'|'--configure') configure; shift 1; continue;;
			'-V'|'--version') version; shift 1; continue;;
			'--') test -z "${opt[1]}" && usage; break 1;; ## Check if no options, then display usage.
			*) colors 'BRED' 'Unknown error' >&2; return 1;; ## This should not happen.
		esac
	done
}

# Help message
usage () {
	colors 'BCYAN' "Usage: $(basename "${config['INSTALL']}") -[[h|[-]help]|[c|[-]configure]|[V|[-]version]]"
	colors 'BBLUE' 'Options:'
readarray options <<EOU
	-h|-help	Display this help usage
	-c|-configure	Configure
	-V|-version	Display version and information
EOU
	colors 'BWHITE' "${options[@]}"
}

# Configuration
configure () {
	## Installation
	installPkg () {
		while true; do
			select package in 'update' 'upgrade' 'repository' 'manual' "${PACKAGES[@]}" 'clear' 'exit'; do
				case "${package},${REPLY}" in
					'update',*|*,'update') colors 'BWHITE' 'Updating apt...'; apt update && colors 'BGREEN' 'Done!'; break 1;;
					'upgrade',*|*,'upgrade') colors 'BWHITE' 'Upgrading packages...'; apt full-upgrade && colors 'BGREEN' 'Done!'; break 1;;
					'repository',*|*,'repository') colors 'BWHITE' "Changing Termux's repositories..."; termux-change-repo && colors 'BGREEN' 'Done!'; break 1;;
					'manual',*|*,'manual') colors 'BWHITE' 'Package to install? (): '; read -r -e package; apt install "${package}" && colors 'BGREEN' 'Done!'; break 1;;
					'tar',*|*,'tar') colors 'BWHITE' 'Installing tar...'; apt install tar && colors 'BGREEN' 'Done!'; break 1;;
					'pigz',*|*,'pigz') colors 'BWHITE' 'Installing pigz...'; apt install pigz && colors 'BGREEN' 'Done!'; break 1;;
					'zstd',*|*,'zstd') colors 'BWHITE' 'Installing zstd...'; apt install zstd && colors 'BGREEN' 'Done!'; break 1;;
					'clear',*|*,'clear'|*,) clear; break 1;;
					'exit',*|*,'exit') colors 'BRED' 'Exiting installation...'; break 2;;
					*) colors 'BRED' 'Unknown option' >&2; break 1;;
				esac
			done
		done
	}
	## Uninstallation
	uninstallPkg () {
		while true; do
			select package in 'manual' "${PACKAGES[@]}" 'clear' 'exit'; do
				case "${package},${REPLY}" in
					'manual',*|*,'manual') colors 'BWHITE' 'Package to uninstall? (): '; read -r -e package; apt autoremove "${package}" && colors 'BGREEN' 'Done!'; break 1;;
					'tar',*|*,'tar') colors 'BRED' 'Uninstalling tar (dangerous)...'; apt autoremove tar && colors 'BGREEN' 'Done!'; break 1;;
					'pigz',*|*,'pigz') colors 'BWHITE' 'Uninstalling pigz...'; apt autoremove pigz && colors 'BGREEN' 'Done!'; break 1;;
					'zstd',*|*,'zstd') colors 'BWHITE' 'Uninstalling zstd...'; apt autoremove zstd && colors 'BGREEN' 'Done!'; break 1;;
					'clear',*|*,'clear'|*,) clear; break 1;;
					'exit',*|*,'exit') colors 'BRED' 'Exiting uninstallation...'; break 2;;
					*) colors 'BRED' 'Unknown option' >&2; break 1;;
				esac
			done
		done
	}
	## Backup configuration
	backupConf () {
		while true; do
			select configuration in "${BACKUP_CONFIGURATIONS[@]}" 'clear' 'exit'; do
				case "${configuration},${REPLY}" in
					'Backup tool',*|*,'Backup tool')
						while true; do
							select tool in 'manual' "${BACKUP_TOOLS[@]}" 'view' 'clear' 'exit'; do
								case "${tool},${REPLY}" in
									'manual',*|*,'manual')
										colors 'BWHITE' "Backup tool to use? ('${config['BACKUP_TOOL']}'): "
										read -r -e BACKUP_TOOL
										colors 'BWHITE' "Changing backup tool '${config['BACKUP_TOOL']}' to '${BACKUP_TOOL:-${config['BACKUP_TOOL']}}'..."
										config['BACKUP_TOOL']="${BACKUP_TOOL:-${config['BACKUP_TOOL']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'tar',*|*,'tar')
										local BACKUP_TOOL='tar'
										colors 'BWHITE' "Changing backup tool '${config['BACKUP_TOOL']}' to '${BACKUP_TOOL:-${config['BACKUP_TOOL']}}'..."
										config['BACKUP_TOOL']="${BACKUP_TOOL:-${config['BACKUP_TOOL']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'tar (pigz)',*|*,'tar (pigz)')
										local BACKUP_TOOL='tar (pigz)'
										colors 'BWHITE' "Changing backup tool '${config['BACKUP_TOOL']}' to '${BACKUP_TOOL:-${config['BACKUP_TOOL']}}'..."
										config['BACKUP_TOOL']="${BACKUP_TOOL:-${config['BACKUP_TOOL']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'tar (zstd)',*|*,'tar (zstd)')
										local BACKUP_TOOL='tar (zstd)'
										colors 'BWHITE' "Changing backup tool '${config['BACKUP_TOOL']}' to '${BACKUP_TOOL:-${config['BACKUP_TOOL']}}'..."
										config['BACKUP_TOOL']="${BACKUP_TOOL:-${config['BACKUP_TOOL']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['BACKUP_TOOL']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting backup tool configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Backup options',*|*,'Backup options')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'change',*|*,'change')
										colors 'BWHITE' "What backup options? ('${config['BACKUP_OPTIONS']}'): "
										read -r -e BACKUP_OPTIONS
										colors 'BWHITE' "Changing backup options '${config['BACKUP_OPTIONS']}' to '${BACKUP_OPTIONS-${config['BACKUP_OPTIONS']}}'..."
										config['BACKUP_OPTIONS']="${BACKUP_OPTIONS-${config['BACKUP_OPTIONS']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['BACKUP_OPTIONS']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting backup options configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Backup environmental variables',*|*,'Backup environmental variables')
						colors 'BYELLOW' 'WARNING: This uses eval, and your security will suffer.' >&2
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'change',*|*,'change')
										colors 'BWHITE' "What backup environmental variables? ('${config['BACKUP_ENV']}'): "
										read -r -e BACKUP_ENV
										colors 'BWHITE' "Changing backup enviornmental variables '${config['BACKUP_ENV']}' to '${BACKUP_ENV-${config['BACKUP_ENV']}}'..."
										config['BACKUP_ENV']="${BACKUP_ENV-${config['BACKUP_ENV']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['BACKUP_ENV']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting backup environmental variables configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'clear',*|*,'clear'|*,) clear; break 1;;
					'exit',*|*,'exit') colors 'BRED' 'Exiting backup configuration...'; break 2;;
					*) colors 'BRED' 'Unknown option' >&2; break 1;;
				esac
			done
		done
	}
	## Restore configuration
	restoreConf () {
		while true; do
			select configuration in "${RESTORE_CONFIGURATIONS[@]}" 'clear' 'exit'; do
				case "${configuration},${REPLY}" in
					'Restore tool',*|*,'Restore tool')
						while true; do
							select tool in 'manual' "${RESTORE_TOOLS[@]}" 'view' 'clear' 'exit'; do
								case "${tool},${REPLY}" in
									'manual',*|*,'manual')
										colors 'BWHITE' "Restore tool to use? ('${config['RESTORE_TOOL']}'): "
										read -r -e RESTORE_TOOL
										colors 'BWHITE' "Changing restore tool '${config['RESTORE_TOOL']}' to '${RESTORE_TOOL:-${config['RESTORE_TOOL']}}'..."
										config['RESTORE_TOOL']="${RESTORE_TOOL:-${config['RESTORE_TOOL']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'tar',*|*,'tar')
										local RESTORE_TOOL='tar'
										colors 'BWHITE' "Changing restore tool '${config['RESTORE_TOOL']}' to '${RESTORE_TOOL:-${config['RESTORE_TOOL']}}'..."
										config['RESTORE_TOOL']="${RESTORE_TOOL:-${config['RESTORE_TOOL']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'tar (pigz)',*|*,'tar (pigz)')
										local RESTORE_TOOL='tar (pigz)'
										colors 'BWHITE' "Changing restore tool '${config['RESTORE_TOOL']}' to '${RESTORE_TOOL:-${config['RESTORE_TOOL']}}'..."
										config['RESTORE_TOOL']="${RESTORE_TOOL:-${config['RESTORE_TOOL']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'tar (zstd)',*|*,'tar (zstd)')
										local RESTORE_TOOL='tar (zstd)'
										colors 'BWHITE' "Changing restore tool '${config['RESTORE_TOOL']}' to '${RESTORE_TOOL:-${config['RESTORE_TOOL']}}'..."
										config['RESTORE_TOOL']="${RESTORE_TOOL:-${config['RESTORE_TOOL']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['RESTORE_TOOL']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting restore tool configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Restore options',*|*,'Restore options')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'change',*|*,'change')
										colors 'BWHITE' "What options? ('${config['RESTORE_OPTIONS']}'): "
										read -r -e RESTORE_OPTIONS
										colors 'BWHITE' "Changing restore options '${config['RESTORE_OPTIONS']}' to '${RESTORE_OPTIONS-${config['RESTORE_OPTIONS']}}'..."
										config['RESTORE_OPTIONS']="${RESTORE_OPTIONS-${config['RESTORE_OPTIONS']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['RESTORE_OPTIONS']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting restore options configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Restore environmental variables',*|*,'Restore environmental variables')
						colors 'BYELLOW' 'WARNING: This uses eval, and your security will suffer.' >&2
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'change',*|*,'change')
										colors 'BWHITE' "What restore environmental variables? ('${config['RESTORE_ENV']}'): "
										read -r -e RESTORE_ENV
										colors 'BWHITE' "Changing restore enviornmental variables '${config['RESTORE_ENV']}' to '${RESTORE_ENV-${config['RESTORE_ENV']}}'..."
										config['RESTORE_ENV']="${RESTORE_ENV-${config['RESTORE_ENV']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['RESTORE_ENV']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting restore environmental variables configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Always delete tarmux root directory before restore',*|*,'Always delete tarmux root directory before restore')
						while true; do
							select option in 'enable' 'disable' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'enable',*|*,'enable')
										colors 'BGREEN' 'Enabling...'
										config['DELETE_TARMUX_ROOT']='true'
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'disable',*|*,'disable')
										colors 'BRED' 'Disabling...'
										config['DELETE_TARMUX_ROOT']='false'
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: $(test "${config['DELETE_TARMUX_ROOT']}" == 'true' && echo 'true' || echo 'false')"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting deletion of tarmux root directory before restoring configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'clear',*|*,'clear'|*,) clear; break 1;;
					'exit',*|*,'exit') colors 'BRED' 'Exiting restore configuration...'; break 2;;
					*) colors 'BRED' 'Unknown option' >&2; break 1;;
				esac
			done
		done
	}
	## tarmux configuration
	tarmuxConf () {
		while true; do
			select configuration in "${CONFIGURATIONS[@]}" 'clear' 'exit'; do
				case "${configuration},${REPLY}" in
					'Installation directory',*|*,'Installation directory')
						while true; do
							select option in 'explorer' 'manual' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'explorer',*|*,'explorer')
										cd "$(dirname "${config['INSTALL']}")" || colors 'BRED' 'Error going to current config installation directory.' >&2
										while true; do
											local glob
											glob="$(compgen -G './'*'/' &>/dev/null && echo '1')"
											select directory in 'select' 'clear' 'exit' "${PWD}" './..' ${glob:+./*/}; do
												case "${directory},${REPLY}" in
													'select',*|*,'select')
														colors 'BWHITE' "Program name? ('$(basename "${config['INSTALL']}")'): "
														read -r -e INSTALL
														colors 'BWHITE' "Moving installation directory '${config['INSTALL']}' to '${PWD}/${INSTALL:-$(basename "${config['INSTALL']}")}'..."
														### Do not treat INSTALL as moving to a directory; Always be a file.
														mv --interactive --no-target-directory "${config['INSTALL']}" "${PWD}/${INSTALL:-$(basename "${config['INSTALL']}")}" || break 1
														config['INSTALL']="${PWD}/${INSTALL:-$(basename "${config['INSTALL']}")}"
														save_config &&
														colors 'BGREEN' 'Done!'
														break 1
														;;

													'clear',*|*,'clear'|*,) clear; break 1;;
													'exit',*|*,'exit') colors 'BRED' 'Exiting installation directory explorer configuration...'; break 2;;
													'/'*,*|*,'/'*) read -p "/" -r -e; cd "/${REPLY}" || true; break 1;;
													'./..',*|*,'./..') cd .. || true; break 1;;
													'./'*,*|*,'./'*) cd "${directory:-${REPLY}}" || colors 'BRED' 'Unknown error.' >&2; break 1;;
												esac
											done
										done
										cd "${CWD}" || colors 'BRED' 'Error going to previous working directory.' >&2
										break 1
										;;

									'manual',*|*,'manual')
										colors 'BWHITE' "Where? ('${config['INSTALL']}'): "
										read -r -e INSTALL
										colors 'BWHITE' "Moving installation directory '${config['INSTALL']}' to '${INSTALL:-${config['INSTALL']}}'..."
										### Do not treat INSTALL as moving to a directory; Always be a file.
										mv --interactive --no-target-directory "${config['INSTALL']}" "${INSTALL:-${config['INSTALL']}}" || break 1
										config['INSTALL']="${INSTALL:-${config['INSTALL']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['INSTALL']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting installation directory configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Backup',*|*,'Backup') backupConf; break 1;;
					'Restore',*|*,'Restore') restoreConf; break 1;;
					'tarmux backup root directory',*|*,'tarmux backup root directory')
						while true; do
							select option in 'explorer' 'manual' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'explorer',*|*,'explorer')
										cd "${config['TARMUX_ROOT']}" || colors 'BRED' 'Error going to current config tarmux root directory.' >&2
										while true; do
											local glob
											glob="$(compgen -G './'*'/' &>/dev/null && echo '1')"
											select directory in 'select' 'clear' 'exit' "${PWD}" './..' ${glob:+./*/}; do
												case "${directory},${REPLY}" in
													'select',*|*,'select')
														local TARMUX_ROOT="${PWD}"
														colors 'BWHITE' "Moving tarmux backup root directory '${config['TARMUX_ROOT']}' to '${TARMUX_ROOT:-${config['TARMUX_ROOT']}}'..."
														config['TARMUX_ROOT']="${TARMUX_ROOT:-${config['TARMUX_ROOT']}}"
														save_config &&
														colors 'BGREEN' 'Done!'
														break 1
														;;

													'clear',*|*,'clear'|*,) clear; break 1;;
													'exit',*|*,'exit') colors 'BRED' 'Exiting tarmux backup root directory explorer configuration...'; break 2;;
													'/'*,*|*,'/'*) read -p "/" -r -e; cd "/${REPLY}" || true; break 1;;
													'./..',*|*,'./..') cd .. || true; break 1;;
													'./'*,*|*,'./'*) cd "${directory:-${REPLY}}" || colors 'BRED' 'Unknown error' >&2; break 1;;
												esac
											done
										done
										cd "${CWD}" || colors 'BRED' 'Error going to previous working directory.' >&2
										break 1
										;;

									'manual',*|*,'manual')
										colors 'BWHITE' "Where? ('${config['TARMUX_ROOT']}'): "
										read -r -e TARMUX_ROOT
										colors 'BWHITE' "Moving tarmux backup root directory '${config['TARMUX_ROOT']}' to '${TARMUX_ROOT:-${config['TARMUX_ROOT']}}'..."
										config['TARMUX_ROOT']="${TARMUX_ROOT:-${config['TARMUX_ROOT']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['TARMUX_ROOT']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting tarmux backup root directory configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'tarmux backup data directory',*|*,'tarmux backup data directory')
						while true; do
							select option in 'explorer' 'manual' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'explorer',*|*,'explorer')
										cd "${config['TARMUX_DATA']}" || colors 'BRED' 'Error going to current config tarmux data directory.' >&2
										while true; do
											local glob
											glob="$(compgen -G './'*'/' &>/dev/null && echo '1')"
											select directory in 'select' 'clear' 'exit' "${PWD}" './..' ${glob:+./*/}; do
												case "${directory},${REPLY}" in
													'select',*|*,'select')
														local TARMUX_DATA="${PWD}"
														colors 'BWHITE' "Moving tarmux backup data directory '${config['TARMUX_DATA']}' to '${TARMUX_DATA:-${config['TARMUX_DATA']}}'..."
														config['TARMUX_DATA']="${TARMUX_DATA:-${config['TARMUX_DATA']}}"
														save_config &&
														colors 'BGREEN' 'Done!'
														break 1
														;;

													'clear',*|*,'clear'|*,) clear; break 1;;
													'exit',*|*,'exit') colors 'BRED' 'Exiting tarmux backup data directory explorer configuration...'; break 2;;
													'/'*,*|*,'/'*) read -p "/" -r -e; cd "/${REPLY}" || true; break 1;;
													'./..',*|*,'./..') cd ..; break 1;;
													'./'*,*|*,'./'*) cd "${directory:-${REPLY}}" || colors 'BRED' 'Unknown error.' >&2; break 1;;
												esac
											done
										done
										cd "${CWD}" || colors 'BRED' 'Error going to previous working directory.' >&2
										break 1
										;;

									'manual',*|*,'manual')
										colors 'BWHITE' "Where? ('${config['TARMUX_DATA']}'): "
										read -r -e TARMUX_DATA
										colors 'BWHITE' "Moving tarmux backup data directory '${config['TARMUX_DATA']}' to '${TARMUX_DATA:-${config['TARMUX_DATA']}}'..."
										config['TARMUX_DATA']="${TARMUX_DATA:-${config['TARMUX_DATA']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['TARMUX_DATA']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting tarmux backup data directory configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'tarmux backup name',*|*,'tarmux backup name')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'change',*|*,'change')
										colors 'BWHITE' "Backup name? You can also include date formats like '%Y-%m-%d' ('${config['TARMUX_NAME']}'): "
										read -r -e TARMUX_NAME
										colors 'BWHITE' "Changing tarmux backup name '${config['TARMUX_NAME']}' to '${TARMUX_NAME:-${config['TARMUX_NAME']}}'..."
										config['TARMUX_NAME']="${TARMUX_NAME:-${config['TARMUX_NAME']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['TARMUX_NAME']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting tarmux backup name configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'tarmux backup extension',*|*,'tarmux backup extension')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'change',*|*,'change')
										colors 'BWHITE' "Backup extension? ('${config['TARMUX_EXT']}'): "
										read -r -e TARMUX_EXT
										colors 'BWHITE' "Changing tarmux backup extension '${config['TARMUX_EXT']}' to '${TARMUX_EXT-${config['TARMUX_EXT']}}'..."
										config['TARMUX_EXT']="${TARMUX_EXT-${config['TARMUX_EXT']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['TARMUX_EXT']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting tarmux backup extension configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'tarmux backup directories',*|*,'tarmux backup directories')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'change',*|*,'change')
										colors 'BWHITE' "What tarmux backup directories? Must be separated with '${config['TARMUX_IFS']}' ('${config['TARMUX_LIST']}'): "
										read -r -e TARMUX_LIST
										colors 'BWHITE' "Changing tarmux backup directories '${config['TARMUX_LIST']}' to '${TARMUX_LIST:-${config['TARMUX_LIST']}}'..."
										config['TARMUX_LIST']="${TARMUX_LIST:-${config['TARMUX_LIST']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view')
										colors 'BCYAN' 'Current: '
										IFS="${config['TARMUX_IFS']}" read -r -a backup_directories <<< "${config['TARMUX_LIST']}"
										for i in "${backup_directories[@]}"; do
											colors 'BWHITE' "${i}"
										done
										break 1
										;;

									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting tarmux backup directories configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'tarmux backup directories separator',*|*,'tarmux backup directories separator')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'change',*|*,'change')
										colors 'BWHITE' "Directory Separator ('${config['TARMUX_IFS']}'): "
										read -r -e TARMUX_IFS
										colors 'BWHITE' "Changing tarmux backup directories separator '${config['TARMUX_IFS']}' to '${TARMUX_IFS-${config['TARMUX_IFS']}}'..."
										config['TARMUX_IFS']="${TARMUX_IFS-${config['TARMUX_IFS']}}"
										save_config &&
										colors 'BGREEN' 'Done!'
										break 1
										;;

									'view',*|*,'view') colors 'BCYAN' "Current: '${config['TARMUX_IFS']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting tarmux backup directories separator configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Always ask storage permission',*|*,'Always ask storage permission')
						while true; do
							select option in 'enable' 'disable' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
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

									'view',*|*,'view') colors 'BCYAN' "Current: $(test "${config['REQUEST_STORAGE']}" == 'true' && echo 'true' || echo 'false')"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting request for storage configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Always save config',*|*,'Always save config')
						while true; do
							select option in 'enable' 'disable' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
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

									'view',*|*,'view') colors 'BCYAN' "Current: $(test "${config['ALWAYS_SAVE']}" == 'true' && echo 'true' || echo 'false')"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') colors 'BRED' 'Exiting always saving configuration...'; break 2;;
									*) colors 'BRED' 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'save',*|*,'save') colors 'BWHITE' 'Saving configuration...'; save_config && colors 'BGREEN' 'Done!'; break 1;;
					'reset',*|*,'reset')
						while true; do
							select option in 'reset' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'reset',*|*,'reset')
										colors 'RED' "Are you sure to reset the config from '${CONFIG_DIR:-/data/data/com.termux/files/home/.config/tarmux}/${CONFIG_FILE:-config}'? (y/N): "
										read -r -e ### No -n1 because I am not that evil.
										case "${REPLY:-n}" in
											'y'|'Y')
												colors 'BWHITE' 'Resetting...'
												printf '' > "${CONFIG_DIR:-/data/data/com.termux/files/home/.config/tarmux}/${CONFIG_FILE:-config}" &&
												unset config
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
					*) colors 'BRED' 'Unknown option' >&2; break 1;;
				esac
			done
		done
	}
	while true; do
		select action in "${ACTIONS[@]}" 'clear' 'exit'; do
			case "${action},${REPLY}" in
				'install',*|*,'install') installPkg; break 1;;
				'uninstall',*|*,'uninstall') uninstallPkg; break 1;;
				'tarmux',*|*,'tarmux') tarmuxConf; break 1;;
				'clear',*|*,'clear'|*,) clear; break 1;;
				'exit',*|*,'exit') colors 'BRED' 'Exiting...'; break 2;;
				*) colors 'BRED' 'Unknown option' >&2; break 1;;
			esac
		done
	done
}

version () {
readarray config_variables <<EOV
$(for key in "${!config[@]}"; do printf '\t%s\n' "${config_name["${key}"]}: '${config[${key}]}'"; done)
EOV
	colors 'BCYAN' "tarmux ${VERSION}"
	colors 'BPURPLE' "Config: '${CONFIG_DIR:-/data/data/com.termux/files/home/.config/tarmux}/${CONFIG_FILE:-config}'"
	colors 'BWHITE' "${config_variables[@]}"
}


# Check if backup data is not writable and can request permission.
while test '(' '!' -w "${config['TARMUX_DATA']}" ')' -a '(' -n "${config['REQUEST_STORAGE']}" ')'; do
	colors 'BCYAN' "No write permission on ${config['TARMUX_DATA']}. Requesting storage permission..."
	termux-setup-storage
done

save_config &&
options "${opt[@]:---}" &&
save_config
