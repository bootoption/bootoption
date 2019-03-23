#  bootoption

<p align="center">
<img src="https://github.com/bootoption/bootoption/raw/master/Screenshot.png" alt="bootoption screenshot" width="700" />
</p>

EFI boot menu manipulation for macOS, report bugs [here on GitHub](https://github.com/bootoption/bootoption/issues).

## Install

Install bootoption with [Homebrew](https://docs.brew.sh/Installation):

```
brew tap bootoption/repo
brew install bootoption
```

## Usage

bootoption \<command> [options]

available commands:

- <strong>list</strong>&nbsp;&nbsp;show the firmware boot menu
- <strong>info</strong>&nbsp;&nbsp;show an option's properties
- <strong>create</strong>&nbsp;&nbsp;create a new load option and add it to the boot order
- <strong>order</strong>&nbsp;&nbsp;change the boot order
- <strong>set</strong>&nbsp;&nbsp;set firmware variables
- <strong>delete</strong>&nbsp;&nbsp;unset firmware variables
- <strong>reboot</strong>&nbsp;&nbsp;reboot to firmware settings

#### Create a new option and add it to the boot order

```
sudo bootoption create -l /Volumes/EFI/EFI/GRUB/GRUBX64.EFI -d "GNU GRUB"
```

#### Move an option from 4th to 1st in the boot order

```
sudo bootoption order 4 1
```

#### Disable an option

```
sudo bootoption set -n Boot0002 --active 0
```

#### Change the boot menu timeout to 10 seconds

```
sudo bootoption set -t 10
```

#### Set an option's command line argmuments

```
sudo bootoption set -n Boot0000 -a "initrd=/initramfs.img root=/dev/disk/by-uuid/346d9a61-f7e5-4f58-bad7-026bb5376e0f"
```

#### Reboot to firmware settings

```
sudo bootoption reboot
```

### System Integrity Protection

Note: csrutil needs to be executed from the Recovery OS.

##### Disable SIP

```
csrutil disable
```

##### Disable only NVRAM protections

```
csrutil enable --without nvram
```

## License

Copyright © vulgo 2017-2019

bootoption is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).

Individual files contain the following tag instead of the full license text:

```
SPDX-License-Identifier: GPL-3.0-or-later
```

This enables machine processing of license information based on the SPDX License Identifiers that are available here: [http://spdx.org/licenses/](http://spdx.org/licenses/).
