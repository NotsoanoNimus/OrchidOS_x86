# OrchidOS_x86 - A Maybe-New Concept
A 32-bit, flat-model, single-user, single-tasking operating system, intended to run in legacy 32-bit operating modes.
Programmed entirely in Intel-x86 Assembly using _NASM_ (compiler) and _Atom_ (IDE), with no external libraries used (~~yet~~ **ever**).

Orchid is a _concept_ operating system, that I'd like to call an **Ephemeral OS**.

See the /docs/ folder for more specific information about each command, the parser, memory maps, etc.

---

## What's an "Ephemeral OS"?
_TL;DR is below_, but I'd recommend reading everything when you can find time to understand my motivations. :)

Orchid was originally built on hopes and dreams of creating a full-fledged _UNIX±Windows_ system that featured odd mixes of both platforms. However, I realized the absolutely astounding amount of (both toy and feature-rich) operating systems that already exist around this concept, and many other unique concepts.

Call it _laziness_ or _ingenuity_, but I've strayed from my initial aspirations of making an alternative system for the average user, and have since become infatuated with the concept of **no storage**. _Everything is temporary._

That's right, **no saved configurations** (only pre-compiled ones), **no saved files**, and **no trace of usage**. Even though it wasn't the initial purpose of the project, the name still fits: orchids are _notoriously delicate_.

As of right now, all you need to get started is a display, a compatible Ethernet adapter, some RAM, a BIOS, and a keyboard.

### What's the purpose??
Well, I'm not ruling out _external storage_, but only _local storage_.

Orchid will eventually use its own file-system virtualization in a portion of its RAM (_the same way it uses a heap for memory management of tasks_), where users can write data and create things. Perhaps eventually it will enable scripts to run automated tasks.

One might ask how creating a script will help whatsoever if it will just be lost to the VOID after a reboot, and I would let them know that I plan to **implement SFTP for offsite file storage and retrieval** through the addition of the network stack.

### But I don't want to download my files every time!
I thought about this. What if you could _compile_ your config into Orchid?

For example, say I create an Orchid script parser (as a universal kernel module) that will take pre-compiled files, load them into memory, and run them at startup? The files would be coded in some proprietary language and written by me, then included in my compilation.

Now when my PC starts Orchid, it asks for a static IP address, a gateway, a DNS server, and a remote/local SFTP host (with username & password). My pre-compiled script will tell it which parts/components of the OS to download and load into RAM, so I can _run them via their references_.

I want this "pre-compile" option to be available to all parties. **It's basically AUTOEXEC.bat compiled into your local copy of OrchidOS_x86!**

### And security?
Security was an initial concern I had from the start with making an operating system. How could one person with limited experience ever implement something like Kerberos?!

Well, with an **Ephemeral OS**, I don't have to worry about passwords, and neither do you. Your FTP server will handle that!

Scared that some rogue hacker will pop onto your system with Orchid on a USB stick?
1. You should be afraid that they have physical access at all. **Security starts with YOU.**
2. Orchid _can't even access file systems_. It has no idea what the heck an IDE controller is (only that it exists), and it has no concept of USB mass storage, though it began to trend that way.
3. All your data from the last operation of your system is _already gone_ when it turns back on.

### TL;DR / In summation...
**Every user will have full control of their systems, no traces of usage (if shutdown properly), no overhead in performing intensive tasks, and secure+remote storage for their information. All scripts, automations, and remote filesystem/SFTP properties will be customizable at compile-time for maximum static access to your information.**

---

---

## How do I run it?
#### Build Dependencies
- [QEMU Emulator](https://qemu.weilnetz.de/).
- [NASM v2.14+](http://www.nasm.us/pub/nasm/releasebuilds/2.14rc0/).
- [DD for Windows](http://www.chrysocome.net/dd). **If you're running Windows.**

**NOTE for Windows users**: The NASM, QEMU, and DD directories need to be added onto the Windows PATH environment variable. If you don't do this, the compiler won't be happy! :O

#### After Installing the Build Dependencies
It's as easy as compiling it with the `/src/__compile32` file, extension depending on your operating system. If it throws errors, try running it with Administrative/root privileges (or changing file permissions). The compiler scripts offer ways to emulate the system with QEMU after compilation.

To use the image **without having to compile it again**, run the `/src/__run32` file for an instantly-running emulation of the operating system that you most recently compiled. In fact, I keep this one as a useful shortcut on my desktop for quick access to show friends and family alike! :)

For those who would like to help test and debug the OS on **real hardware**, head on over to [this document](https://github.com/ZacharyPuhl/OrchidOS_x86/blob/master/docs/BUILD_AND_RUN.md) to learn how you can run it on your own machine!

---

## TO-DO
- Build up the network stack to include simple adapters and protocols for mainly-private usage (meaning HTTP/S is **NOT** intended as an included protocol at this time).
- Add some basic crypto functions for data hashing, and to use later with the Network Stack.
- Finish exception-handling and basic IDT hooks.
- ~~USB 1.0 support (UHCI & OHCI).~~ (not interesting right now)
- ~~USB 2.0 support (EHCI).~~ (not interesting right now)
- Clean up the God-forsaken parser that still can't handle its input appropriately. :(



## Capabilities
- Read PCI devices and initialize them.
- Parse commands and arguments in _SHELL_MODE_ (see /docs/SHELL_MODE.md for more).
- VGA basic display driver (graphical, non-text modes), for drawing primitive shapes. Supports both 24bpp and 32bpp dynamically.
- Heap initialization and memory management in a flat environment. Supports a max of 4GB RAM.

---

## Future Plans (distant, in no particular order)
- Security implementations for certificates (SSL/SFTP/RSA/etc).
- Abstracted file system in RAM, using a handling system to reference chunks of data (similar to directories and filenames, of course).
- Basic system calls and I/O piping. This is still on the table.
- ~~Multitasking using PIT IRQ0. Implement TSS ops and inter-process COMM channels as well.~~ Probably won't happen, since the OS is such a low-overhead endeavor that there is no noticeable difference between a 500MHz processor and a 3.8GHz one. :)
- ~~Interactive, layered GUI with a Windows-style Desktop Window Manager (which will manage layers).~~ What was I thinking? _SHELL_MODE is love, SHELL_MODE is life_. I may include a basic GUI, though.
- ~~Implement system processes in separate ELF binaries, such as the DWM, GUI control, driver control.~~ Ahahahahahaha, _"ELF"_. At most, I will be placing system 'processes' in different places of the Heap with a handle to reference their activities...
- ~~Eventually shrink the orchidOS kernel to just a simple memory manager and syscall handler.~~ The kernel **IS** the system, now and forever!

---

#### Successfully-Tested Systems/Processors
- VIA Esther C7 800MHz processor
- Generic Intel Celeron/Pentium
- QEMU/Bochs Emulator
- AMD Ryzen 5 2400G (in legacy mode, obviously)
