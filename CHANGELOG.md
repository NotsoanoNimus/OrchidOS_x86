# The Evolution of Orchid OS
This file will serve to document the version history of the Orchid operating system. Some previous versions **before version 0.4** are estimations of the features available at the time, since the version history was never _officially_ tracked numerically until then.

Also, do note that my versioning format is **{major.minor.patch}**, and that my _patch_ additions are mostly subjective and aren't marked by any particular fixes or milestones that will be listed in this document.

**Version 1.0.x will be considered an 'official' release of the OS in its intended initial, functional state.**

---

## Legend
+ **[✔]** - _Completed_: Component/Change is completed, tested, and implemented in the current repository.
+ **[-]** - _In Progress_: Component/Change is currently in the process of being implemented at the time of the last commit.
+ **[X]** - _Pending_: Component/Change is pending work and will be completed as the current version progresses to the next.
+ **[D]** - _Dilapidated_: Component/Change is in need of an overhaul since its last implementation.

---

## [FUTURE/TBD] v0.6.x - What's a Gooey (GUI)
Version 0.6 seems so ambitious to me that it's akin to pop culture in the 1950s thinking we will have flying cars by the new millennium. This stage will represent a **fundamental** change in, not the _concept_ of the OS, but rather its _methods of usage_. This version will reskin _everything_ to a higher resolution and introduce a more stable shell environment.
- [-] A complete transition to a working GUI shell, in VESA mode _0x118_, (_an even more ambitious project_).
  + [-] System monospace font for displaying information to the user (_all type-able characters_).
  + [-] Primitive shapes for windowing and information distinction.
  + [X] Scaling primitive shapes and display environment (_for when new modes are supported_).
- [X] Renovated **KEYBOARD** driver, so multi-press events are supported.
- [X] VFS file manipulations and a working file editing module built in to the SHELL_MODE access.
- [X] Cleaner SCREEN wrappers, screen/command history, and more efficient handling of visual SCREEN functions in a way that supports different modes of operation. This is **required** to have a working `notepad`-like program in the shell for file editing (an ambitious project).

---

## [FUTURE/TBD] v0.5.x - Say Hello to My Little Ping
Version 0.5 is all about reaching out. Orchid will _speak_ to everyone and let them know it's there, and will perhaps have some more basic protocol implementations and commands (such as the elusive, deprecated predecessor to its goal of SFTP: _FTP_).
- [-] A working TCP/IP suite with basic ICMP support over IPv4.
- [X] Commands in SHELL_MODE to configure the network device.
- [X] Stronger encryption functions (RSA, SSL, etc).

---

## [CURRENT] v0.4.x - Ephemeral
Version 0.4 brings with it a **wholly new purpose** to the Orchid platform, and has drastically altered the future aspirations of the project. Some features intended to be implemented between versions 0.4 and 0.5 are:
- [-] The **VFS** (Virtual File System) module, a RAM-only file system that uses an indexed table to find files in the VFS buffer.
- [-] A working, transmitting Ethernet adapter with RX IRQs being handled in the system. No need for protocol wrappers yet.
- [X] Basic cryptographic functions (md5, maybe SHA1).
- [X] Linux compilation/run support, with supporting documentation.
- [-] More basic **video driver** features, cleaner functions, and better-separated source files (_splitting cousin functions into separate header libraries_).

---

## v0.3.x - The Age of Exploration
Version 0.3 was an interesting, yet lackluster, time in the history of the system. Things were slowing _way_ down and I wasn't finding any reason to keep going on the project when there were so many other fun toy systems out there that were all doing the **exact** same thing.

This was mostly a time of experimentation with branches, forks, and possible project directions. For a long time, development had stopped completely. The release 0.3 brought with it these features:
- [✔] Basic memory operations (memcmp, memcpy, etc).
- [✔] Improved SCREEN wrapper functions and a fixed parser that was desperately broken/buggy.
- [✔] Development on USB (UHCI & EHCI) implementations were beginning.
- [✔] Some Video functions and basic, primitive shapes in a widely-supported video mode.
- [✔] Efficiently-automated compilation Batch scripts.

---

## v0.2.x - It's Alive!!!
Things were starting to gain some steam with the system. It was _alive_ and able to show me it could all function together.
- [✔] RTC, PIT, and IDT mostly functional.
- [✔] IRQs, keyboard input, splash screen, and shell are mostly stable.
- [✔] The stage-two bootloader was developed and implemented, where memory and CPU information was gotten in Real-Mode and used in the INIT.asm file thereafter.

---

## v0.1.x - From Humble Beginnings
I have a picture of this laying around somewhere, but back in these days, I was deciding between using a flat-model system and a paged system. It was a very young project and didn't even have a clock on the system. It was just going to have an 'uptime' counter. :)

Introduced:
- [✔] The system concept. Name, initial purpose, intended functions, etc.
- [✔] The custom, independent MBR with no GRUB or El Torito requirements.
- [✔] Protected-Mode transition and other basic requirements of any OS beyond a Bootloader.
