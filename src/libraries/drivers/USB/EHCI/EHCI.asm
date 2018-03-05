; EHCI.asm
; -- Implement support functions for the EHCI specification.

EHCI_PCI_CONTROLLER_CLASS_ID        equ 0x0C
EHCI_PCI_CONTROLLER_SUBCLASS_ID     equ 0x03
EHCI_PCI_CONTROLLER_INTERFACE_ID    equ 0x20
; The EHCI BARIOs are found on the PCI bus, --BAR0-- of the device's location.

; Since there are 8 max supported USB devices of one type,
;  the driver needs to account for the fact that there may be 8 controllers.
EHCI_BARIO_ARRAY:   ; use this accessor for queries to a drive/controller id. Ex: BARIO_N = [EHCI_BARIO_ARRAY+((N-1)*4)]
EHCI_BARIO_1 equ 0x00070500 ;using 70500 as a base address to check memory-mapped i/o address with MEMD in real time.
;EHCI_BARIO_1    dd 0x00000000
;EHCI_BARIO_2    dd 0x00000000
;EHCI_BARIO_3    dd 0x00000000
;EHCI_BARIO_4    dd 0x00000000
;EHCI_BARIO_5    dd 0x00000000
;EHCI_BARIO_6    dd 0x00000000
;EHCI_BARIO_7    dd 0x00000000
;EHCI_BARIO_8    dd 0x00000000
; Each BAR I/O address is a BASE address (hence "BaseAR") for a configuration I/O port.
; Universal HCI follows this standard for its I/O Config Port Accesses:
;  [BASE+00h->WORD] : USBCMD, USB Command
;  [BASE+02h->WORD] : USBSTS, USB Status
;  [BASE+04h->WORD] : USBINTR, USB Interrupt-Enable
;  [BASE+06h->WORD] : FRNUM, USB Frame Number
;  [BASE+08h->DWORD]: FRBASE, USB Frame Base Address
;  [BASE+0Ch->DWORD]: SOFMOD, Start of Frame Modification
;  [BASE+10h->WORD] : PORTSC1, Port 1 Status/Control
;  [BASE+12h->WORD] : PORTSC2, Port 2 Status/Control
EHCI_REG_CAPLENGTH      db 0x00
ECHI_REG_HCIVERSION     equ 0x02    ;word
EHCI_REG_HCSPARAMS      equ 0x04    ;DWORD
EHCI_REG_HCCPARAMS      equ 0x08    ;DWORD
EHCI_REG_HCSP_PORTROUTE equ 0x0C    ;QWORD




; Find devices on the PCI bus(es) that match the device specification of an EHCI.
USB_INTERNAL_findMatchingEHCI:
    push eax

    xor eax, eax
    mov al, EHCI_PCI_CONTROLLER_CLASS_ID
    shl eax, 8
    mov al, EHCI_PCI_CONTROLLER_SUBCLASS_ID
    shl eax, 8
    mov al, EHCI_PCI_CONTROLLER_INTERFACE_ID
    shl eax, 8
    ; Leave al = 0 (Revision does not matter right now).

    push dword eax  ;EAX = (0x0C0320xx)
    call PCI_returnMatchingDevices  ; Get matching UHCI devices on the PCI bus.
    add esp, 4

    pop eax
    ret


; Set up the BARIO variables that will contain each EHCI USB controller's I/O port bases.
USB_INTERNAL_iterateEHCIBARs:
    pushad
    mov esi, PCI_MATCHED_DEVICE1
    mov edi, EHCI_BARIO_1   ; start at MATCHED_DEVICE1 & BARIO1
    xor ecx, ecx   ;set counter to 0
 .iterateBAR:
    xor eax, eax    ; returns for readConfigWord
    xor ebx, ebx    ; register access
    xor edx, edx    ; holds BAR
    cmp dword [esi], 0x00000000     ; check for empty PCI_MATCHED_DEVICE
    je .leaveCall  ; this line is the origin of a known possible bug. See top of this file.

    ; FOR EHCI, BAR0 in the PCI config space is written as such:
    ; [BAR0] (I/O) format...
    ;   31-8 = base address. 7-3 = Reserved (0). 2-1 = (10b):May be mapped to 64-bit/(00b):32. 0 = Reserved (0).
    mov dword ebx, [esi]    ; ebx = (Bus<<24|Device<<16|Function<<8|00h) <------------,
    mov bl, PCI_BAR0    ; get IO-port addr, EHCI has it at BAR0 of its PCI bus addr -'
    push dword ebx
    call PCI_configReadWord ;Reading offset (10h)
    pop dword ebx
    mov word dx, ax  ;store the low word
    shl edx, 16     ; store PCI config BAR0 31-16 in the high bits of EDX.
    add bl, 2
    push dword ebx
    call PCI_configReadWord ;Reading offset (12h)
    add esp, 4

    ; The BAR DWORD results needs to be &0xFFFFFF00 to get the true base I/O address.
    and edx, 0xFFFFFF00     ;Saving only bits 31 to 8
    mov dword [edi], edx    ; Store result in the EHCI_BARIO var

    add edi, 4      ; next BARIO.
    add esi, 4      ; next MATCHED_DEVICE
    inc cl
    cmp byte cl, 8  ; were 8 devices filled? If so, leave before overflow!
    je .leaveCall
    jmp .iterateBAR

 .leaveCall:
    popad
    ret
