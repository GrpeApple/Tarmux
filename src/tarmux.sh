#!/data/data/com.termux/files/usr/bin/env bash

VERSION='v0.3.1'

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

# Check shell options
case "${-}" in
	*'r'*) printf "${color['BYELLOW']}%s\n${color['RESET']}" 'WARNING: shell in restricted mode.' >&2;;
	*'p'*) printf "${color['BYELLOW']}%s\n${color['RESET']}" 'WARNING: shell in POSIX mode.' >&2;;
esac

# Configuration
## tarmux preferences
declare -A config=(
	['INSTALL']="$(realpath "${0:-./tarmux}")"
	['BACKUP_TOOL']='tar'
	['BACKUP_OPTIONS']='-z'
	['BACKUP_ENV']=''
	['RESTORE_TOOL']='tar'
	['RESTORE_OPTIONS']='-z'
	['BACKUP_ENV']=''
	['TARMUX_ROOT']='/data/data/com.termux/files'
	['TARMUX_DATA']='/storage/emulated/0/Download'
	['TARMUX_NAME']='termux_backup_%Y-%m-%d_%H-%M-%S-%N'
	['TARMUX_EXT']='.bak'
	['TARMUX_LIST']='home|usr'
	['TARMUX_IFS']='|'
	['REQUEST_STORAGE']='1'
	['ALWAYS_SAVE']='1'
)

## Config location
CONFIG_DIR="${HOME:-/data/data/com.termux/files/home}/.config/tarmux"
CONFIG_FILE='config'

# Incase if config location does not exist.
mkdir --parents "${CONFIG_DIR:-/data/data/com.termux/files/home/.config/tarmux}" || exit 1
touch "${CONFIG_DIR:-/data/data/com.termux/files/home/.config/tarmux}/${CONFIG_FILE:-config}" || exit 1

# Backup variables before sourcing.
INSTALL="${config['INSTALL']}"

# You are responsible for putting dangerous stuff in the config file.
source "${CONFIG_DIR:-/data/data/com.termux/files/home/.config/tarmux}/${CONFIG_FILE:-config}"

# Check if INSTALL changed
if [[ "${INSTALL}" != "${config['INSTALL']}" ]]; then
	readarray warning <<-EOW
		WARNING: moving ${INSTALL} to ${config['INSTALL']}.
		Use ${0:-./tarmux} -c and select 'Installation directory' to move; or use ${0:-./tarmux} -c and select 'reset' then move it to the desired location.
	EOW
	printf "${color['BYELLOW']}%s${color['RESET']}" "${warning[@]}" >&2
	## Do not treat config file as moving to a directory; Always be a file.
	mv --interactive --no-target-directory "${INSTALL}" "${config['INSTALL']}"
fi

# Options for tarmux
opt="$(getopt --options 'hcV' --alternative --longoptions 'help,configure,version' --name 'tarmux' --shell 'bash' -- "${@:---}")"
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
RESTORE_CONFIGURATIONS=('Restore tool' 'Restore options' 'Restore environmental variables')
BACKUP_TOOLS=('tar' 'tar (pigz)' 'tar (zstd)')
RESTORE_TOOLS=('tar' 'tar (pigz)' 'tar (zstd)')

save_config () {
	cat > "${CONFIG_DIR:-/data/data/com.termux/files/home/.config/tarmux}/${CONFIG_FILE:-config}" <<-EOC
		# $(date +'Saved config on %c %:::z') `# Date and time`
		# DO NOT EDIT THIS FILE!
		# Unless, you know what you are doing.
		$(for key in "${!config[@]}"; do echo "config['${key}']='${config[${key}]}'"; done) `# Save the config for sourcing.`
	EOC
}

# Option management
options () {
	while true; do
		case "${1:---}" in
			'-h'|'--help') usage; break 1;;
			'-c'|'--configure') configure; shift 1; continue;;
			'-V'|'--version') version; shift 1; continue;;
			'--') test -z "${opt:4}" && usage; break 1;; ## Check if no options, then display usage.
			*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown error' >&2; return 1;; # This should not happen unless a change to the program is made.
		esac
	done
}

usage () {
	printf "${color['BCYAN']}%s\n${color['RESET']}" "Usage: $(basename "${config['INSTALL']}") -[[h|[-]help]|[c|[-]configure]|[V|[-]version]]"
	printf "${color['BBLUE']}%s\n${color['RESET']}" 'Options:'
readarray options <<EOU
	-h|-help	Display this help usage
	-c|-configure	Configure
	-V|-version	Display version and information
EOU
	printf "${color['BWHITE']}%s${color['RESET']}" "${options[@]}"
}

# Configuration
configure () {
	## Installation
	installPkg () {
		while true; do
			select package in 'update' 'upgrade' 'repository' 'manual' "${PACKAGES[@]}" 'clear' 'exit'; do
				case "${package},${REPLY}" in
					'update',*|*,'update') printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Updating apt...'; apt update && printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'; break 1;;
					'upgrade',*|*,'upgrade') printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Upgrading packages...'; apt full-upgrade && printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'; break 1;;
					'repository',*|*,'repository') printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing Termux's repositories..."; termux-change-repo && printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'; break 1;;
					'manual',*|*,'manual') printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" 'Package to install? (): '; read -r -e package; apt install ${package} && printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'; break 1;;
					'tar',*|*,'tar') printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Installing tar...'; apt install tar && printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'; break 1;;
					'pigz',*|*,'pigz') printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Installing pigz...'; apt install pigz && printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'; break 1;;
					'zstd',*|*,'zstd') printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Installing zstd...'; apt install zstd && printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'; break 1;;
					'clear',*|*,'clear'|*,) clear; break 1;;
					'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting installation...'; break 2;;
					*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
				esac
			done
		done
	}
	## Uninstallation
	uninstallPkg () {
		while true; do
			select package in 'manual' "${PACKAGES[@]}" 'clear' 'exit'; do
				case "${package},${REPLY}" in
					'manual',*|*,'manual') printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" 'Package to uninstall? (): '; read -r -e package; apt autoremove ${package} && printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'; break 1;;
					'tar',*|*,'tar') printf "${color['BRED']}%s\n${color['RESET']}" 'Uninstalling tar (dangerous)...'; apt autoremove tar && printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'; break 1;;
					'pigz',*|*,'pigz') printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Uninstalling pigz...'; apt autoremove pigz && printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'; break 1;;
					'zstd',*|*,'zstd') printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Uninstalling zstd...'; apt autoremove zstd && printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'; break 1;;
					'clear',*|*,'clear'|*,) clear; break 1;;
					'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting uninstallation...'; break 2;;
					*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
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
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "Backup tool to use? ('${config['BACKUP_TOOL']}'): "
										read -r -e BACKUP_TOOL
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing backup tool '${config['BACKUP_TOOL']}' to '${BACKUP_TOOL:-${config['BACKUP_TOOL']}}'..."
										config['BACKUP_TOOL']="${BACKUP_TOOL:-${config['BACKUP_TOOL']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'tar',*|*,'tar')
										local BACKUP_TOOL='tar'
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing backup tool '${config['BACKUP_TOOL']}' to '${BACKUP_TOOL:-${config['BACKUP_TOOL']}}'..."
										config['BACKUP_TOOL']="${BACKUP_TOOL:-${config['BACKUP_TOOL']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'tar (pigz)',*|*,'tar (pigz)')
										local BACKUP_TOOL='tar (pigz)'
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing backup tool '${config['BACKUP_TOOL']}' to '${BACKUP_TOOL:-${config['BACKUP_TOOL']}}'..."
										config['BACKUP_TOOL']="${BACKUP_TOOL:-${config['BACKUP_TOOL']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'tar (zstd)',*|*,'tar (zstd)')
										local BACKUP_TOOL='tar (zstd)'
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing backup tool '${config['BACKUP_TOOL']}' to '${BACKUP_TOOL:-${config['BACKUP_TOOL']}}'..."
										config['BACKUP_TOOL']="${BACKUP_TOOL:-${config['BACKUP_TOOL']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['BACKUP_TOOL']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting backup tool configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
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
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "What backup options? ('${config['BACKUP_OPTIONS']}'): "
										read -r -e BACKUP_OPTIONS
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing backup options '${config['BACKUP_OPTIONS']}' to '${BACKUP_OPTIONS-${config['BACKUP_OPTIONS']}}'..."
										config['BACKUP_OPTIONS']="${BACKUP_OPTIONS-${config['BACKUP_OPTIONS']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['BACKUP_OPTIONS']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting backup options configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Backup environmental variables',*|*,'Backup environmental variables')
						printf "${color['BYELLOW']}%s\n${color['RESET']}" 'WARNING: This uses eval, and your security will suffer.' >&2
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'change',*|*,'change')
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "What backup environmental variables? ('${config['BACKUP_ENV']}'): "
										read -r -e BACKUP_ENV
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing backup enviornmental variables '${config['BACKUP_ENV']}' to '${BACKUP_ENV-${config['BACKUP_ENV']}}'..."
										config['BACKUP_ENV']="${BACKUP_ENV-${config['BACKUP_ENV']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['BACKUP_ENV']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting backup environmental variables configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'clear',*|*,'clear'|*,) clear; break 1;;
					'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting backup configuration...'; break 2;;
					*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
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
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "Restore tool to use? ('${config['RESTORE_TOOL']}'): "
										read -r -e RESTORE_TOOL
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing restore tool '${config['RESTORE_TOOL']}' to '${RESTORE_TOOL:-${config['RESTORE_TOOL']}}'..."
										config['RESTORE_TOOL']="${RESTORE_TOOL:-${config['RESTORE_TOOL']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'tar',*|*,'tar')
										local RESTORE_TOOL='tar'
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing restore tool '${config['RESTORE_TOOL']}' to '${RESTORE_TOOL:-${config['RESTORE_TOOL']}}'..."
										config['RESTORE_TOOL']="${RESTORE_TOOL:-${config['RESTORE_TOOL']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'tar (pigz)',*|*,'tar (pigz)')
										local RESTORE_TOOL='tar (pigz)'
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing restore tool '${config['RESTORE_TOOL']}' to '${RESTORE_TOOL:-${config['RESTORE_TOOL']}}'..."
										config['RESTORE_TOOL']="${RESTORE_TOOL:-${config['RESTORE_TOOL']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'tar (zstd)',*|*,'tar (zstd)')
										local RESTORE_TOOL='tar (zstd)'
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing restore tool '${config['RESTORE_TOOL']}' to '${RESTORE_TOOL:-${config['RESTORE_TOOL']}}'..."
										config['RESTORE_TOOL']="${RESTORE_TOOL:-${config['RESTORE_TOOL']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['RESTORE_TOOL']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting restore tool configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
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
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "What options? ('${config['RESTORE_OPTIONS']}'): "
										read -r -e RESTORE_OPTIONS
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing restore options '${config['RESTORE_OPTIONS']}' to '${RESTORE_OPTIONS-${config['RESTORE_OPTIONS']}}'..."
										config['RESTORE_OPTIONS']="${RESTORE_OPTIONS-${config['RESTORE_OPTIONS']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['RESTORE_OPTIONS']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting restore options configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Restore environmental variables',*|*,'Restore environmental variables')
						printf "${color['BYELLOW']}%s\n${color['RESET']}" 'WARNING: This uses eval, and your security will suffer.' >&2
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'change',*|*,'change')
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "What restore environmental variables? ('${config['RESTORE_ENV']}'): "
										read -r -e RESTORE_ENV
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing restore enviornmental variables '${config['RESTORE_ENV']}' to '${RESTORE_ENV-${config['RESTORE_ENV']}}'..."
										config['RESTORE_ENV']="${RESTORE_ENV-${config['RESTORE_ENV']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['RESTORE_ENV']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting restore environmental variables configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'clear',*|*,'clear'|*,) clear; break 1;;
					'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting restore configuration...'; break 2;;
					*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
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
										cd "$(dirname "${config['INSTALL']}")" &>/dev/null
										while true; do
											local glob="$(compgen -G './'*'/' &>/dev/null && echo '1')"
											select directory in 'select' 'clear' 'exit' "${PWD}" './..' ${glob:+./*/}; do
												case "${directory},${REPLY}" in
													'select',*|*,'select')
														printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "Program name? ('$(basename "${config['INSTALL']}")'): "
														read -r -e INSTALL
														printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Moving installation directory '${config['INSTALL']}' to '${PWD}/${INSTALL:-$(basename "${config['INSTALL']}")}'..."
														### Do not treat INSTALL as moving to a directory; Always be a file.
														mv --interactive --no-target-directory "${config['INSTALL']}" "${PWD}/${INSTALL:-$(basename "${config['INSTALL']}")}" || break 1
														config['INSTALL']="${PWD}/${INSTALL:-$(basename "${config['INSTALL']}")}"
														test -n "${config['ALWAYS_SAVE']}" && save_config &&
														printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
														break 1
														;;

													'clear',*|*,'clear'|*,) clear; break 1;;
													'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting installation directory explorer configuration...'; break 2;;
													'/'*,*|*,'/'*) read -p "/" -r -e; cd "/${REPLY}"; break 1;;
													'./..',*|*,'./..') cd ..; break 1;;
													'./'*,*|*,'./'*) cd "${directory:-${REPLY}}"; break 1;;
												esac
											done
										done
										cd "${CWD}" &>/dev/null
										break 1
										;;

									'manual',*|*,'manual')
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "Where? ('${config['INSTALL']}'): "
										read -r -e INSTALL
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Moving installation directory '${config['INSTALL']}' to '${INSTALL:-${config['INSTALL']}}'..."
										## Do not treat INSTALL as moving to a directory; Always be a file.
										mv --interactive --no-target-directory "${config['INSTALL']}" "${INSTALL:-${config['INSTALL']}}" || break 1
										config['INSTALL']="${INSTALL:-${config['INSTALL']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['INSTALL']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting installation directory configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
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
										cd "${config['TARMUX_ROOT']}" &>/dev/null
										while true; do
											local glob="$(compgen -G './'*'/' &>/dev/null && echo '1')"
											select directory in 'select' 'clear' 'exit' "${PWD}" './..' ${glob:+./*/}; do
												case "${directory},${REPLY}" in
													'select',*|*,'select')
														local TARMUX_ROOT="${PWD}"
														printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Moving tarmux backup root directory '${config['TARMUX_ROOT']}' to '${TARMUX_ROOT:-${config['TARMUX_ROOT']}}'..."
														config['TARMUX_ROOT']="${TARMUX_ROOT:-${config['TARMUX_ROOT']}}"
														test -n "${config['ALWAYS_SAVE']}" && save_config &&
														printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
														break 1
														;;

													'clear',*|*,'clear'|*,) clear; break 1;;
													'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting tarmux backup root directory explorer configuration...'; break 2;;
													'/'*,*|*,'/'*) read -p "/" -r -e; cd "/${REPLY}"; break 1;;
													'./..',*|*,'./..') cd ..; break 1;;
													'./'*,*|*,'./'*) cd "${directory:-${REPLY}}"; break 1;;
												esac
											done
										done
										cd "${CWD}" &>/dev/null
										break 1
										;;

									'manual',*|*,'manual')
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "Where? ('${config['TARMUX_ROOT']}'): "
										read -r -e TARMUX_ROOT
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Moving tarmux backup root directory '${config['TARMUX_ROOT']}' to '${TARMUX_ROOT:-${config['TARMUX_ROOT']}}'..."
										config['TARMUX_ROOT']="${TARMUX_ROOT:-${config['TARMUX_ROOT']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['TARMUX_ROOT']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting tarmux backup root directory configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
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
										cd "${config['TARMUX_DATA']}" &>/dev/null
										while true; do
											local glob="$(compgen -G './'*'/' &>/dev/null && echo '1')"
											select directory in 'select' 'clear' 'exit' "${PWD}" './..' ${glob:+./*/}; do
												case "${directory},${REPLY}" in
													'select',*|*,'select')
														local TARMUX_DATA="${PWD}"
														printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Moving tarmux backup data directory '${config['TARMUX_DATA']}' to '${TARMUX_DATA:-${config['TARMUX_DATA']}}'..."
														config['TARMUX_DATA']="${TARMUX_DATA:-${config['TARMUX_DATA']}}"
														test -n "${config['ALWAYS_SAVE']}" && save_config &&
														printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
														break 1
														;;

													'clear',*|*,'clear'|*,) clear; break 1;;
													'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting tarmux backup data directory explorer configuration...'; break 2;;
													'/'*,*|*,'/'*) read -p "/" -r -e; cd "/${REPLY}"; break 1;;
													'./..',*|*,'./..') cd ..; break 1;;
													'./'*,*|*,'./'*) cd "${directory:-${REPLY}}"; break 1;;
												esac
											done
										done
										cd "${CWD}" &>/dev/null
										break 1
										;;

									'manual',*|*,'manual')
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "Where? ('${config['TARMUX_DATA']}'): "
										read -r -e TARMUX_DATA
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Moving tarmux backup data directory '${config['TARMUX_DATA']}' to '${TARMUX_DATA:-${config['TARMUX_DATA']}}'..."
										config['TARMUX_DATA']="${TARMUX_DATA:-${config['TARMUX_DATA']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['TARMUX_DATA']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting tarmux backup data directory configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
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
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "Backup name? You can also include date formats like '%Y-%m-%d' ('${config['TARMUX_NAME']}'): "
										read -r -e TARMUX_NAME
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing tarmux backup name '${config['TARMUX_NAME']}' to '${TARMUX_NAME:-${config['TARMUX_NAME']}}'..."
										config['TARMUX_NAME']="${TARMUX_NAME:-${config['TARMUX_NAME']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['TARMUX_NAME']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting tarmux backup name configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
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
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "Backup extension? ('${config['TARMUX_EXT']}'): "
										read -r -e TARMUX_EXT
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing tarmux backup extension '${config['TARMUX_EXT']}' to '${TARMUX_EXT-${config['TARMUX_EXT']}}'..."
										config['TARMUX_EXT']="${TARMUX_EXT-${config['TARMUX_EXT']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['TARMUX_EXT']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting tarmux backup extension configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
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
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "What tarmux backup directories? Must be separated with '${config['TARMUX_IFS']}' ('${config['TARMUX_LIST']}'): "
										read -r -e TARMUX_LIST
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing tarmux backup directories '${config['TARMUX_LIST']}' to '${TARMUX_LIST:-${config['TARMUX_LIST']}}'..."
										config['TARMUX_LIST']="${TARMUX_LIST:-${config['TARMUX_LIST']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view')
										printf "${color['BCYAN']}%s\n${color['RESET']}${color['BWHITE']}${color['KBLACK']}" "Current: "
										IFS="${config['TARMUX_IFS']}" read -r -a backup_directories <<< "${config['TARMUX_LIST']}"
										for i in "${backup_directories[@]}"; do
											printf "\t'%s'\n" "${i}"
										done
										printf "%s${color['RESET']}"
										break 1
										;;

									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting tarmux backup directories configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
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
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "Directory Separator ('${config['TARMUX_IFS']}'): "
										read -r -e TARMUX_IFS
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing tarmux backup directories separator '${config['TARMUX_IFS']}' to '${TARMUX_IFS-${config['TARMUX_IFS']}}'..."
										config['TARMUX_IFS']="${TARMUX_IFS-${config['TARMUX_IFS']}}"
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['TARMUX_IFS']}'"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting tarmux backup directories separator configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
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
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Enabling...'
										config['REQUEST_STORAGE']='1'
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'disable',*|*,'disable')
										printf "${color['BRED']}%s\n${color['RESET']}" 'Disabling...'
										config['REQUEST_STORAGE']=''
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: $(test -n "${config['REQUEST_STORAGE']}" && echo 'true' || echo 'false')"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting request for storage configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
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
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Enabling...'
										config['ALWAYS_SAVE']='1'
										test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'disable',*|*,'disable')
										printf "${color['BRED']}%s\n${color['RESET']}" 'Disabling...'
										config['ALWAYS_SAVE']=''
										test -n "${config['ALWAYS_SAVE']}" && test -n "${config['ALWAYS_SAVE']}" && save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: $(test -n "${config['ALWAYS_SAVE']}" && echo 'true' || echo 'false')"; break 1;;
									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting always saving configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'save',*|*,'save') printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Saving configuration...'; save_config && printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'; break 1;;
					'reset',*|*,'reset')
						while true; do
							select option in 'reset' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'reset',*|*,'reset')
										printf "${color['RED']}%s${color['RESET']}" "Are you sure to reset the config from '${CONFIG_DIR:-/data/data/com.termux/files/home/.config/tarmux}/${CONFIG_FILE:-config}'? (y/N): "
										read -r -e # No -n1 because I am not that evil.
										case "${REPLY:-n}" in
											'y'|'Y')
												printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Resetting...'
												printf '' > "${CONFIG_DIR:-/data/data/com.termux/files/home/.config/tarmux}/${CONFIG_FILE:-config}" &&
												printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
												;;

											'n'|'N'|*) printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting resetting configuration confirmation...';;
										esac
										break 1
										;;

									'clear',*|*,'clear'|*,) clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting resetting configuration...'; break 2;;
								esac
							done
						done
						break 1
						;;

					'clear',*|*,'clear'|*,) clear; break 1;;
					'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting tarmux configuration...'; break 2;;
					*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
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
				'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting...'; break 2;;
				*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
			esac
		done
	done
}

version () {
	readarray config_variables <<-EOV
		$(for key in "${!config[@]}"; do echo "${key}: '${config[${key}]}'"; done)
	EOV
	printf "${color['BCYAN']}%s\n${color['RESET']}" "tarmux ${VERSION}"
	printf "${color['BPURPLE']}%s\n${color['RESET']}" "Config: '${CONFIG_DIR:-/data/data/com.termux/files/home/.config/tarmux}/${CONFIG_FILE:-config}'"
	printf "${color['BWHITE']}\t%s${color['RESET']}" "${config_variables[@]}"
}


# Check if backup data is not writable and can request permission.
while test '(' '!' -w "${config['TARMUX_DATA']}" ')' -a '(' -n "${config['REQUEST_STORAGE']}" ')'; do
	printf "${color['BCYAN']}%s\n${color['RESET']}" "No write permission on ${config['TARMUX_DATA']}. Requesting storage permission..."
	termux-setup-storage
done

test -n "${config['ALWAYS_SAVE']}" && save_config &&
options ${opt:-'--'} && # Without "" is necessary!!!
test -n "${config['ALWAYS_SAVE']}" && save_config
