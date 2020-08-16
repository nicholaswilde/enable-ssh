# enable-ssh
Enable ssh in a linux image

This script takes a zipped headless image file and adds [an ssh file to the boot partition](https://www.raspberrypi.org/documentation/remote-access/ssh/) to enable SSH on first boot.

## Usage
```
sudo ./enable-ssh.sh linux-image.zip
```

## Notes
- XZ and ZIP file compression formats are supported.
- The exported zip file is exported to the current working directory.
- The exported zip file adds a -1 to the end of the file name.
- The COMPRESSION_PRESET variable can be adjusted for the [xz compression](https://linux.die.net/man/1/xz).

## Tested Images
- [Rasberry Pi OS](https://www.raspberrypi.org/downloads/raspberry-pi-os/)
- [Hypriot](https://blog.hypriot.com/downloads/)
