# Tentative Memory Map for Orchid_x86
This document will serve as an index into target systems' physical memory layouts, for interested parties. It exists primarily to list taken spaces in memory, gaps and possible holes in memory, for future allocations and deallocations.

This document will also function secondarily as a description of Orchid's tentative structure, including the heap setup and the kernel memory manager. Some information about the Kernel can be found here for now, until the SYSCALL documentation is written.

If you would like more information about System Calls regarding allocations and deallocations of heap space, please reference the SYSCALL.md document, and find the section "Memory Management" inside.

*Please remember that Orchid is a flat-model system, and does not use paging whatsoever.*


## Map
- *00000000 to 000004FF: BDA (BIOS data area). Reserved.*
- 00000500 to 000006FF: MEM_INFO --> Map of system memory & system memory holes; retrieved from BIOS at boot.
- 00000700 to 000007FF: CPU_INFO --> CPU information, such as the vendor string and processing power. May deprecate.
- 00000800 to 00000BFF: VGA_INFO --> Information about the VGA and supported video modes.
- 00000C00 to 00000DFF: VESA_INFO --> Information about VESA and the requested mode (typically 0x118).
- 00000E00 to 00000EFF: ACPI_RSDP/RSDT & ACPI_INFO --> Pointers to ACPI information tables.
- **00000F00 to 00000FFB**: FREE.
- 00000FFC to 00000FFF: _BOOT_ERROR_FLAGS_. Important flags that tell the system which devices/protocols failed on start.
- 00001000 to 000013FF: Extended Boot Sector, also referenced in src as ST2 (2 sectors).
- 00001400 to 000014FF: SHELL_MODE user input buffer for command parsing.
- 00001500 to 000015FF: SHELL_MODE shadow buffer, used to retrieve the last command used.
- **00001600 to 00007BFF**: FREE.
- 00007C00 to 00007DFF: OS Boot Sector. Can be overwritten after booting.
- **00007E00 to 00010000**: FREE.
- 00010000 to 0006FFF0: **SYSTEM KERNEL.**
- 0006FFF0 to 0006FFFF: HEAP_INFO. Stored information about the heap status and health. See the MEMOPS.asm: HEAP_INFO section for more.
- 00070000 to 00070FFF: Running Process Information (strings for filenames, PIDs, permissions, etc).
- 00071000 to 000713FF: PCI Bus Devices
- **00071400 to 0007FFFF**: FREE.
- 00080000 to 00090000: Kernel Stack. Might be split later into userspace stack and kernel stack.
- **00090000 to 0009FDFF**: FREE.
- *0009FC00 to 0009FFFF: Extended BDA. Reserved.*
- *000A0000 to 000FFFFF: Video/VGA memory & ROM area. Reserved.*
- 00100000 to FFFFFFFF: Memory Heap / Free for Allocation. Replace FFFFFFFF with max available RAM on target system.


### About That Kernel...
#### What do you plan on doing with it?

Nothing too fancy. The kernel is intended to be a gateway to the system hardware via the syscall, as they usually are. I don't think I want a monolithic (though that's its current rendition), but something more along the lines of a micro-hybrid, if that's sensible. I want there to be an entire shell built into the system that the user can use if their VGA card fails an initialization.

If it passes into video-mode, then I want the kernel to setup a USB & IDE (pretty much a VFS) environment solely for the purpose of retrieving files and loading them. I want those files to be individual system processes that control things like the display buffers, device drivers, and system security.

#### What about higher-half systems? This violates a convention/must of systems development!

As you know, the kernel has likely hundreds of internal flags that guarantee its smooth operation, error-checking processes, and safety. It can be relocated eventually with a changed load location and origin, but its origin in the source file must always be fixed.

Not to mention that my obsession with the system being on the lower half is also influenced by setting up a loading environment for other interactive programs I'll be writing to the disk and loading into the heap environment.

Plus, I like the heap and kernel where they are (until the kernel grows too large and must relocate)!


## Heap
The dynamic memory heap starts at **1 MiB** of physical memory, with a starting size of **16 MiB**.

It has no maximum size (at the moment) and can expand until the end of available memory, which is retrieved by the early system initialization.

When allocation occurs, memory is aligned to **256-byte "parcels"**. The entire allocation accounts for the size of the program's header and footer, and will expand to another 256-byte parcel if necessary. There is only one header at the beginning of a block, and one footer at its end, for every allocated space. No memory in a single running process is fragmented; it will always be contiguous.

**NOTE**: *A feature which has yet to be implemented is an initial check of the heap that searches for reserved holes, referenced in the MEM_INFO section of memory (PA 0x500). There shouldn't be many, but they are possible on some systems. The heap will later search for these, and upon finding them, mark them as 'dirty' blocks that have already been allocated.*

#### Elements of the Heap
1. **Header**
    - DWORD: Starts the header every time (0xBEABEA57). Mnemonic is "BE A BEAST" for this signature.
    - DWORD: Lists the size of the block, from header-to-footer.
    - DWORD: Technically only a byte, this space is reserved for future flags. When the LSBit is set, it means the block is 'dirty' and therefore not free to allocate or merge.
2. **Footer**
    - DWORD: Footer signature. Always 0xDEADBEEF. May change later.
    - DWORD: Pointer to block's header.
3. **Dynamic Allocation**
    - Fragmentation: the heap is capable of dynamically freeing blocks and merging them into large holes to be used later.
    - First-Come: any free blocks with space enough for a new allocation will be fragmented
