#!/data/data/com.termux/files/usr/bin/env bash

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
