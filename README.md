# OrchidOS_x86
A 32-bit, flat-model, single-user, single-tasking operating system targeting legacy BIOS systems.
Programmed entirely in Intel-x86 Assembly using _NASM_ (compiler) and _Atom_ (IDE), with no external libraries used (yet).

See the /docs/ folder for more specific information about each command, the parser, memory maps, etc.

---

## How do I run it?
#### Build Dependencies
- [QEMU Emulator](https://qemu.weilnetz.de/w64/) for Windows.
- [NASM v2.14+](http://www.nasm.us/pub/nasm/releasebuilds/2.14rc0/), under the Windows directories.
- [DD for Windows](http://www.chrysocome.net/dd).

**NOTE**: The NASM, QEMU, and DD directories need to be added onto the Windows PATH environment variable. If you don't do this, the compiler won't be happy! :O

#### After Installing the Dependencies
It's as easy as compiling it with the `/src/__compile32.bat` file. If it throws errors, try running it with Administrator privileges. The compiler script itself offers a way to emulate the system with QEMU.

To use the image **without having to compile it again**, run the `/src/__run32.bat` file for an instantly-running emulation of the operating system! In fact, I keep this one as a shortcut on my desktop for quick access to show friends and family alike! :)

For those who would like to help test and debug the OS on **real hardware**, head on over to [this document](https://github.com/ZacharyPuhl/OrchidOS_x86/blob/master/docs/BUILD_AND_RUN.md) to learn how you can run it!

---

## TO-DO
- ~~Optimize old commands by centralizing some utility functions.~~
- Finish exception-handling and basic IDT hooks.
- USB 1.0 support (UHCI & OHCI).
- USB 2.0 support (EHCI).
- Read USB mass-storage devices (since that's orchid's intended boot device).
- ~~Clean up the deprecated, inefficient screen wrapper functions (one of the first files drafted at this project's inception).~~



## Capabilities
- Read PCI devices and initialize them.
- Parse commands and arguments in _SHELL_MODE_ (see /docs/SHELL_MODE.md for more).
- VGA basic display driver (graphical, non-text modes), for drawing primitive shapes. Supports both 24bpp and 32bpp dynamically.
- Heap initialization and memory management in a flat environment. Supports a max of 4GB RAM.



## Future Plans (distant, in no particular order)
- File system based on FAT16, or some customized variant of it.
- ELF binary support.
- Basic system calls and I/O piping.
- Network stack.
- [_Maybe/Undecided_] Multitasking using PIT IRQ0. Implement TSS ops and inter-process COMM channels as well.
- [_Maybe/Undecided_] Interactive, layered GUI with a Windows-style Desktop Window Manager (which will manage layers).
- Implement system processes in separate ELF binaries, such as the DWM, GUI control, driver control.
- [_Maybe/Undecided_] Eventually shrink the orchidOS kernel to just a simple memory manager and syscall handler.

#### Successfully-Tested Systems/Processors
- VIA Esther C7 800MHz processor
- Generic Intel Celeron/Pentium
- QEMU/Bochs Emulator

---

## Why Reinvent the Wheel? (Anecdotal Commentary)
Most people would consider the concept of designing an operating system from the ground-up a masochistic venture at best.
Personally, I believe it's a journey that's not about the end-product, but more about the experience being so close to the system's hardware gets you.

I have never felt a greater sense of accomplishment than successfully building the next version of an orchid kernel, and having a new feature work smoothly. It's enthralling to work at my own independent shell -- every. single. time.

In the same vein, a failed compilation becomes one more surmountable hurdle, and experience in my tool-belt for later recollection.

I hope someone enjoys this operating system as much as I enjoy creating it!

Thanks for reading!
