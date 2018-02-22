# Build and Run OrchidOS on Real Hardware
In this document, I outline the necessary dependencies and steps to build and install orchid onto a USB mass-storage device to boot off of on compatible legacy systems. **NOTE**: Orchid cannot run on CDs, and has not been tested on floppy disks. Try at your own peril!

**THIS IS A WINDOWS INSTALLATION METHOD ONLY, AND IS CURRENTLY THE ONLY WAY I HAVE CONFIGURED THE BUILD PROCESS.**

**THIS WILL CHANGE LATER TO BECOME MORE VERSATILE AND CROSS-PLATFORM COMPATIBLE.**

---

## Build Dependencies
- [QEMU Emulator](https://qemu.weilnetz.de/w64/) for Windows.
- [NASM v2.14+](http://www.nasm.us/pub/nasm/releasebuilds/2.14rc0/), under the Windows directories.
- [DD for Windows](http://www.chrysocome.net/dd).

**NOTE**: The NASM, QEMU, and DD directories need to be added onto the Windows PATH environment variable. If you don't do this, the compiler won't be happy! :O

### Other Requirements
- A USB drive, _preferably the smallest storage capacity you can find_, because every time you load the IMG onto the drive you'll have to format it with DISKPART. This takes significantly less time with a smaller storage capacity.
- Test hardware -- that is, the computer you want to run Orchid on. It must be a BIOS-enabled system with _non-UEFI_ firmware. These are typically older systems that were manufactured before some time circa 2010.

---

## How to Compile it
Simply double-click the `/src/__compile32.bat` file to compile the binary image, granted you have installed and configured the dependencies for the project. You might need to run it as an Administrator, depending on your current user privileges.

This is a **one-script solution** for building the OS and then running it with the emulator. After that, use the `/src/__run32.bat` file to emulate it directly, without having to build it again.

---

## Installing it onto a USB Drive
This is the hard part and is by FAR the most time-consuming. Eventually, this will be pared down to simply creating a new disk partition to boot from, but the way I built the OS uses absolute memory references that, _for now_, require a custom MBR solution.

In this section, I will reference the compiling system and the testing system as the _build_ computer and the _test_ computer, respectively.

**DO NOT PROCEED WITH THIS UNLESS YOU ARE COMFORTABLE WITH LOSING ALL DATA ON YOUR USB DRIVE!**

1. Plug in your USB drive to your _build_ computer. Obvious, I know. :)
2. Open up a command prompt with Administrative permissions.
3. Execute these commands... **EXPLAINED BELOW THE IMAGE. DO NOT COPY IT VERBATIM.**
![Use the Windows DISKPART utility to format your USB drive to prepare the installation.](https://github.com/ZacharyPuhl/OrchidOS_x86/blob/master/res/documentation_imgs/diskpart_cleaning.png "Using DISKPART to format your OrchidOS USB Drive...")
> - Start the DISKPART utility, find your USB disk ID based on its size in the 'list disk' output. Select it.
> - List the volumes; select the volume ID that corresponds to your USB drive's drive letter (for example, D-drive or F-drive).
> - Format it, then clean it. Your disk is set for installation, exit DISKPART with 'exit' command.
4. Navigate to your orchidOS /bin/ directory to prepare for installation.
5. To know which device and partition to replace, use the command `dd --list`, and find your USB device.
![Use the "dd --list" command to find the USB Device's 0th Partition to overwrite](https://github.com/ZacharyPuhl/OrchidOS_x86/blob/master/res/documentation_imgs/dd_--list.png "Finding the USB Device's 0th Partition to overwrite.")
6. Once you have your device, execute the command below with `if=[orchidOS_image_file.img]` and `of=\\?\Device\Harddisk[USB Device
 #]\Partition0`. **The command in the image below is an example. This can do damage to your computer if you make a mistake.**
![Use DD for Windows to inject the Orchid image onto the USB drive.](https://github.com/ZacharyPuhl/OrchidOS_x86/blob/master/res/documentation_imgs/dd_cmd.png "Using the DD for Windows utility to inject the orchidOS image onto the MBR of the USB drive.")
7. Eject the USB drive, plug it into an OFF _test_ computer, and fire up the _test_ computer.
8. Make sure your boot order in your BIOS menu is set to boot off of USB devices before the Hard Drive, or simply use the BIOS boot menu to select the USB to boot from.
9. If there are any issues with the boot process, it's likely there's a bug that needs some fixin'. Seriously, _report it to me_ and I'll be on it ASAP.
10. Enjoy!
