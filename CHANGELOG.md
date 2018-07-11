# The Evolution of Orchid OS
This file will serve to document the version history of the Orchid operating system. Some previous versions **before version 0.4** are estimations of the features available at the time loosely based off of GitHub commits, since the version history was never _officially_ tracked numerically until then.

Also, do note that my versioning format is **{major.minor.patch}**, and that my _patch_ additions are mostly subjective and aren't marked by any particular fixes or milestones that will be listed in this document. The **dates** next to the releases are when that release was officially considered complete. _I am often miles ahead of myself on versioning, so the below log may not be 100% accurate to the actual times that said changes were made._

**Version 1.0.x will be considered an 'official' release of the OS in its intended initial, functional state.** When that release is posted to the repo, the releases afterwards will be posted for each _minor_ patch (notes for which will be listed here).

---

## Legend
+ [X] ✔ - _Completed_: Component/Change is completed, tested, and implemented in the current repository.
+ [X] **(D)** - _Dilapidated_: Component/Change is in need of an overhaul since its last implementation.
+ [ ] - _Pending_: Component/Change is pending work and will be completed as the current version progresses to the next.
+ [ ] **(?)** _Probable Feature_: Component/Change is pending implementation but may be removed from tentative versions.

---

## [FUTURE/TBD] v0.9.x - What's a Gooey (GUI)
Version 0.8 seems so ambitious to me that it's akin to pop culture in the 1950s thinking we will have flying cars by the new millennium. This stage will represent a **fundamental** change in, not the _concept_ of the OS, but rather its _methods of usage_. This version will reskin _everything_ to a higher resolution and attempt to introduce a more stable shell environment.
- [ ] A complete transition to a working GUI shell, in VESA mode _0x118_, (_an even more ambitious project_).
  + [X] ✔ System monospace font for displaying information to the user (_all type-able characters_).
  + [ ] Primitive shapes for windowing and information distinction.
  + [ ] Scaling primitive shapes and display environment (_for when new modes are dynamically supported_).
- [ ] Renovated **KEYBOARD** driver, so multi-press events are supported.
- [ ] VFS file manipulations and a working file editing module built into the kernel (_for potentially both modes, but tentatively GUI_MODE_).
- [ ] Cleaner SCREEN wrappers, screen/command history, and more efficient handling of visual SCREEN functions in a way that supports different modes of operation. This is **required** to have a working `notepad`-like program in the shell for file editing (an ambitious project).

---

## [FUTURE/TBD] v0.8.x - Let it BLOOM
It's time to implement the Orchid BLOOM platform! Compatibility has _hopefully_ been added for more modern systems at this point. Now before the focus lands on the UI, implement the BLOOM platform in all of its glory.
- [ ] Add the BLOOM package manager command to start pre-compiled BLOOM scripts at will.
- [ ] Configure the AUTOEXEC features of the BLOOM architecture to seamlessly integrate with the boot process. _This already has some scaffolding in the source code as of v0.5.x._
- [ ] Tie BLOOM functions into kernel library functions in an API-like way to allow independent developers to easily write their own scripts. This will be a very challenging endeavor, and will likely represent a fundamental change in the OS.

---

## [FUTURE/TBD] v0.7.x - No Trunk, No Branches, NO SERVICE(S)
What's a flower without a stem to feed, support, and control it? The Stem Platform will be responsible for most kernel-level system tasks, such as **memory allocation requests**, **access control**, and **task rotation** (maybe **syscalls** as well).
- [ ] STEMCTL command and system management via the Stem platform in SHELL_MODE.
- [ ] ACPI power profiles and system state management.
- [ ] Process/"Service" management, task delegation, and task management through inter-process communications.
- [ ] Task Manager for kernel task delegation. The _TASKMAN_ module will iterate through the list of system processes in the process table and, based on the kernel-assigned priority, delegate a certain amount of time to each process in the table in a rotating fashion, while simultaneously task-switching and interrupting seamlessly.
- [ ] Creation of I/O streams for the system to utilize dynamically, when needed.

---

## [FUTURE/TBD] v0.6.x - Functions Are Functionally Functional
Compatibility! Version 0.6 is a very functional update that will bring with it a host of compatibility features for newer machines and devices that run on an **x64** architecture, but can emulate **x86** processing (_generally by a feature aptly named 'Legacy Mode'_). Most of these backwards-compatible devices have newer MoBo standards for processing only, such as the APIC, PCIe, and many others. Orchid should support these before tackling greater ambitions.
- [ ] Compatibility with PCI-express-only motherboards, using a dynamic selection on system initialization.
- [ ] ~~GUI folder (_shell_ folder counterpart), that will hold all runtime-environment programs used by GUI_MODE.~~ Desktop folder now holds GUI_MODE files and related setup routines.
- [ ] CMOS RTC driver implementation for better time control on systems that may not have a PIT.
- [ ] **(?)** I/O APIC dynamic support.
- [ ] If possible: video mode & resolution detection.
- [ ] Rework the command parser in SHELL_MODE to take more arguments of a longer length each, or to better parse/iterate the user's command, possibly using the ISTREAM object later.

---

## [FUTURE/TBD] v0.5.x - Say Hello to My Little Ping
Version 0.5 is all about reaching out. Orchid will _speak_ to everyone and let them know it's there, and will perhaps have some more basic protocol implementations and commands (such as the elusive, deprecated predecessor to its goal of SFTP: _FTP_).
- [ ] A working TCP/IP suite with basic ICMP support over IPv4.
- [ ] Commands in SHELL_MODE to configure the network device.
- [ ] **(?)** Stronger encryption functions (RSA, SSL, etc).
- [ ] Working FTP transfers.

---

## [CURRENT] v0.4.x - Ephemeral
Version 0.4 brings with it a **wholly new purpose** to the Orchid platform, and has drastically altered the future aspirations of the project. Some features intended to be implemented between versions 0.4 and 0.5 are:
- [X] ✔ Documentation for the repurposing of the system, from BLOOM to the Ephemeral concept.
- [X] ✔ The **VFS** (Virtual File System) module, a RAM-only file system that uses an indexed table to find files in the VFS buffer. _The more detailed 'write' functions of the VFS will not be written until the editor command/module is finished._
- [ ] A working, transmitting Ethernet adapter with RX IRQs being handled in the system. No need for protocol wrappers yet.
- [ ] Basic cryptographic functions (md5, maybe SHA1; just hashes for now).
- [X] ✔ Linux compilation/run support, with supporting documentation.
- [X] ✔ Bloom module documentation clarification.
- [X] ✔ More basic **video driver** features, cleaner functions, and better-separated source files --_see next point_-- (_splitting cousin functions into separate header libraries_).
- [X] ✔ Introduce **new macros** to clean up repetitive code, and split mega-files into smaller component files by an intelligent analysis of compatible sister functions/methods. Make incredible strides toward source readability & manageability so that any browsers of the repo can follow.
- [X] ✔ Shutdown & Reboot commands will zero out important parts of memory that are written to by the user. The list of places to be overwritten will be constantly evolving.

---

## [May 6, 2018] v0.3.x - The Age of Exploration
Version 0.3 was an interesting, yet lackluster, time in the history of the system. Things were slowing _way_ down and I wasn't finding any reason to keep going on the project when there were so many other fun toy systems out there that were all doing the **exact** same thing.

This was mostly a time of experimentation with branches, forks, and possible project directions. For a long time, development had stopped completely. The release 0.3 brought with it these features:
- [X] ✔ Basic memory operations (memcmp, memcpy, etc).
- [X] ✔ Improved SCREEN wrapper functions and a fixed parser that was desperately broken/buggy.
- [X] ✔ Development on USB (UHCI & EHCI) implementations were beginning.
- [X] ✔ Some Video functions and basic, primitive shapes in a widely-supported video mode.
- [X] ✔ Efficiently-automated compilation Batch scripts.
- [X] **(D)** Added the Heap functions to control process memory access.

---

## [September 14, 2017] v0.2.x - It's Alive!!!
Things were starting to gain some steam with the system. It was _alive_ and able to show me it could all function together.
- [X] **(D)** RTC, PIT, and IDT mostly functional.
- [X] ✔ Basic ACPI implementation.
- [X] ✔ IRQs, keyboard input, splash screen, and shell are mostly stable.
- [X] ✔ The stage-two bootloader was developed and implemented, where memory and CPU information was gotten in Real-Mode and used in the `INIT.asm` file thereafter.

---

## [July 22, 2017] v0.1.x - From Humble Beginnings
I have a picture of this laying around somewhere, but back in these days, I was deciding between using a flat-model system and a paged system. It was a very young project and didn't even have a clock on the system. It was just going to have an 'uptime' counter. :)

Introduced:
- [X] ✔ The system concept. Name, initial purpose, intended functions, etc.
- [X] ✔ The custom, independent Master Boot Record, with no GRUB or El Torito requirements (_no external dependencies_).
- [X] ✔ Protected-Mode transition and other basic requirements of any OS beyond a Bootloader.
