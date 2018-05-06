# BLOOM, a proprietary byte-code scripting subsystem
Orchid needs a way to pre-compile, load, and run user-made programs while still maintaining its _Ephemeral OS_ qualities.

One simple way to do such a thing is to make user programs/applications **part of** the kernel itself, effectively an installation to the kernel.

When the kernel boots, it loads the Orchid subsystem, including all required devices, networking information, and other system requirements for basic operation. Afterwards, the system enters **blooming** mode, where it unpacks the pre-compiled byte-code on the tail-end of the kernel and loads it into memory.

Think of what happens in **blooming** mode as the equivalent of the **AUTOEXEC.bat** process in the days of MSDOS systems. You write byte-code with **FULL CONTROL** of your system and it runs on startup for you.

The system is said to have **bloomed** when the process is complete.

## How to make a BLOOM script
