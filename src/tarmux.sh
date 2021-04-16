#!/data/data/com.termux/files/usr/bin/env bash

VERSION='v0.2.1.3'

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
	*'r'*) printf "${color['BYELLOW']}%s\n${color['RESET']}" 'WARNING: bash in restricted mode.' >&2;;
	*'p'*) printf "${color['BYELLOW']}%s\n${color['RESET']}" 'WARNING: bash in POSIX mode.' >&2;;
esac

# Configuration
## tarmux preferences
declare -A config=(
	['INSTALL']="$(realpath "${0:-./tarmux}")"
	['BACKUP_DATA']='/storage/emulated/0/Download'
	['BACKUP_NAME']='termux_backup_%Y-%m-%d_%H-%M-%S-%N'
	['BACKUP_EXT']='.bak'
	['BACKUP_ROOT']='/data/data/com.termux/files'
	['BACKUP_LIST']='home|usr'
	['BACKUP_IFS']='|'
	['REQUEST_STORAGE']='1'
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
CONFIGURATIONS=('Installation directory' 'Backup data directory' 'Backup name' 'Backup extension' 'Backup root directory' 'Backup directories' 'Backup directories separator' 'Always ask storage permission' 'reset')

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
			'-h'|'--help')
				usage
				break 1
				;;

			'-c'|'--configure')
				configure
				shift 1
				continue
				;;

			'-V'|'--version')
				version
				shift 1
				continue
				;;

					## tarmux configuration
			'--')
				test -z "${opt:4}" && usage ## Check if no options, then display usage.
				break 1
				;;

			*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown error' >&2; exit 1; break 1;; # This should not happen unless a change to the program is made.
		esac
	done
}

usage () {
	printf "${color['BCYAN']}%s\n${color['RESET']}" "Usage: $(basename "${config['INSTALL']}") -[[h|[-]help]|[c|[-]configure]|[v|[-]version]]"
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
			select package in 'update' 'upgrade' 'repository' "${PACKAGES[@]}" 'clear' 'exit'; do
				case "${package},${REPLY}" in
					'update',*|*,'update')
						printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Updating apt...'
						apt update &&
						printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
						break 1
						;;

					'upgrade',*|*,'upgrade')
						printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Upgrading packages...'
						apt full-upgrade &&
						printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
						break 1
						;;

					'repository',*|*,'repository')
						printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing Termux's repositories..."
						termux-change-repo &&
						printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
						break 1
						;;

					'tar',*|*,'tar')
						printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Installing tar...'
						apt install tar &&
						printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
						break 1
						;;

					'pigz',*|*,'pigz')
						printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Installing pigz...'
						apt install pigz &&
						printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
						break 1
						;;

					'zstd',*|*,'zstd')
						printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Installing zstd...'
						apt install zstd &&
						printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
						break 1
						;;

					'clear',*|*,'clear') clear; break 1;;
					'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting installation...'; break 2;;
					*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
				esac
			done
		done
	}
	## Uninstallation
	uninstallPkg () {
		while true; do
			select package in "${PACKAGES[@]}" 'clear' 'exit'; do
				case "${package},${REPLY}" in
					'tar',*|*,'tar')
						printf "${color['BRED']}%s\n${color['RESET']}" 'Uninstalling tar (dangerous)...'
						apt autoremove tar &&
						printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
						break 1
						;;

					'pigz',*|*,'pigz')
						printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Uninstalling pigz...'
						apt autoremove pigz &&
						printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
						break 1
						;;

					'zstd',*|*,'zstd')
						printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Uninstalling zstd...'
						apt autoremove zstd &&
						printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
						break 1
						;;

					'clear',*|*,'clear') clear; break 1;;
					'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting uninstallation...'; break 2;;
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
														mv --interactive --no-target-directory "${config['INSTALL']}" "${PWD}/${INSTALL:-$(basename "${config['INSTALL']}")}" || exit 1
														config['INSTALL']="${PWD}/${INSTALL:-$(basename "${config['INSTALL']}")}"
														save_config &&
														printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
														break 1
														;;

													'clear',*|*,'clear') clear; break 1;;
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
										mv --interactive --no-target-directory "${config['INSTALL']}" "${INSTALL:-${config['INSTALL']}}" || exit 1
										config['INSTALL']="${INSTALL:-${config['INSTALL']}}"
										save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['INSTALL']}'"; break 1;;
									'clear',*|*,'clear') clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting installation directory configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Backup data directory',*|*,'Backup data directory')
						while true; do
							select option in 'explorer' 'manual' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'explorer',*|*,'explorer')
										cd "${config['BACKUP_DATA']}" &>/dev/null
										while true; do
											local glob="$(compgen -G './'*'/' &>/dev/null && echo '1')"
											select directory in 'select' 'clear' 'exit' "${PWD}" './..' ${glob:+./*/}; do
												case "${directory},${REPLY}" in
													'select',*|*,'select')
														local BACKUP_DATA="${PWD}"
														printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Moving backup data directory '${config['BACKUP_DATA']}' to '${BACKUP_DATA:-${config['BACKUP_DATA']}}'..."
														config['BACKUP_DATA']="${BACKUP_DATA:-${config['BACKUP_DATA']}}"
														save_config &&
														printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
														break 1
														;;

													'clear',*|*,'clear') clear; break 1;;
													'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting backup data directory explorer configuration...'; break 2;;
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
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "Where? ('${config['BACKUP_DATA']}'): "
										read -r -e BACKUP_DATA
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Moving backup data directory '${config['BACKUP_DATA']}' to '${BACKUP_DATA:-${config['BACKUP_DATA']}}'..."
										config['BACKUP_DATA']="${BACKUP_DATA:-${config['BACKUP_DATA']}}"
										save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['BACKUP_DATA']}'"; break 1;;
									'clear',*|*,'clear') clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting backup data directory configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Backup name',*|*,'Backup name')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'change',*|*,'change')
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "Backup name? You can also include date formats like '%Y-%m-%d' ('${config['BACKUP_NAME']}'): "
										read -r -e BACKUP_NAME
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing backup name '${config['BACKUP_NAME']}' to '${BACKUP_NAME:-${config['BACKUP_NAME']}}'..."
										config['BACKUP_NAME']="${BACKUP_NAME:-${config['BACKUP_NAME']}}"
										save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['BACKUP_NAME']}'"; break 1;;
									'clear',*|*,'clear') clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting backup name configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Backup extension',*|*,'Backup extension')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'change',*|*,'change')
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "Backup extension? ('${config['BACKUP_EXT']}'): "
										read -r -e BACKUP_EXT
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing backup extension '${config['BACKUP_EXT']}' to '${BACKUP_EXT:-${config['BACKUP_EXT']}}'..."
										config['BACKUP_EXT']="${BACKUP_EXT:-${config['BACKUP_EXT']}}"
										save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['BACKUP_EXT']}'"; break 1;;
									'clear',*|*,'clear') clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting backup extension configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Backup root directory',*|*,'Backup root directory')
						while true; do
							select option in 'explorer' 'manual' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'explorer',*|*,'explorer')
										cd "${config['BACKUP_ROOT']}" &>/dev/null
										while true; do
											local glob="$(compgen -G './'*'/' &>/dev/null && echo '1')"
											select directory in 'select' 'clear' 'exit' "${PWD}" './..' ${glob:+./*/}; do
												case "${directory},${REPLY}" in
													'select',*|*,'select')
														local BACKUP_ROOT="${PWD}"
														printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Moving backup root directory '${config['BACKUP_ROOT']}' to '${BACKUP_ROOT:-${config['BACKUP_ROOT']}}'..."
														config['BACKUP_ROOT']="${BACKUP_ROOT:-${config['BACKUP_ROOT']}}"
														save_config &&
														printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
														break 1
														;;

													'clear',*|*,'clear') clear; break 1;;
													'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting backup root directory explorer configuration...'; break 2;;
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
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "Where? ('${config['BACKUP_ROOT']}'): "
										read -r -e BACKUP_ROOT
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Moving backup root directory '${config['BACKUP_ROOT']}' to '${BACKUP_ROOT:-${config['BACKUP_ROOT']}}'..."
										config['BACKUP_ROOT']="${BACKUP_ROOT:-${config['BACKUP_ROOT']}}"
										save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['BACKUP_ROOT']}'"; break 1;;
									'clear',*|*,'clear') clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting backup root directory configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Backup directories',*|*,'Backup directories')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'change',*|*,'change')
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "What backup directories? Must be separated with '${config['BACKUP_IFS']}' ('${config['BACKUP_LIST']}'): "
										read -r -e BACKUP_LIST
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing backup directories '${config['BACKUP_LIST']}' to '${BACKUP_LIST:-${config['BACKUP_LIST']}}'..."
										config['BACKUP_LIST']="${BACKUP_LIST:-${config['BACKUP_LIST']}}"
										save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view')
										printf "${color['BCYAN']}%s\n${color['RESET']}${color['BWHITE']}${color['KBLACK']}" "Current: "
										IFS="${config['BACKUP_IFS']}" read -r -a backup_directories <<< "${config['BACKUP_LIST']}"
										for i in "${backup_directories[@]}"; do
											printf "\t'%s'\n" "${i}"
										done
										printf "%s${color['RESET']}"
										break 1
										;;

									'clear',*|*,'clear') clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting backup directories configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

					'Backup directories separator',*|*,'Backup directories separator')
						while true; do
							select option in 'change' 'view' 'clear' 'exit'; do
								case "${option},${REPLY}" in
									'change',*|*,'change')
										printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "Directory Separator ('${config['BACKUP_IFS']}'): "
										read -r -e BACKUP_IFS
										printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Changing Backup directory separator'${config['BACKUP_IFS']}' to '${BACKUP_IFS:-${config['BACKUP_IFS']}}'..."
										config['BACKUP_IFS']="${BACKUP_IFS:-${config['BACKUP_IFS']}}"
										save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: '${config['BACKUP_IFS']}'"; break 1;;
									'clear',*|*,'clear') clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting backup directories separator configuration...'; break 2;;
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
										save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'disable',*|*,'disable')
										printf "${color['BRED']}%s\n${color['RESET']}" 'Disabling...'
										config['REQUEST_STORAGE']=''
										save_config &&
										printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
										break 1
										;;

									'view',*|*,'view') printf "${color['BCYAN']}%s\n${color['RESET']}" "Current: $(test -n "${config['REQUEST_STORAGE']}" && echo 'true' || echo 'false')"; break 1;;
									'clear',*|*,'clear') clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting request for storage configuration...'; break 2;;
									*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown option' >&2; break 1;;
								esac
							done
						done
						break 1
						;;

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

									'clear',*|*,'clear') clear; break 1;;
									'exit',*|*,'exit') printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting resetting configuration...'; break 2;;
								esac
							done
						done
						break 1
						;;

					'clear',*|*,'clear') clear; break 1;;
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
				'clear',*|*,'clear') clear; break 1;;
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
while test '(' '!' -w "${config['BACKUP_DATA']}" ')' -a '(' -n "${config['REQUEST_STORAGE']}" ')'; do
	printf "${color['BCYAN']}%s\n${color['RESET']}" "No write permission on ${config['BACKUP_DATA']}. Requesting storage permission..."
	termux-setup-storage
done

save_config
options ${opt:-'--'} # Without "" is necessary!!!
