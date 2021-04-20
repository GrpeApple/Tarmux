# `tarmux`
Tool to backup files on Termux with `tar`.

*Please lowercase `tarmux` and format it as code if possible; if the first word is at the start of a sentence you may not lowercase. This is to avoid confusion with Termux and `tarmux`.*

Issues may occur on Bash POSIX or Restricted mode when setting `bash -p` or `bash -r` respectively.

---

## Versions

There are two versions, *main* and *yagni*.

<!-- Change the link if you want to fork. -->
- [The *main* version contains so many overengineered features.](https://github.com/GrpeApple/tarmux/tree/main)
- [(Current) The *yagni* version stands for [*You aren't gonna need it*](https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it).](https://github.com/GrpeApple/tarmux/tree/yagni)

---

## Installation

```bash
chmod u+x ./tarmux
mv ./tarmux $PREFIX/bin
```

----
## Uninstallation

```bash
rm $PREFIX/bin/tarmux
```

----
## Usage

Run `./tarmux -h` or `./tarmux --help`

-----
### Configuration

You need to read and change the shell script of the *yagni* version.

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
			<code>-v</code>
		</td>
		<td>
			<code>--verbose</code>
		</td>
		<td>
			Enable verbose output of <code>tar</code>
		</td>
	</tr>
	<tr>
		<td>
			<code>-b</code>
		</td>
		<td>
			<code>--backup</code>
		</td>
		<td>Backup</td>
	</tr>
	<tr>
		<td>
			<code>-r BACKUP</code>
		</td>
		<td>
			<code>--restore=BACKUP</code>
		</td>
		<td>
			Restore from <code>BACKUP</code>
		</td>
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
