#!/data/data/com.termux/files/usr/bin/env bash

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
