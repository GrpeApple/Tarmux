#!/data/data/com.termux/files/usr/bin/env bash

VERSION='v0.1.0.1'

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
declare -A config=(
	['INSTALL']="$(realpath "${0:-tarmux}")"
)

CONFIG_DIR="${HOME:-'/data/data/com.termux/files/home'}/.config/tarmux"
CONFIG_FILE="config"

mkdir --parents "${CONFIG_DIR:-'/data/data/com.termux/files/home/.config/tarmux'}"
touch "${CONFIG_DIR:-'/data/data/com.termux/files/home/.config/tarmux'}/${CONFIG_FILE:-'config'}"

INSTALL="${config['INSTALL']}"

# You are responsible for putting dangerous stuff in the config file.
source "${CONFIG_DIR:-'/data/data/com.termux/files/home/.config/tarmux'}/${CONFIG_FILE:-'config'}"

if [[ "${INSTALL}" != "${config['INSTALL']}" ]]; then
	readarray warning <<-EOW
		WARNING: moving ${INSTALL} to ${config['INSTALL']}.
		Use ${0:-tarmux} -c and select 'Installation directory' to move; or use ${0:-tarmux} -c and select 'reset' then move it to the desired location.
	EOW
	printf "${color['BYELLOW']}%s${color['RESET']}" "${warning[@]}" >&2
	mv --interactive --no-target-directory "${INSTALL}" "${config['INSTALL']}"
fi

opt="$(getopt --options 'hcV' --alternative --longoptions 'help,configure,version' --name 'tarmux' --shell 'bash' -- "${@:---}")"

ACTIONS=('install' 'uninstall' 'tarmux')
PACKAGES=('tar' 'pigz' 'zstd')
CONFIGURATIONS=('Installation directory' 'reset')

save_config () {
	cat > "${CONFIG_DIR:-'/data/data/com.termux/files/home/.config/tarmux'}/${CONFIG_FILE:-'config'}" <<-EOC
		$(for key in "${!config[@]}"; do echo "config['${key}']='${config[${key}]}'"; done)
	EOC
}

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

			'--')
				break 1
				;;

			*) printf "${color['BRED']}%s\n${color['RESET']}" 'Unknown error' >&2; exit 1; break 1;;
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

configure () {
	installPkg () {
		while true; do
			select package in 'update' 'upgrade' "${PACKAGES[@]}" 'clear' 'exit'; do
				case "${package:-'exit'},${REPLY:-'exit'}" in
					'update',*|*,'update')
						printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Updating apt'
						apt update &&
						printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
						break 1
						;;

					'upgrade',*|*,'upgrade')
						printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Upgrading packages'
						apt full-upgrade &&
						printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
						break 1
						;;

					'tar'*,*|*,'tar'*)
						printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Installing tar'
						apt install tar &&
						printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
						break 1
						;;

					'pigz',*|*,'pigz')
						printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Installing pigz'
						apt install pigz &&
						printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
						break 1
						;;

					'zstd',*|*,'zstd')
						printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Installing zstd'
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
	uninstallPkg () {
		while true; do
			select package in "${PACKAGES[@]}" 'clear' 'exit'; do
				case "${package:-'exit'},${REPLY:-'exit'}" in
					'tar'*,*|*,'tar'*)
						printf "${color['BRED']}%s\n${color['RESET']}" 'Uninstalling tar (dangerous)'
						apt autoremove tar &&
						printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
						break 1
						;;

					'pigz',*|*,'pigz')
						printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Uninstalling pigz'
						apt autoremove pigz &&
						printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
						break 1
						;;

					'zstd',*|*,'zstd')
						printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Uninstalling zstd'
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
	tarmuxConf () {
		while true; do
			select configuration in "${CONFIGURATIONS[@]}" 'clear' 'exit'; do
				case "${configuration:-'exit'},${REPLY:-'exit'}" in
					'Installation directory',*|*,'Installation directory')
						while true; do
							printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" "Are you sure to move ${config['INSTALL']} to another location? (y/N): "
							read -r -e # No -n1 because I am not that evil.
							case "${REPLY:-'n'}" in
								'y'|'Y')
									printf "${color['BGREEN']}%s\n${color['RESET']}" 'Continuing...'
									printf "${color['BWHITE']}${color['KBLACK']}%s${color['RESET']}" 'Where? (): '
									read -r -e INSTALL
									printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" "Moving ${config['INSTALL']} to ${INSTALL:-"${config['INSTALL']}"}..."
									mv --interactive --no-target-directory "${config['INSTALL']}" "${INSTALL:-"${config['INSTALL']}"}" || exit 1
									config['INSTALL']="${INSTALL:-"${config['INSTALL']}"}"
									save_config &&
									printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
									break 1
									;;

								'n'|'N'|*)
									printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting installation directiory configuration...'
									break 1
									;;
							esac
						done
						break 1
						;;

					'reset',*|*,'reset')
						printf "${color['RED']}%s${color['RESET']}" "Are you sure to reset the config from ${CONFIG_DIR:-'/data/data/com.termux/files/home/.config/tarmux'}/${CONFIG_FILE:-'config'}? (y/N): "
						read -r -e # No -n1 because I am not that evil.
						case "${REPLY:-'n'}" in
							'y'|'Y')
								printf "${color['BWHITE']}${color['KBLACK']}%s\n${color['RESET']}" 'Resetting...'
								printf '' > "${CONFIG_DIR:-'/data/data/com.termux/files/home/.config/tarmux'}/${CONFIG_FILE:-'config'}" &&
								printf "${color['BGREEN']}%s\n${color['RESET']}" 'Done!'
								;;

							'n'|'N'|*)
								printf "${color['BRED']}%s\n${color['RESET']}" 'Exiting resetting configuration...'
								;;
						esac
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
readarray config_variables <<EOV
	$(for key in "${!config[@]}"; do echo "${key}: '${config[${key}]}'"; done)
EOV
	printf "${color['BCYAN']}%s\n${color['RESET']}" "tarmux ${VERSION}" >&2
	printf "${color['BPURPLE']}%s\n${color['RESET']}" "Config: '${CONFIG_DIR:-'/data/data/com.termux/files/home/.config/tarmux'}/${CONFIG_FILE}'" >&2
	printf "${color['BWHITE']}%s${color['RESET']}" "${config_variables[@]}" >&2
}


save_config
options ${opt:-'--'} # Without "" is necessary!!!
