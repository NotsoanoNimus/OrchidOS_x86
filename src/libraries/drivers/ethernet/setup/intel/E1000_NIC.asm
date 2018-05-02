; E1000_NIC.asm
; -- Adapter-specific driver for ethernet control.

struc e1000_rx_desc
    .addr: resq 1
    .length: resw 1
    .checksum: resw 1
    .status: resb 1
    .errors: resb 1
    .special: resw 1
endstruc

struc e1000_tx_desc
    .addr: resq 1
    .length: resw 1
    .cso: resb 1
    .cmd: resb 1
    .status: resb 1
    .css: resb 1
    .special: resw 1
endstruc

E1000_NUM_RX_DESC       equ 32
E1000_NUM_TX_DESC       equ 8

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

E1000_BAR_TYPE          db 0x00             ; Type of BAR
E1000_BASE_IO_ADDR      dw 0x0000           ; I/O Base Address Register
E1000_MMIO_BASE_ADDR    dd 0x00000000       ; MMIO Base Address
E1000_EEPROM_EXISTS     db FALSE            ; Flag for EEPROM

E1000_MAC_ADDRESS       times 6 db 0x00     ; 6-byte space to store MAC address.

E1000_RX_CURRENT        dw 0x0000           ; Current RX Descriptor Buffer.
E1000_TX_CURRENT        dw 0x0000           ; Current TX Descriptor Buffer.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



ETHERNET_INTEL_E1000_NIC_START:

 .leaveCall:
    ret



; Write command to device
;   ARG1 = Chopped WORD = Port Address
;   ARG2 = Value to write (DWORD)
E1000_WRITE_COMMAND:
    push ebp
    mov ebp, esp
    push ebx
    push eax
    push edx

    mov ebx, dword [ebp+8]  ; EBX = MMIO Offset
    and ebx, 0x0000FFFF     ; chop the DWORD to a WORD
    mov eax, dword [ebp+12] ; EAX = value to write

    ; What type of I/O will be performed?
    cmp byte [E1000_BAR_TYPE], 0x00
    jne .IOCOMM
    ;bleed
 .MMIOCOMM:
    mov edx, dword [E1000_MMIO_BASE_ADDR]
    add edx, ebx    ; add the port offset to the base address.
    mov [edx], dword eax   ;write the value to the MMIO register
    jmp .leaveCall

 .IOCOMM:
    movzx edx, strict word [E1000_BASE_IO_ADDR]

    push ebx                ; push address
    push edx                ; port
    call PORT_OUT_DWORD     ; write
    add esp, 8

    add edx, 4      ; Next DWORD I/O address up
    push ebx        ; push address
    push edx        ; port
    call PORT_OUT_DWORD     ; write
    add esp, 8
    ;bleed
 .leaveCall:
    pop edx
    pop eax
    pop ebx
    pop ebp
    ret


; Read from the device.
;   ARG1 = Port Address.
;   EAX = Retrieved data.
E1000_READ_COMMAND:
    push ebp
    mov ebp, esp
    push ebx
    push edx
    xor eax, eax    ; ready the return register.

    mov ebx, dword [ebp+8]  ;arg1 - port address/offset
    and ebx, 0x0000FFFF     ; force lower WORD

    ; What type of I/O will be performed?
    cmp byte [E1000_BAR_TYPE], 0x00
    jne .IOCOMM
    ;bleed
 .MMIOCOMM:
    mov edx, dword [E1000_MMIO_BASE_ADDR]
    add edx, ebx    ; add the offset to the base
    mov eax, dword [edx]   ; store the value
    jmp .leaveCall

 .IOCOMM:
    movzx edx, strict word [E1000_BASE_IO_ADDR]

    push ebx                ; push address
    push edx                ; port
    call PORT_OUT_DWORD     ; write
    add esp, 8

    push edx                ; port
    call PORT_IN_DWORD      ; read. EAX = value
    ;bleed
 .leaveCall:
    pop edx
    pop ebx
    pop ebp
    ret
