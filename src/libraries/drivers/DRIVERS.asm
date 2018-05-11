; DRIVERS.asm
; --- Include file for all the basic drivers.

; PCI Bus configuration & access for other devices.
%include "libraries/drivers/PCI/PCI.asm"

; Programmable Interval Timer driver.
%include "libraries/drivers/timer/PIT.asm"

; External device generic drivers.
%include "libraries/drivers/USB/USB.asm"
%include "libraries/drivers/keyboard/KEYBOARD.asm"

; ACPI generic power driver.
%include "libraries/drivers/ACPI/ACPI.asm"

; Virtual File System interface driver.
%include "libraries/drivers/vfs/VFS.asm"

; GUI_MODE Video Driver.
%include "libraries/drivers/VIDEO/VIDEO.asm"

; Ethernet & connectivity.
%include "libraries/drivers/ethernet/ETHERNET.asm"
