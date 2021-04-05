#!/data/data/com.termux/files/usr/bin/env bash

opt="$(getopt --options 'hV' --alternative --longoptions 'help,version' --name 'tarmux' --shell 'bash' -- "${@}")"

options () {
	while true; do
		case "${1}" in
			' '|'-h'|'--help')
				usage
				break
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
Usage: $(basename "${0}") -[[h|-help]|[v|-version]]
Options:
	-h	Show this help usage
	-V	Display version and information
EOU
}

version () {
	cat <<-EOV
		Tarmux v0.0.3
	EOV
}


options ${opt}
