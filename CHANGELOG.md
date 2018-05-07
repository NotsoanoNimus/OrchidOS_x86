# The Evolution of Orchid OS
This file will serve to document the version history of the Orchid operating system. Some previous versions **before version 0.4** are estimations of the features available at the time, since the version history was never _officially_ tracked numerically until then.

Also, do note that my versioning format is **{major.minor.patch}**, and that my _patch_ additions are mostly subjective and aren't marked by any particular fixes or milestones that will be listed in this document.

---

## [FUTURE/TBD] v0.5.x - Say Hello to My Little Ping
Version 0.5 tentatively implements these features, assuming the previous version is successful:
- A working TCP/IP suite with basic ICMP support over IPv4.
- File manipulations and a working file editing module built in to the shell.
- Cleaner SCREEN wrappers, screen/command history, and more efficient handling of visual SCREEN functions in a way that supports different modes of operation. This is **required** to have a working `notepad`-like program in the shell for file editing (an ambitious project).

---

## v0.4.x - Ephemeral
Version 0.4 brings with it a **wholly new purpose** to the Orchid platform, and has drastically altered the future aspirations of the project. Some features intended to be implemented between versions 0.4 and 0.5 are:
- The VFS (Virtual File System) module, a RAM-only file system that uses an indexed table to find files in the VFS buffer.
- A working, transmitting Ethernet adapter with RX IRQs being handled in the system. No need for protocol wrappers yet.
- Basic cryptographic functions.
- Linux compilation/run support, with supporting documentation.

---

## v0.3.x - The Age of Exploration
Version 0.3 was an interesting, yet lackluster, time in the history of the system. Things were slowing _way_ down and I wasn't finding any reason to keep going on the project when there were so many other fun toy systems out there that were all doing the **exact** same thing.

This was mostly a time of experimentation with branches, forks, and possible project directions. For a long time, development had stopped completely. The release 0.3 brought with it these features:
- Basic memory operations (memcmp, memcpy, etc).
- Improved SCREEN wrapper functions and a fixed parser that was desperately broken/buggy.
- Development on USB (UHCI & EHCI) implementations were beginning.
- Some Video functions and basic, primitive shapes in a widely-supported video mode.
- Efficiently-automated compilation Batch scripts.

---

## v0.2.x - It's Alive!!!
Things were starting to gain some steam with the system. It was _alive_ and able to show me it could all function together.
- RTC, PIT, and IDT mostly functional.
- IRQs, keyboard input, splash screen, and shell are mostly stable.
- The stage-two bootloader was developed and implemented, where memory and CPU information was gotten in Real-Mode and used in the INIT.asm file thereafter.

---

## v0.1.x - From Humble Beginnings
I have a picture of this laying around somewhere, but back in these days, I was deciding between using a flat-model system and a paged system. It was a very young project and didn't even have a clock on the system. It was just going to have an 'uptime' counter. :)

Introduced:
- The system concept. Name, initial purpose, intended functions, etc.
- The custom, independent MBR with no GRUB or El Torito requirements.
- Protected-Mode transition and other basic requirements of any OS beyond a Bootloader.
