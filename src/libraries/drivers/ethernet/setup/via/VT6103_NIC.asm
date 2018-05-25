; VT6103_NIC.asm
; -- Contains driver functions & definitions for the VIA VT6103 FastEthernet PCI device.

VIA_DEVICE_PCI_WORD dw 0xDEAD

VT6103_BAR_TYPE     db 0x00
VT6103_BAR_IO       dw 0x0000   ; word for I/O-type BAR
VT6103_BAR_MMIO     dd 0x00000000 ; dword for MMIO-type BAR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




ETHERNET_VIA_VT6103_NIC_START:
    call VT6103_GET_PCI_PROPERTIES



    mov [0x70100], dword "YEET"
 .leaveCall:
    ret


ETHERNET_VIA_VT6103_NIC_SET_GLOBALS:
    mov dword [ETHERNET_DRIVER_SPECIFIC_SEND_FUNC], VT6103_SEND_PACKET
    mov dword [ETHERNET_DRIVER_SPECIFIC_INTERRUPT_FUNC], VT6103_DRIVER_ISR
 .leaveCall:
    ret



VT6103_GET_PCI_PROPERTIES:  ; EDI = (Device|Vendor), so sub 4 to get PCI address.
    sub edi, 4
    mov eax, dword [edi]    ; EAX = (Bus|Device|Func|rev)
    xor al, al  ; AL = 0, get bar0

    func(PCI_BAR_getAddressesAndType_header00,eax)  ; EAX = BAR#0, BL = TYPE

    or eax, eax ;no BAR found?
    jz .error

    mov byte [VT6103_BAR_TYPE], bl
    or bl, bl
    jz .MMIO
    ; bleed if IO access-type
 .IO:
    mov word [VT6103_BAR_IO], ax
    jmp .leaveCall
 .MMIO:
    mov dword [VT6103_BAR_MMIO], eax
    jmp .leaveCall
 .error:    ; no BAR found...

 .leaveCall:
    ret




; Write command to device
;   ARG1 = Chopped WORD = Port Address
;   ARG2 = Value to write (DWORD)
VT6103_WRITE_COMMAND:
    FunctionSetup
    MultiPush ebx,eax,edx

    mov ebx, dword [ebp+8]  ; EBX = MMIO Offset
    and ebx, 0x0000FFFF     ; chop the DWORD to a WORD
    mov eax, dword [ebp+12] ; EAX = value to write

    ; What type of I/O will be performed?
    cmp byte [VT6103_BAR_TYPE], 0x00
    jne .IOCOMM
    ;bleed
 .MMIOCOMM:
    mov edx, dword [VT6103_BAR_MMIO]
    add edx, ebx    ; add the port offset to the base address.
    mov [edx], dword eax   ;write the value to the MMIO register
    jmp .leaveCall

 .IOCOMM:
    movzx edx, strict word [VT6103_BAR_IO]

    push ebx                ; push address
    push edx                ; port
    call PORT_OUT_DWORD     ; write
    add esp, 8

    add edx, 4      ; Next DWORD I/O address up
    push eax        ; push value
    push edx        ; port
    call PORT_OUT_DWORD     ; write
    add esp, 8
    ;bleed
 .leaveCall:
    MultiPop edx,eax,ebx
    FunctionLeave


; Read from the device.
;   ARG1 = Port Address.
;   EAX = Retrieved data.
VT6103_READ_COMMAND:
    FunctionSetup
    MultiPush ebx,edx
    xor eax, eax    ; ready the return register.

    mov ebx, dword [ebp+8]  ;arg1 - port address/offset
    and ebx, 0x0000FFFF     ; force lower WORD

    ; What type of I/O will be performed?
    cmp byte [VT6103_BAR_TYPE], 0x00
    jne .IOCOMM
    ;bleed
 .MMIOCOMM:
    mov edx, dword [VT6103_BAR_MMIO]
    add edx, ebx    ; add the offset to the base
    mov eax, dword [edx]   ; store the value
    jmp .leaveCall

 .IOCOMM:
    movzx edx, strict word [VT6103_BAR_IO]

    ;push ebx                ; push address
    ;push edx                ; port
    ;call PORT_OUT_WORD     ; write
    ;add esp, 8
    
    push edx                ; port
    call PORT_IN_WORD      ; read. EAX = value
    add esp, 4
    ;bleed
 .leaveCall:
    MultiPop edx,ebx
    FunctionLeave


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

szEthernetIntCalled db "ETHERNET INTERRUPT", 0
VT6103_DRIVER_ISR:
    PrintString szEthernetIntCalled,0x08
 .leaveCall:
    ret


VT6103_SEND_PACKET:
 .leaveCall:
    ret
