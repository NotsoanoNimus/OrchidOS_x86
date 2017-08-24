# OrchidOS_x86
A 32-bit, flat-model, single-user operating system targeting legacy BIOS systems.
Programmed entirely in Intel-x86 Assembly using <i>NASM</i> (compiler) and <i>Atom</i> (IDE), with no external libraries used (yet).

See the /docs/ folder for more specific information about each command, the parser, memory maps, etc.

## TO-DO
- <strike>Optimize old commands by centralizing some utility functions.</strike>
- Add USB driver to read mass-storage devices.
- File system based on FAT16, or some customized variant of it.
- ELF binary support.
- Basic system calls and I/O piping.

## Capabilities
- Read PCI devices and initialize them.
- Parse commands and arguments in SHELL_MODE (see /docs/commands/ for more).
- VGA basic display driver (graphical, non-text modes), for drawing primitive shapes. Supports both 24bpp and 32bpp dynamically.
- Heap initialization and memory management in a flat environment. Supports a max of 4GB RAM.

## Future Plans (distant, in no particular order)
- Network stack.
- Multitasking using PIT IRQ0. Implement TSS ops and inter-process COMM channels as well.
- Interactive, layered GUI with a Windows-style Desktop Window Manager (which will manage layers).
- Implement system processes in separate ELF binaries, such as the DWM, GUI control, driver control.
- Eventually shrink the orchidOS kernel to just a simple memory manager and syscall handler. (?)

#### Successfully-Tested Systems/Processors
- VIA Esther C7 800MHz processor
- Generic Intel Celeron/Pentium
