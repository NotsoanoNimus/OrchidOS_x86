; DRIVERS.asm
; --- Include file for all the basic drivers.

%include "libraries/drivers/vfs/VFS.asm"

%include "libraries/drivers/VIDEO/VIDEO.asm"

%include "libraries/drivers/USB/USB.asm"
%include "libraries/drivers/keyboard/KEYBOARD.asm"

%include "libraries/drivers/timer/PIT.asm"

%include "libraries/drivers/ACPI/ACPI.asm"

%include "libraries/drivers/PCI/PCI.asm"

; ETHERNET & NETWORK STACK
%include "libraries/network/NETWORK_STACK.asm"
%include "libraries/drivers/ethernet/ETHERNET.asm"
