; ETHERNET_definitions.asm
; -- Definitions for all Ethernet drivers. May be delegated to separate folders as more vendors become supported.

ETHERNET_DEVICE_ID  dw 0x0000
ETHERNET_VENDOR_ID  dw 0x0000

ETHERNET_MAC_ADDRESS    times 6 db 0x00

ETHERNET_INITIALIZED db FALSE


; Device & Vendor IDs, checked against the PCI_INFO table.
; -- Supported devices are all listed here.
ETHERNET_INTEL_E1000_DEVICE_ID      equ 0x100E8086
ETHERNET_INTEL_I217_DEVICE_ID       equ 0x153A8086
ETHERNET_INTEL_82577LM_DEVICE_ID    equ 0x10EA8086
