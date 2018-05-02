; ETHERNET_SETUP.asm
; -- Setup and Init functions for the onboard Ethernet device.
; ---- May be split into multiple directories/files later
;      depending on the amount of vendors that become supported.

%include "libraries/drivers/ethernet/setup/intel/E1000_NIC.asm"

; Called by the primary Ethernet driver to delegate setup responsibility to this component file.
; -- Reads device ID stored from PCI_INFO earlier.
; -- If no matching ethernet device was found, will exit and continue system initialization.
ETHERNET_SETUP_begin:
    xor ecx,ecx
    xor eax,eax

    mov edi, PCI_INFO
    add edi, 4          ; Set EDI at the first PCI entry's (DevID<<16|VenID) DWORD.
    mov cl, byte [PCI_INFO_NUM_ENTRIES] ; CL = counter

 .searchForEthernetDevice:
    mov eax, dword [edi]
    ; Here will be a list of all supported ethernet Vendor ID's & Device ID's to match against.
    ; The first and only one for the moment will be supported by QEMU.

    cmp eax, 0x100E8086     ;Intel E1000 NIC Gigabit Ethernet Controller (QEMU).
    je .Intel_100E

    ; Decrement counter, check if there are still more devices to iterate.
    add edi, 20     ; Each PCI entry is 20 bytes long (5 DWORDs).
    dec cl
    or cl, cl
    jnz .searchForEthernetDevice
    jmp .leaveCall

 .Intel_100E:
    call ETHERNET_INTEL_E1000_initialize
    jmp .leaveCall

 .leaveCall:
    ret


; Device ID: 0x100E
; Vendor ID: 0x8086
szETHERNETIntel_E1000_found db "Found Intel E1000-Class Gigabit Ethernet Controller.", 0
ETHERNET_INTEL_E1000_initialize:
    call ETHERNET_INTEL_E1000_NIC_START
 .leaveCall:
    mov byte [ETHERNET_INITIALIZED], TRUE
    PrintString szETHERNETIntel_E1000_found,0x0A
    ret
