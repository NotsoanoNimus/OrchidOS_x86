# OrchidOS_x86
A 32-bit, flat-model, single-user operating system targeting legacy BIOS systems.
Programmed entirely in Intel-x86 Assembly using <i>NASM</i> (compiler) and <i>Atom</i> (IDE), with no external libraries used (yet).

See the /docs/ folder for more specific information about each command, the parser, memory maps, etc.


## TO-DO
- <strike>Optimize old commands by centralizing some utility functions.</strike>
- Finish exception-handling and basic IDT hooks.
- USB 1.0 support (<strike>UHCI</strike> & OHCI).
- USB 2.0 support (EHCI).
- Read USB mass-storage devices (since that's typically orchid's boot device).
- Clean up the deprecated, inefficient screen wrapper functions (one of the first files drafted at this project's inception).


## How To Run
Take the binary image and force it over the MBR of a removable media, such as a flash drive or external HDD. Write the whole image to LBA 0 of the disk.
<strong>BE CAREFUL</strong>: Replacing the MBR of a disk can cause a loss of personal data. Do not use a disk you have data stored on!!!

If you're using an emulator, check out the compiler Batch file in the /src/ directory to view the compatible QEMU emulator settings.

<i><u>NOTE</u></i>: Orchid cannot run on CDs, and has not been tested on floppy disks. Try at your own peril. Also, <u>orchid is not UEFI-compatible in any way</u>, so always run the legacy BIOS setting.


## Capabilities
- Read PCI devices and initialize them.
- Parse commands and arguments in SHELL_MODE (see /docs/SHELL_MODE.md for more).
- VGA basic display driver (graphical, non-text modes), for drawing primitive shapes. Supports both 24bpp and 32bpp dynamically.
- Heap initialization and memory management in a flat environment. Supports a max of 4GB RAM.


## Future Plans (distant, in no particular order)
- File system based on FAT16, or some customized variant of it.
- ELF binary support.
- Basic system calls and I/O piping.
- Network stack.
- Multitasking using PIT IRQ0. Maybe/Undecided. Implement TSS ops and inter-process COMM channels as well.
- Interactive, layered GUI with a Windows-style Desktop Window Manager (which will manage layers).
- Implement system processes in separate ELF binaries, such as the DWM, GUI control, driver control.
- Eventually shrink the orchidOS kernel to just a simple memory manager and syscall handler. (?)


#### Successfully-Tested Systems/Processors
- VIA Esther C7 800MHz processor
- Generic Intel Celeron/Pentium


## Why Reinvent the Wheel? (Anecdotal Commentary)
Most people would consider the concept of designing an operating system from the ground-up a masochistic venture at best.
Personally, I believe it's a journey that's not about the end-product, but more about the experience being so close to the system's hardware gets you.

I have never felt a greater sense of accomplishment than successfully building the next version of an orchid kernel, and having a new feature work smoothly. It's enthralling to work at my own independent shell -- every. single. time.

In the same vein, a failed compilation becomes one more surmountable hurdle, and experience in my tool-belt for later recollection.

I hope someone enjoys this operating system as much as I enjoy creating it!

Thanks for reading!
