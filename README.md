# Tarmux
Backup files on Termux with `tar`

---

## Installation

----
### Install `make`

```bash
apt update
apt full-upgrade
apt install make
```

-----
### Installing

```bash
make build
make install
tarmux -c # Select installation
```

----
## Uninstallation

You must install [`make`](#install-make)

-----
### Uninstall

```bash
tarmux -c # Select uninstallation
make clean
make uninstall
```

-----
### Uninstall `make`

```bash
apt autoremove make
```

----
## Usage

-----
### Configuration

There is a config (`CONFIG_DIR` (default: `/data/data/com.termux/files/home/.config/tarmux`)/`CONFIG_FILE` (default: `config`)) file (default: `/data/data/com.termux/files/home/.config/tarmux`).

You are responsible for your actions of adding dangerous stuff to your config file. (It uses `source` so it will run commands like `rm -rf *` if added to the config file)

-----
### Options

You can use `-some-long-option` or `-some-long` and it will still work.

------
<table>
<thead>
	<tr>
		<th>Option</th>
		<th>Long option</th>
		<th>Description</th>
	</tr>
</thead>
<tbody>
	<tr>
		<td>
			<code>-h</code>
		</td>
		<td>
			<code>--help</code>
		</td>
		<td>Display help message</td>
	</tr>
	<tr>
		<td>
			<code>-c</code>
		</td>
		<td>
			<code>--configure</code>
		</td>
		<td>Configure and install, uninstall packages</td>
	</tr>
	<tr>
		<td>
			<code>-V</code>
		</td>
		<td>
			<code>--version</code>
		</td>
		<td>Display version and information</td>
	</tr>
</tbody>
</table>
