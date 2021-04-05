# Tarmux
Backup files on Termux with tar

---

## Installation

### Install `make`



```bash
apt update
apt full-upgrade -y
apt install make -y
```

### Installing

```bash
./install.sh
make build
make install
```



## Uninstallation

You must install [`make`](#install-make)

### Uninstall



```bash
./uninstall.sh
make clean
make uninstall
```


### Uninstall `make`



```bash
apt autoremove make
```

----

## Usage

You can use `-some-long-option` or `-some-long` and it will still work.

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
			<code>-V</code>
		</td>
		<td>
			<code>--version</code>
		</td>
		<td>Display version and information</td>
	</tr>
</tbody>
</table>
