; ETHERNET_definitions.asm
; -- Definitions for all Ethernet drivers. May be delegated to separate folders as more vendors become supported.

ETHERNET_DEVICE_ID  dw 0x0000
ETHERNET_VENDOR_ID  dw 0x0000

ETHERNET_MAC_ADDRESS    times 6 db 0x00

ETHERNET_PROCESS_ID     db 0x00
ETHERNET_PROCESS_BASE   dd 0x00000000

ETHERNET_REQUIRED_RAM   equ 0x00010000

; RX & TX buffers in the Heap.
ETHERNET_RX_BUFFER_BASE     dd 0x00000000
ETHERNET_TX_BUFFER_BASE     dd 0x00000000

ETHERNET_INITIALIZED db FALSE
ETHERNET_PROCESS_FAILURE db FALSE


; Device & Vendor IDs, checked against the PCI_INFO table.
; -- Supported devices are all listed here.
ETHERNET_INTEL_E1000_DEVICE_ID      equ 0x100E8086
ETHERNET_INTEL_I217_DEVICE_ID       equ 0x153A8086
ETHERNET_INTEL_82577LM_DEVICE_ID    equ 0x10EA8086
