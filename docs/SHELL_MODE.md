# SHELL_MODE Commands, Parser, & Environment
Orchid's SHELL_MODE feature is used as a fall-back on computers that are not compatible with the video mode that the OS requests.
It is loaded by default until the more basic features of the operating system are handled.

## Environment
### Video Mode / Graphics
By default, orchid is set to load into SHELL_MODE, VGA BIOS mode 03h (80*25 text), if it cannot obtain a proper VESA signature, or find a supported video mode.
### Graphical Mode
Orchid <i>tentatively</i> chooses a graphical mode from a selection of standards, mainly seeking support for video mode <strong>0x118</strong>, which is a widely-supported <strong>1024x768</strong> mode, with 24bpp/32bpp support.

## Parser
### Arguments
Arguments are held to a rather strict standard by the kernel. They are stored in memory at PARSER_ARG(N), where N = 1 to 3.
Their lengths are measured as well and stored into PARSER_ARGN_LENGTH for further checks by the called command.

Argument Restrictions:
- No more than 3 arguments are allowed through the parser.
- No more than 64 characters each, including those in double-quotes.
- No more than one space between arguments. This has to do with ASCII processing in the arguments themselves.

Upon error, the parser will let the user know that there was an error, and to check the documentation here.

## Commands
All commands <strong><i>must be entered in lowercase text</i></strong>. Uppercase calls to commands are not supported yet, but can be quickly implemented later.
A quick syntax reference:
- %N implies the N-th argument in the command sequence.
- Arguments are separated by one space.
- Arguments in double-quotes are treated as one argument from quote to quote, regardless of spacing.
- [] around an argument implies that the argument is optional.

### CLS
Clears the console screen.

### COLOR %1
Changes the color of the user's input. Both the foreground and background colors are changeable.
The two digits of the 4-bit colors cannot be the same.

### CONN [%1 %2]
Show an enumerated list of PCI devices. No support for PCIe (but those should be backwards-compatible).
The arguments are an option that is pending approval, to allow detailed information on a specific bus->device. The brackets around both of them imply that one cannot be passed without the other. More info will be provided upon implementation.

### DUMP
Dump the states of all general-purpose registers, stack pointer, segments, and indices.
Mostly a debugging tool, that can be inserted anywhere in the source code (past the kernel) to show register states at a certain time.

### MEMD %1 %2
Perform a hexdump of memory at the specified location, for the specified length.
Arg1 is the physical address to start the hexdump from.
Arg2 is the length of the dump in hex. This is always 16-byte-aligned (meaning rounded to the nearest 0x10).

### SYS
Tell the user information about the system they're running on.
