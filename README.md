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

---

# [LICENSE](LICENSE)
```
MIT License

Copyright (c) 2020 GrpeApple

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
