; UHCI.asm
; -- Implement support functions for the UHCI specification.

UHCI_PCI_CONTROLLER_CLASS_ID        equ 0x0C
UHCI_PCI_CONTROLLER_SUBCLASS_ID     equ 0x03
UHCI_PCI_CONTROLLER_INTERFACE_ID    equ 0x00
; The UHCI IO port is contained in BAR4 (offset 20h).
UHCI_PCI_CONFIG_BAR4                equ 0x20
; Since there are 8 max supported USB devices of one type,
;  the driver needs to account for the fact that there may be 8 controllers.
UHCI_BARIO_1    dd 0x00000000
UHCI_BARIO_2    dd 0x00000000
UHCI_BARIO_3    dd 0x00000000
UHCI_BARIO_4    dd 0x00000000
UHCI_BARIO_5    dd 0x00000000
UHCI_BARIO_6    dd 0x00000000
UHCI_BARIO_7    dd 0x00000000
UHCI_BARIO_8    dd 0x00000000


USB_INTERNAL_findMatchingUHCI:
    pushad

    xor eax, eax
    mov al, UHCI_PCI_CONTROLLER_CLASS_ID
    shl eax, 8
    mov al, UHCI_PCI_CONTROLLER_SUBCLASS_ID
    shl eax, 8
    mov al, UHCI_PCI_CONTROLLER_INTERFACE_ID
    shl eax, 8
    ; Leave al = 0 (Revision does not matter right now).

    push dword eax
    call PCI_returnMatchingDevices  ; Get matching UHCI devices on the PCI bus.
    add esp, 4

    popad
    ret


USB_INTERNAL_iterateUHCIBARs:
    pushad
    mov esi, PCI_MATCHED_DEVICE1
    mov edi, UHCI_BARIO_1           ; start at MD1 & BAR1
    xor ecx, ecx   ;set counter to 0
 .iterateBAR:
    xor eax, eax    ; returns for readConfigWord
    xor ebx, ebx    ; register access
    xor edx, edx    ; holds BAR
    cmp dword [esi], 0x00000000
    je .leaveCall  ; this line is the origin of a known possible bug. See top of this file.
    mov dword ebx, [esi]    ; ebx = (Bus<<24|Device<<16|Function<<8|00h)
    mov bl, UHCI_PCI_CONFIG_BAR4    ; get IO-port addr

    or bl, PCI_GET_HIGH_WORD   ; get the high WORD.
    push dword ebx
    call PCI_configReadWord
    add esp, 4
    mov word dx, ax
    shl edx, 16     ; store high word of BAR4 into high word of EDX.

    xor bl, PCI_GET_HIGH_WORD  ; toggle PCI_GET_HIGH_WORD off.
    push dword ebx
    call PCI_configReadWord
    add esp, 4
    mov word dx, ax  ;now get the low word.

    ; EDX = [BAR4] of PCI_MATCHED_DEVICE[n]
    mov dword [edi], edx

    add edi, 4      ; next BARIO address.
    add esi, 4      ; next MATCHED_DEVICE
    inc cl
    cmp byte cl, 8  ; were 8 devices filled? If so, leave before overflow!
    je .leaveCall
    jmp .iterateBAR

 .leaveCall:
    popad
    ret
