# Build and Run OrchidOS on Real Hardware
In this document, I outline the necessary dependencies and steps to build and install orchid onto a USB mass-storage device to boot off of on compatible systems. **NOTE**: Orchid cannot run on CDs, and has not been tested on floppy disks. Try at your own peril!

---

# Linux

## A Quick Start for Linux users...
You could always use the Bash scripts I've now written to test the OS in QEMU/KVM on Linux.

Linux users are likely to be the most interested parties, so I'm slowly transitioning the project to mostly support Linux development. I now use Arch Linux daily (_I use Arch btw_) to compile and test the system.

I'm sure a simple compilation and DD of the image using the instructions below wouldn't be a challenge whatsoever to a Linux-savvy user, but I will eventually expand on this when I get more interest/time.

### Installing and compiling manually
I will add more Linux versions (and specific guides) as people suggest/request them, or as I find the time to do it manually. Instead of doing this manually, you can always run my premade `__compile32.sh` shell script (**this "guide" is literally a copy-paste of the script**).

**NOTE IN THESE QEMU INSTALLATIONS THAT ORCHID IS MOSTLY TESTED ON THE qemu-system-x86_64 EXECUTABLE!**

#### Installation & Setup
Prepare to compile and "link" the repo.
- `sudo [your-package-mgr] nasm qemu[-kvm] git`: Install NASM & QEMU.
- `git clone https://github.com/ZacharyPuhl/OrchidOS_x86`: In case you haven't pulled the Orchid repo yet.
- `cd [the-orchid-src-directory]`: Navigate to the **src** directory of the Orchid repo you have cloned to your computer.
- If it does not exist already (it **DOES NOT** by default until the official release): `mkdir "../bin"`. If it already exists and you have compiled before: `rm -f "../bin/image.img"`.
#### Compiling & "Linking"
Generate the binary image to run with QEMU.
- `nasm "./core/BOOT.asm" -f bin -o "../bin/boot.bin"`: Compile the MBR.
- `nasm "./core/BOOT_ST2.asm" -f bin -o "../bin/boot2.bin"`: Compile the Stage-2 loader.
- `nasm "./core/KERNEL.asm" -f bin -o "../bin/kernel.bin"`: Compile the Kernel.
- `dd if="../bin/boot.bin" of="../bin/image.img" bs=512`
- `dd if="../bin/boot2.bin" of="../bin/image.img" bs=512 seek=1`
- `dd if="../bin/kernel.bin" of="../bin/image.img" bs=512 seek=3`
#### Cleanup
Clean up the NASM-compiled binaries (we don't need them).
- `rm -f "../bin/boot.bin"`
- `rm -f "../bin/boot2.bin"`
- `rm -f "../bin/kernel.bin"`
#### Run it!
These are the optimal settings to test and run the Orchid image through QEMU. Make sure you have the proper QEMU executable.
- `qemu-system-x86_64 \
    -m 8G -usb -device usb-ehci,id=ehci \
    -device isa-debug-exit,iobase=0xF4,iosize=0x04 \
    -netdev user,id=eth0,net=10.0.2.0/24,dhcpstart=10.0.2.6,hostfwd=tcp::5555-:22 \
    -device e1000,netdev=eth0,mac=11:22:33:44:55:66 \
    -drive format=raw,index=0,file="../bin/image.img" \
    -object filter-dump,id=eth0,netdev=eth0,file="~/Documents/QEMUDUMP.txt"`

---

# Windows

## Build Dependencies
- [QEMU Emulator](https://qemu.weilnetz.de/w64/) for Windows.
- [NASM v2.14+](http://www.nasm.us/pub/nasm/releasebuilds/2.14rc0/), under the Windows directories.
- [DD for Windows](http://www.chrysocome.net/dd).

**NOTE**: The NASM, QEMU, and DD directories need to be added onto the Windows PATH environment variable. If you don't do this, the compiler won't be happy! :O

### Other Requirements
- A USB drive, _preferably the smallest storage capacity you can find_, because every time you load the IMG onto the drive you'll have to format it with DISKPART. This takes significantly less time with a smaller storage capacity.
- Test hardware -- that is, the computer you want to run Orchid on. It must be a BIOS-enabled system with _non-UEFI_ firmware, **or** a BIOS/CPU with legacy compatibility.

## How to Compile it
Simply double-click the `/src/__compile32.bat` file to compile the binary image, granted you have installed and configured the dependencies for the project. You might need to run it as an Administrator, depending on your current user privileges.

This is a **one-script solution** for building the OS and then running it with the emulator. After that, use the `/src/__run32.bat` file to emulate it directly, without having to build it again.

## Installing it onto a USB Drive
This is the hard part and is by FAR the most time-consuming. Eventually, this will be pared down to simply creating a new disk partition to boot from, but the way I built the OS uses absolute memory references that, _for now_, require a custom MBR solution.

There are two ways to create a bootable USB drive, one with a GUI tool and one by console. I'll go through both below.

**DO NOT PROCEED WITH EITHER OF THESE UNLESS YOU ARE COMFORTABLE WITH LOSING ALL DATA ON YOUR USB DRIVE!**

### Create a Bootable USB with Rufus
**For this section, you will need** [Rufus for Windows](https://rufus.akeo.ie/)!
1. Plug in your fresh USB drive, ready to go.
2. Open up Rufus (I suggest opening it with Administrative privileges).
3. Name your drive, choose "DD Image". Ensure the allocation size is **16K** and the filesystem is **FAT**. If this isn't the case, you may need to find an older USB drive (_but shh, just try it anyway and let me know if it works (;_ ).
![Name your drive. Use Rufus to add a DD Image.](https://github.com/ZacharyPuhl/OrchidOS_x86/blob/master/res/documentation_imgs/rufus_usb_setup.png "Prepare the installation.")
4. Click the disk icon to open up the explorer window. Navigate to the binary image you compiled earlier.
![Find your OrchidOS binary img file you compiled earlier.](https://github.com/ZacharyPuhl/OrchidOS_x86/blob/master/res/documentation_imgs/rufus_get_img.png "Find your Orchid image you compiled earlier.")
5. Start it up and let 'er rip.
![Click the 'Start' button in Rufus after setting everything up.](https://github.com/ZacharyPuhl/OrchidOS_x86/blob/master/res/documentation_imgs/rufus_done.png "Click the 'Start' button in Rufus after setting everything up.")
6. Check out your new tiny drive!
![Check out your still-usable flash drive.](https://github.com/ZacharyPuhl/OrchidOS_x86/blob/master/res/documentation_imgs/finished_bootable_usb.png "Wow, it's still actually usable and not completely mangled!")

**WHY IS MY DRIVE 128MB NOW WHEN IT'S ACTUALLY MUCH LARGER?**
- Orchid's BIOS Parameter Block for its MBR section claims that its filesystem is only 0x40000 sectors of 512 bytes each in length. This comes out to 128MB of space on the disk, whether there's more or less won't matter.
- This is a **temporary solution** until OrchidOS is self-aware enough to access its own filesystem and overwrite the BPB to something it understands.
- In short, give me a few years to fix this problem! (;

### Creating a Bootable USB with the Command Prompt
This is for the console-only folks out there who are just too cool for school and won't live in the shadow of a worthless GUI!

In this section, I will reference the compiling system and the testing system as the _build_ computer and the _test_ computer, respectively.

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

---

## What If I Want My USB Drive Normal Again???
Right-click it in the Windows explorer and FORMAT it. Simple as that! :)

If you're having issues restoring your drive to a defaulted state (which should never _ever_ be the case), contact me on GitHub and I'll help you out!
