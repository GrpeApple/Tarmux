# Tarmux
Backup files on Termux with `tar`

Issues may occur on Bash POSIX or Restricted mode when setting `bash -p` or `bash -r` respectively.

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


Some actions are self-explanatory and are not explained in this table.

You are to configure with `tarmux -c`.

------
<table>
<thead>
	<tr>
		<th>Action</th>
		<th>Description</th>
		<th>Configuration</th>
	</tr>
</thead>
<tbody>
	<tr>
		<td>
			<code>install</code>
		</td>
		<td>Install packages for backing up and restoring.</td>
		<td>
			Packages
			<ul>
				<li>
					<code>tar</code>
				</li>
				<li>
					<code>pigz</code>
				</li>
				<li>
					<code>zstd</code>
				</li>
			</ul>
		</td>
	</tr>
	<tr>
		<td>
			<code>uninstall</code>
		</td>
		<td>Uninstall packages for backing up and restoring.</td>
		<td>
			Packages
			<ul>
				<li>
					<code>tar</code>
				</li>
				<li>
					<code>pigz</code>
				</li>
				<li>
					<code>zstd</code>
				</li>
			</ul>
		</td>
	</tr>
	<tr>
		<td>
			<code>tarmux</code>
		</td>
		<td>
			The real configuration of <code>tarmux</code> starts here.
		</td>
		<td>
			<table>
			<thead>
				<tr>
					<th>Configuration</th>
					<th>Description</th>
				</tr>
			</thead>
			<tbody>
				<tr>
					<td>
						<code>Installation directory</code>
					</td>
					<td>
						Location of where `tarmux` lives at, once you run `tarmux` you have to configure so as to move it to a different location (You can also <code>reset</code> it and move it; this will be explained in another row).
					</td>
				</tr>
				<tr>
					<td>
						<code>Backup root directory</code>
					</td>
					<td>
						Location of where your termux backup directories.
					</td>
				</tr>
				<tr>
					<td>
						<code>Backup data directory</code>
					</td>
					<td>Location of your backups.</td>
				</tr>
				<tr>
					<td>
						<code>Backup name</code>
					</td>
					<td>
						Name of your backups, since this also has <code>date</code> within, you can use control characters (the list of it is in <code>man date</code> or any other help page) to add the date of your backup.
					</td>
				</tr>
				<tr>
					<td>
						<code>Backup extension</code>
					</td>
					<td>Self-explanatory; extension of your backup filename.</td>
				</tr>
				<tr>
					<td>
						<code>Backup directories</code>
					</td>
					<td>
						Your <code>tarmux</code> backup directories.<br>
						On how to separate them is explained on another row.
					</td>
				</tr>
				<tr>
					<td>
						<code>Backup directories separator</code>
					</td>
					<td>
						Backup directory separator<br>
						For example:<br>
						<code>home[separator]usr</code>
					</td>
				</tr>
				<tr>
					<td>
						<code>reset</code>
					</td>
					<td>Self-explanatory; reset your config file to the defaults.</td>
				</tr>
			</tbody>
			</table>
		</td>
	</tr>
</tbody>
</table>

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
			<code></code>
		</td>
		<td>
			<code></code>
		</td>
		<td>Display help message</td>
	</tr>
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
