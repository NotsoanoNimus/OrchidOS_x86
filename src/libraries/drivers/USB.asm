; USB.asm
; -- Implements support for UHCI, OHCI, and EHCI. USB3 (XHCI) is not necessary for x86.

UHCI_PCI_CONTROLLER_CLASS_ID        equ 0x0C
UHCI_PCI_CONTROLLER_SUBCLASS_ID     equ 0x03
UHCI_PCI_CONTROLLER_INTERFACE_ID    equ 0x00
