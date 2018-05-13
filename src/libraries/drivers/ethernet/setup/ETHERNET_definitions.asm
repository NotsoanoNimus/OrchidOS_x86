; ETHERNET_definitions.asm
; -- Definitions for all Ethernet drivers. May be delegated to separate folders as more vendors become supported.

ETHERNET_DEVICE_ID  dw 0x0000
ETHERNET_VENDOR_ID  dw 0x0000

ETHERNET_MAC_ADDRESS    times 6 db 0x00

ETHERNET_PROCESS_ID     db 0x00
ETHERNET_PROCESS_BASE   dd 0x00000000

ETHERNET_REQUIRED_RAM   equ 0x00080000

; Buffer for transmitting packets.
; -- First var is the offset into the Ethernet Controller process RAM to find the Packet buffer.
ETHERNET_PACKET_SEND_BUFFER_OFFSET  equ 0x00070000  ; offset into the Ethernet process
ETHERNET_PACKET_SEND_MAX_SIZE       equ 0x00010000  ; maximum allocation for one packet.
ETHERNET_PACKET_SEND_BUFFER_BASE     dd 0x00000000  ; actual pointer to address of 0x10000-byte send buffer.

; RX & TX buffers in the Heap. Desc buffers are tables that describe the packet access for the data buffer pieces.
ETHERNET_RX_DESC_BUFFER_BASE     dd 0x00000000
ETHERNET_RX_DATA_BUFFER_BASE     dd 0x00000000
ETHERNET_TX_DESC_BUFFER_BASE     dd 0x00000000
ETHERNET_TX_DATA_BUFFER_BASE     dd 0x00000000

ETHERNET_INITIALIZED db FALSE
ETHERNET_PROCESS_FAILURE db FALSE


; Holds the address of a label to an ethernet device-specific interrupt service routine.
ETHERNET_DRIVER_SPECIFIC_INTERRUPT_FUNC dd 0x00000000

; Hold a function pointer for wrapping/sending/transmitting data over the Ethernet adapter.
ETHERNET_DRIVER_SPECIFIC_SEND_FUNC dd 0x00000000


; Device & Vendor IDs, checked against the PCI_INFO table.
; -- Supported devices are all listed here.
ETHERNET_INTEL_E1000_DEVICE_ID      equ 0x100E8086
ETHERNET_INTEL_I217_DEVICE_ID       equ 0x153A8086
ETHERNET_INTEL_82577LM_DEVICE_ID    equ 0x10EA8086
