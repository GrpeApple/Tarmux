#!/data/data/com.termux/files/usr/bin/env bash

opt="$(getopt --options 'hcV' --alternative --longoptions 'help,configure,version' --name 'tarmux' --shell 'bash' -- "${@}")"

options () {
	while true; do
		case "${1}" in
			'-h'|'--help')
				usage
				break
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
				break
				;;

			*)
				echo 'Unknown error' >&2
				exit 1
				break
				;;
		esac
	done
}

usage () {
cat <<EOU
Usage: $(basename "${0}") -[[h|[-]help]|[v|[-]version]]
Options:
	-h|-help	Display this help usage
	-c|-configure	Configure
	-V|-version	Display version and information
EOU
}

configure () {
	installPkg () {
		select compression in 'update' 'upgrade' 'tar (default)' 'tar (pigz)' 'tar (zstd)' 'clear' 'exit'; do
			case "${compression},${REPLY}" in
				'update',*|*,'update')
					echo 'Updating apt'
					apt update
					;;
				'upgrade',*|*,'upgrade')
					echo 'Upgrading packages'
					apt full-upgrade -y
					;;
				'tar (default)',*|*,'tar (default)')
					echo 'Installing tar (default)'
					apt install tar
					;;
				'tar (pigz)',*|*,'tar (pigz)')
					echo 'Installing tar (pigz)'
					apt install tar pigz
					;;
				'tar (zstd)',*|*,'tar (zstd)')
					echo 'Installing tar (zstd)'
					apt install tar zstd
					;;
				'clear',*|*,'clear')
					clear
					;;
				'exit',*|*,'exit')
					echo 'Exiting installation'
					break
					;;
				*)
					echo "Unknown option"
					;;
			esac
		done
	}
	uninstallPkg () {
		select compression in 'tar (default)' 'tar (pigz)' 'tar (zstd)' 'clear' 'exit'; do
			case "${compression},${REPLY}" in
				'tar (default)',*|*,'tar (default)')
					echo 'Uninstalling tar (default)'
					apt autoremove tar
					;;
				'tar (pigz)',*|*,'tar (pigz)')
					echo 'Uninstalling tar (pigz)'
					apt autoremove tar pigz
					;;
				'tar (zstd)',*|*,'tar (zstd)')
					echo 'Uninstalling tar (zstd)'
					apt autoremove tar zstd
					;;
				'clear',*|*,'clear')
					clear
					;;
				'exit',*|*,'exit')
					echo 'Exiting uninstallation'
					break
					;;
				*)
					echo "Unknown option"
					;;
			esac
		done
	}
	select choice in 'install' 'uninstall' 'exit'; do
		case "${choice},${REPLY}" in
			'install',*|*,'install') installPkg;;
			'uninstall',*|*,'uninstall') uninstallPkg;;
			'exit',*|*,'exit')
				echo 'Exiting'
				break
				;;
		esac
	done
}

version () {
	cat <<-EOV
		Tarmux v0.0.3.1
	EOV
}


options ${opt}
