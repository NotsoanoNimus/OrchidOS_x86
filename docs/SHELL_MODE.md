# SHELL_MODE Commands, Parser, & Environment

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
### CLS
### COLOR %1
### CONN [%1]
### DUMP
### MEMD %1 %2
