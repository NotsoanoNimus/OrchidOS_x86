# BLOOM, a proprietary byte-code scripting subsystem
Orchid needs a way to pre-compile, load, and run user-made programs while still maintaining its _Ephemeral OS_ qualities.

One simple way to do such a thing is to make user programs/applications **part of** the kernel itself, effectively an installation to the kernel.

When the kernel boots, it loads the Orchid subsystem, including all required devices, networking information, and other system requirements for basic operation. Afterwards, the system enters **blooming** mode, where it unpacks the pre-compiled byte-code on the tail-end of the kernel and loads it into memory.

Think of what happens in **blooming** mode as the equivalent of the **AUTOEXEC.bat** process in the days of MSDOS systems. You write byte-code with **FULL CONTROL** of your system and it runs on startup for you.

The system is said to have **bloomed** when the process is complete.

## How to make a BLOOM script
BLOOM files are made with a very, _very_ simple structure in mind.

The first two DWORDs (8 bytes) of a BLOOM program's raw binary translation represent:
1. The _size of the file_, which orchid will be **certain** to verify and enforce with a terminating signature at load-time. There will be a strict maximum size limit once this module is developed more.
2. The flags of the file. I will provide a more detailed analysis on this subject when I better know what flags to sense in the BLOOM kernel module.

Everything after the first two DWORDs is raw assembled binary that Orchid will point the EIP to when it's ready to begin the **blooming** process.

More will be provided on this as I develop the module. Firstly, I need to add useful commands to automate, and SFTP connectivity. It will be some time.

## More plans with BLOOM
I want **blooming** to involve more than a startup-script. I want users to write their own custom modules, and even potentially share them with each other.

Here's a list of things I want to add to the BLOOM module as it develops:
- Startup installation of custom user modules that can safely plug into the kernel (think primitive Linux package manager). These could be run with a command like `BLOOM [package-name] [options]`.
- Automation of commands and features that the OS already provides to the user, such as net connectivity and device setup (DHCP and such).
