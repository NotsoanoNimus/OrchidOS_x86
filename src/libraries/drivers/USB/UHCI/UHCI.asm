; UHCI.asm
; -- Implement support functions for the UHCI specification.

UHCI_PCI_CONTROLLER_CLASS_ID        equ 0x0C
UHCI_PCI_CONTROLLER_SUBCLASS_ID     equ 0x03
UHCI_PCI_CONTROLLER_INTERFACE_ID    equ 0x00
; The UHCI IO port is contained in BAR4 (offset 20h).
UHCI_PCI_CONFIG_BAR4                equ 0x20

; Since there are 8 max supported USB devices of one type,
;  the driver needs to account for the fact that there may be 8 controllers.
UHCI_BARIO_1    dw 0x0000
UHCI_BARIO_2    dw 0x0000
UHCI_BARIO_3    dw 0x0000
UHCI_BARIO_4    dw 0x0000
UHCI_BARIO_5    dw 0x0000
UHCI_BARIO_6    dw 0x0000
UHCI_BARIO_7    dw 0x0000
UHCI_BARIO_8    dw 0x0000
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
UHCI_USBCMD     equ 00h
UHCI_USBSTS     equ 02h
UHCI_USBINTR    equ 04h
UHCI_FRNUM      equ 06h
UHCI_FRBASE     equ 08h
UHCI_SOFMOD     equ 0Ch
UHCI_PORTSC1    equ 10h
UHCI_PORTSC2    equ 12h


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;DEBUGGING FUNCTIONS. To be deleted later when code is 100% bulletproof.

;debugging variable.
szUSBDeviceConn db "XXXXXXXX", 0
; INPUTS:
;   ARG1: Which port? Accepts BARIO 1-8.
;   ARG2: Offset into port. UHCI_USBCMD to UHCI_PORTSC2.
;   ARG3: 0x00 = word // 0x01 = dword
; OUTPUTS:
;   * Print value received from port to the screen.
; -- Debugging function to output a read-back on a port.
USB_UHCI_DEBUG_outputPortVariable:
    pushad
    mov ebp, esp

    xor eax, eax
    xor edx, edx
    xor ecx, ecx
    xor ebx, ebx
    mov strict word dx, [ebp+36]        ;arg1 - word
    mov strict byte cl, [ebp+38]        ;arg2 - byte
    mov strict byte bl, [ebp+39]        ;arg3 - byte
    add dx, cx      ; combine offset with base.
    cmp bl, 0x01
    je .dword_in
    in ax, dx       ; read into ax
    jmp .printout
 .dword_in:
    in eax, dx      ; read into eax
 .printout:
    mov esi, szUSBDeviceConn+8
    call UTILITY_DWORD_HEXtoASCII
    mov esi, szUSBDeviceConn
    mov bl, 0x06
    call _screenWrite

    ; clean buffer.
    mov cl, 8   ; 8 bytes in szUSBDeviceConn
    xor eax, eax
    mov al, '0'
    mov edi, szUSBDeviceConn
    rep stosb

    popad
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;POLLING/BOOLEAN/MISC FUNCTIONS.


; INPUTS:
;   ARG1: I/O Base Address
; OUTPUTS:
;   EAX: bit 0 --> Set = True (device is connected)
; -- Polls the PORTSC# I/O ports to see if there is a device connected.
USB_UHCI_isDeviceConnected:
    push ebp
    mov ebp, esp
    push edx
    xor eax, eax

    mov strict word dx, [ebp+8]      ;arg1
    and edx, 0x0000FFFF
    push edx
    add edx, UHCI_PORTSC1
    in ax, dx

    mov esi, szUSBDeviceConn+8
    call UTILITY_DWORD_HEXtoASCII
    mov bl, 0x06
    mov esi, szUSBDeviceConn
    call _screenWrite

    pop edx
    xor eax, eax
    add edx, UHCI_PORTSC2
    in ax, dx

    mov esi, szUSBDeviceConn+8
    call UTILITY_DWORD_HEXtoASCII
    mov bl, 0x06
    mov esi, szUSBDeviceConn
    call _screenWrite

 .leaveCall:
    pop edx
    pop ebp
    ret



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;READ/WRITE/STATUS FUNCTIONS.





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SETUP FUNCTIONS.

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

    push dword ebx
    call PCI_configReadWord
    add esp, 4
    mov word dx, ax  ;now get the low word.

    ; EDX = [BAR4] of PCI_MATCHED_DEVICE[n]
    ; [BAR4] (I/O) format = bits 31-2 = 4-byte-aligned base addr, bits 1-0 = 01b
    ;  `---> so the BAR needs to be &0xFFFFFFFC to get the true base address.
    and dx, 0xFFFC
    mov word [edi], dx

    add edi, 2
    add esi, 4      ; next MATCHED_DEVICE
    inc cl
    cmp byte cl, 8  ; were 8 devices filled? If so, leave before overflow!
    je .leaveCall
    jmp .iterateBAR

 .leaveCall:
    popad
    ret
