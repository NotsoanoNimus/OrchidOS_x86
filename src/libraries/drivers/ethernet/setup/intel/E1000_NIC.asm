; E1000_NIC.asm
; -- Adapter-specific driver for ethernet control.
; ---- A huge THANK YOU to the OSDev community on this file for helping me to learn basic Ethernet I/O!
; ---- Much of the definitions and source here are my own translations from some given C code on the OSDev Wiki.
; ---- We're all gonna make it.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DEFINITIONS

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

E1000_REG_CTRL          equ 0x0000
E1000_REG_STATUS        equ 0x0008
E1000_REG_EEPROM        equ 0x0014
E1000_REG_CTRL_EXT      equ 0x0018
E1000_REG_IMASK         equ 0x00D0
E1000_REG_RCTRL         equ 0x0100
E1000_REG_RXDESCLO      equ 0x2800
E1000_REG_RXDESCHI      equ 0x2804
E1000_REG_RXDESCLEN     equ 0x2808
E1000_REG_RXDESCHEAD    equ 0x2810
E1000_REG_RXDESCTAIL    equ 0x2818

E1000_REG_TCTRL         equ 0x0400
E1000_REG_TXDESCLO      equ 0x3800
E1000_REG_TXDESCHI      equ 0x3804
E1000_REG_TXDESCLEN     equ 0x3808
E1000_REG_TXDESCHEAD    equ 0x3810
E1000_REG_TXDESCTAIL    equ 0x3818

E1000_REG_RDTR          equ 0x2820 ; RX Delay Timer Register
E1000_REG_RXDCTL        equ 0x3828 ; RX Descriptor Control
E1000_REG_RADV          equ 0x282C ; RX Int. Absolute Delay Timer
E1000_REG_RSRPD         equ 0x2C00 ; RX Small Packet Detect Interrupt

E1000_REG_TIPG          equ 0x0410 ; Transmit Inter Packet Gap
E1000_ECTRL_SLU         equ 0x40 ; Set link up

E1000_RCTL_EN               equ (1 << 1)    ; Receiver Enable
E1000_RCTL_SBP              equ (1 << 2)    ; Store Bad Packets
E1000_RCTL_UPE              equ (1 << 3)    ; Unicast Promiscuous Enabled
E1000_RCTL_MPE              equ (1 << 4)    ; Multicast Promiscuous Enabled
E1000_RCTL_LPE              equ (1 << 5)    ; Long Packet Reception Enable
E1000_RCTL_LBM_NONE         equ (0 << 6)    ; No Loopback
E1000_RCTL_LBM_PHY          equ (3 << 6)    ; PHY or external SerDesc loopback
E1000_RTCL_RDMTS_HALF       equ (0 << 8)    ; Free Buffer Threshold is 1/2 of RDLEN
E1000_RTCL_RDMTS_QUARTER    equ (1 << 8)    ; Free Buffer Threshold is 1/4 of RDLEN
E1000_RTCL_RDMTS_EIGHTH     equ (2 << 8)    ; Free Buffer Threshold is 1/8 of RDLEN
E1000_RCTL_MO_36            equ (0 << 12)   ; Multicast Offset - bits 47:36
E1000_RCTL_MO_35            equ (1 << 12)   ; Multicast Offset - bits 46:35
E1000_RCTL_MO_34            equ (2 << 12)   ; Multicast Offset - bits 45:34
E1000_RCTL_MO_32            equ (3 << 12)   ; Multicast Offset - bits 43:32
E1000_RCTL_BAM              equ (1 << 15)   ; Broadcast Accept Mode
E1000_RCTL_VFE              equ (1 << 18)   ; VLAN Filter Enable
E1000_RCTL_CFIEN            equ (1 << 19)   ; Canonical Form Indicator Enable
E1000_RCTL_CFI              equ (1 << 20)   ; Canonical Form Indicator Bit Value
E1000_RCTL_DPF              equ (1 << 22)   ; Discard Pause Frames
E1000_RCTL_PMCF             equ (1 << 23)   ; Pass MAC Control Frames
E1000_RCTL_SECRC            equ (1 << 26)   ; Strip Ethernet CRC

; Buffer Sizes
E1000_RCTL_BSIZE_256        equ (3 << 16)
E1000_RCTL_BSIZE_512        equ (2 << 16)
E1000_RCTL_BSIZE_1024       equ (1 << 16)
E1000_RCTL_BSIZE_2048       equ (0 << 16)
E1000_RCTL_BSIZE_4096       equ ((3 << 16) | (1 << 25))
E1000_RCTL_BSIZE_8192       equ ((2 << 16) | (1 << 25))
E1000_RCTL_BSIZE_16384      equ ((1 << 16) | (1 << 25))

; Transmit Command
E1000_CMD_EOP           equ (1 << 0)    ; End of Packet
E1000_CMD_IFCS          equ (1 << 1)    ; Insert FCS
E1000_CMD_IC            equ (1 << 2)    ; Insert Checksum
E1000_CMD_RS            equ (1 << 3)    ; Report Status
E1000_CMD_RPS           equ (1 << 4)    ; Report Packet Sent
E1000_CMD_VLE           equ (1 << 6)    ; VLAN Packet Enable
E1000_CMD_IDE           equ (1 << 7)    ; Interrupt Delay Enable

; TCTL Register
E1000_TCTL_EN           equ (1 << 1)    ; Transmit Enable
E1000_TCTL_PSP          equ (1 << 3)    ; Pad Short Packets
E1000_TCTL_CT_SHIFT     equ 4           ; Collision Threshold
E1000_TCTL_COLD_SHIFT   equ 12          ; Collision Distance
E1000_TCTL_SWXOFF       equ (1 << 22)   ; Software XOFF Transmission
E1000_TCTL_RTLC         equ (1 << 24)   ; Re-transmit on Late Collision

E1000_TSTA_DD           equ (1 << 0)    ; Descriptor Done
E1000_TSTA_EC           equ (1 << 1)    ; Excess Collisions
E1000_TSTA_LC           equ (1 << 2)    ; Late Collision
E1000_LSTA_TU           equ (1 << 3)    ; Transmit Underrun

E1000_BAR_TYPE          db 0x00             ; Type of BAR (0 = MMIO, not 0 = I/O)
E1000_BASE_IO_ADDR      dw 0x0000           ; I/O Base Address Register
E1000_MMIO_BASE_ADDR    dd 0x00000000       ; MMIO Base Address
E1000_EEPROM_EXISTS     db FALSE            ; Flag for EEPROM

E1000_MAC_ADDRESS       times 6 db 0x00     ; 6-byte space to store MAC address.

E1000_RX_CURRENT        dw 0x0000           ; Current RX Descriptor Buffer.
E1000_TX_CURRENT        dw 0x0000           ; Current TX Descriptor Buffer.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



ETHERNET_INTEL_E1000_NIC_START:
    call E1000_GET_PCI_PROPERTIES   ; fill in the BAR type, Base IO port, and/or MMIO base addr.
    call E1000_DETECT_EEPROM        ; detect whether or not the device has an EEPROM.
    call E1000_GET_MAC_ADDRESS      ; get the MAC address of the ethernet device.
 .leaveCall:
    ret


; Every supported adapter will have an after-setup call that sets global Ethernet properties
;  such as the MAC address, IRQ, and more.
ETHERNET_INTEL_E1000_NIC_SET_GLOBALS:
    MEMCPY E1000_MAC_ADDRESS,ETHERNET_MAC_ADDRESS,0x06
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


; Get the PCI bus properties of the NIC and fill out the corresponding variables.
E1000_GET_PCI_PROPERTIES:
    ; EDI should still be pointing at the VendorID/DeviceID field in PCI_INFO, so subtract 4 bytes
    ;  to get the physical location of the Ethernet device on the PCI bus.
    sub edi, 4
    mov eax, dword [edi]    ; EAX = (Bus<<24|Slot/Device<<16|Func<<8|rev)
    xor al, al              ; Set low byte to zero (get BAR0).

    push eax
    call PCI_BAR_getAddressesAndType_header00
    add esp, 4

    or eax, eax     ; Is EAX 0?
    je .unsupportedMode

    ; Store and check the access type of the BAR.
    mov byte [E1000_BAR_TYPE], bl
    or bl, bl
    jz .MMIO
    ;bleed if I/O access-type
 .IO:
    mov word [E1000_BASE_IO_ADDR], ax
    jmp .leaveCall
 .MMIO:
    mov dword [E1000_MMIO_BASE_ADDR], eax
    jmp .leaveCall
 .unsupportedMode:
 .leaveCall:
    ret



szFoundEEPROM db "E1000 EEPROM found. Initializing driver...", 0
; Set E1000_EEPROM_EXISTS if the EEPROM is found.
E1000_DETECT_EEPROM:
    pushad

    push 0x00000001
    push E1000_REG_EEPROM
    call E1000_WRITE_COMMAND    ; write 0x1 to the EEPROM port.
    add esp, 8

    mov ecx, 0x00000400     ; 1024 iterations (to consume some time and allow a response)
 .repSearch:
    push E1000_REG_EEPROM
    call E1000_READ_COMMAND     ; Read the EEPROM port.
    add esp, 4

    and eax, 0x00000010
    cmp eax, 0x00000010
    je .foundEEPROM
    loop .repSearch
    ;bleed
 .noEEPROM:
    jmp .leaveCall

 .foundEEPROM:
    PrintString szFoundEEPROM,0x0D
    mov strict byte [E1000_EEPROM_EXISTS], TRUE
 .leaveCall:
    popad
    ret


; INPUTS:
;   ARG1 = BYTE of address offset into ROM to read.
; OUTPUTS:
;   EAX = WORD response.
; Read from the EEPROM or EEPROM_REGISTER
E1000_READ_EEPROM:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx

    ; zero registers
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx

    mov edx, dword [ebp+8]  ; EDX = arg1
    and edx, 0x0000FFFF     ; Force DX only.

    mov bl, byte [E1000_EEPROM_EXISTS]
    cmp bl, TRUE
    jne .no_eeprom
    ;bleed if eeprom exists
 .eeprom_exists:
    shl edx, 8
    or edx, 0x00000001
    push edx
    push E1000_REG_EEPROM
    call E1000_WRITE_COMMAND    ; write [(1)|(EDX<<8)] to the EEPROM register
    add esp, 8
    ; while(!((EAX = readCommand(REG_EEPROM)) & (1<<4)))
   .eeprom_exists_wait_read:
    xor ebx, ebx
    push E1000_REG_EEPROM
    call E1000_READ_COMMAND     ; read the EEPROM into EAX
    add esp, 4
    mov ebx, eax    ; copy read into EBX to use for local operations
    and ebx, 0x00000010
    or ebx, ebx
    jz .eeprom_exists_wait_read
    jmp .leaveCall

 .no_eeprom:
    shl edx, 2
    or edx, 0x00000001
    push edx
    push E1000_REG_EEPROM
    call E1000_WRITE_COMMAND    ; write [(1)|(EDX<<2)] to the EEPROM register
    add esp, 8
    ; while(!((EAX = readCommand(REG_EEPROM)) & (1<<1)))
   .no_eeprom_wait_read:
    xor ebx, ebx
    push E1000_REG_EEPROM
    call E1000_READ_COMMAND     ; read the EEPROM into EAX
    add esp, 4
    mov ebx, eax    ; copy read into EBX to use for local operations
    and ebx, 0x00000001
    or ebx, ebx
    jz .no_eeprom_wait_read
    jmp .leaveCall

 .leaveCall:
    shr eax, 16
    and eax, 0x0000FFFF

    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret


; INPUTS: NONE
; OUTPUTS: NONE
; Gets the MAC address of the ethernet device and places it into the E1000_MAC_ADDRESS field.
E1000_GET_MAC_ADDRESS:
    push edi
    push ebx
    push ecx
    mov edi, E1000_MAC_ADDRESS

    mov bl, byte [E1000_EEPROM_EXISTS]
    cmp bl, TRUE
    jne .no_eeprom
    ;bleed if EEPROM exists
 .eeprom_exists:
    push 0x0
    call E1000_READ_EEPROM
    add esp, 4
    call .subRoutine

    push 0x1
    call E1000_READ_EEPROM
    add esp, 4
    call .subRoutine

    push 0x2
    call E1000_READ_EEPROM
    add esp, 4
    call .subRoutine

    jmp .leaveCall
 .subRoutine:
    stosb
    shr eax, 8
    stosb
    ret

 .no_eeprom:
    xor ebx, ebx
    xor ecx, ecx
    mov ebx, dword [E1000_MMIO_BASE_ADDR]
    add ebx, 0x5400 ; add 5400h to the MMIO base to find the start of the MAC address.

    cmp strict byte [ebx], 0    ; value @ EBX = 0?
    je .noMAC

    mov cl, 0x03    ;6-byte MAC (3 WORDs)
   .getMAC_no_eeprom:   ; should probably use ESI for this instead and just MOVSW
    mov ax, strict word [ebx]   ;AX =  get WORD @ address in EBX
    stosw   ; store into EDI, EDI+=2
    add ebx, 2  ;Increment EBX
    loop .getMAC_no_eeprom

    jmp .leaveCall

 .noMAC: ; called when the no_eeprom fallback can't find a MAC. MAC will = 0f.0f.0f.0f.0f.0f
    mov al, 0x0F
    mov cl, 0x06
    rep stosb
    ;bleed
 .leaveCall:
    pop ecx
    pop ebx
    pop edi
    ret


; Enable RX on the device.
E1000_RX_ENABLE:

 .leaveCall:
    ret
