# BLOOM, a proprietary byte-code scripting subsystem
Orchid needs a way to pre-compile, load, and run user-made programs while still maintaining its _Ephemeral OS_ qualities.

One simple way to do such a thing is to make user programs/applications **part of** the kernel itself, effectively an installation to the kernel. Another way would be to directly interface with the kernel via a built-in API (which is _kind of_ how modern applications run).

When the kernel boots, it loads the Orchid subsystem, including all required devices, networking information, and other system requirements for basic operation. Afterwards, the system enters **blooming** mode, where it unpacks the pre-compiled byte-code on the tail-end of the kernel and loads it into memory.

User-space restrictions on application access is possible, since the kernel will eventually feature an easy way for developers to interface with it. This can go either way: BLOOM becomes a **Ring-3 platform** and uses syscalls, or BLOOM becomes a fully-integrated platform wherein the user just references the kernel functions by label.

The latter option will be a much steeper learning curve for any developers, but with the right documentation it wouldn't be a bad idea. Since the system isn't paged, a Ring-3 access control may not even have much of a _security_ effect at all.

Think of what happens in **blooming** mode as the equivalent of the **AUTOEXEC.bat** process in the days of MSDOS systems. You write byte-code with **FULL CONTROL** of your system and it runs on startup for you.

The system is said to have **bloomed** when the process is complete.

## How to make a BLOOM script
BLOOM files are made with a very, _very_ simple structure in mind.

The first two DWORDs (8 bytes) of a BLOOM program's raw binary translation represent:
1. The _size of the file_, which orchid will be **certain** to verify and enforce with a terminating signature at load-time. There will be a strict maximum size limit once this module is developed more.
2. The flags of the file. I will provide a more detailed analysis on this subject when I better know what flags to sense in the BLOOM kernel module.

Everything after the first two DWORDs is raw assembled binary that Orchid will point the EIP (instruction) register to when it's ready to begin the **blooming** process.

More will be provided on this as I develop the module. Firstly, I need to add useful commands to automate, and SFTP connectivity. It will be some time.

## More plans with BLOOM
I want **blooming** to involve more than a startup-script. I want users to write their own custom modules, and even potentially share them with each other.

Here's a list of things I want to add to the BLOOM module as it develops:
- Startup installation of custom user modules that can safely plug into the kernel (think primitive Linux package manager). These could be run with a command like `BLOOM [package-name] [options]`.
- Automation of commands and features that the OS already provides to the user, such as net connectivity and device setup (DHCP and such).
