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
endstruc    ; sizeof = 16 bytes

; sizeof = 16 bytes
struc e1000_tx_desc
    .addr: resq 1
    .length: resw 1
    .cso: resb 1
    .cmd: resb 1
    .status: resb 1
    .css: resb 1
    .special: resw 1
endstruc

E1000_RX_CURSOR db 0x00
E1000_TX_CURSOR db 0x00
E1000_TX_CURSOR_OLD db 0x00

E1000_NUM_RX_DESC       equ 32
E1000_NUM_TX_DESC       equ 8
E1000_RX_DESC_SIZE      equ 16
E1000_TX_DESC_SIZE      equ 16

E1000_RX_FRAME_ALLOC_SIZE   equ 8192

E1000_RX_DESC_NEEDED_RAM    equ (E1000_NUM_RX_DESC*E1000_RX_DESC_SIZE)
E1000_TX_DESC_NEEDED_RAM    equ (E1000_NUM_TX_DESC*E1000_TX_DESC_SIZE)

E1000_REG_CTRL          equ 0x0000
E1000_REG_STATUS        equ 0x0008
E1000_REG_EEPROM        equ 0x0014
E1000_REG_CTRL_EXT      equ 0x0018
E1000_REG_IMASK         equ 0x00D0

E1000_REG_RCTRL         equ 0x0100
E1000_REG_RXDESCLO      equ 0x2800 ; RX Desc Base Addr Low DWORD (lower DWORD of the 64-bit RXdesc buffer base)
E1000_REG_RXDESCHI      equ 0x2804 ; RX Desc Base Addr High DWORD (upper DWORD of a 64-bit address, so 0)
E1000_REG_RXDESCLEN     equ 0x2808 ; Sets bytes alloc for descs in the circ RX desc buffer (must be 128B-aligned)
E1000_REG_RXDESCHEAD    equ 0x2810 ; RX desc buffer Head Ptr. (31:16 - Reserved, 15:0 - RX Desc Head)
E1000_REG_RXDESCTAIL    equ 0x2818 ; RX desc buffer Tail Ptr. (31:16 - Reserved, 15:0 - RX Desc Tail)

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
    call E1000_SET_LINK_UP
    call E1000_CLEAR_MULTICAST_TABLE
    call E1000_IRQ_ENABLE           ; Enable the Hardware IRQ for RX.
    call E1000_RX_ENABLE            ; Enable the RX device function.
    call E1000_TX_ENABLE            ; Enable the TX device function.
 .leaveCall:
    ret


; Every supported adapter will have an after-setup call that sets global Ethernet properties
;  such as the MAC address, IRQ, and more.
ETHERNET_INTEL_E1000_NIC_SET_GLOBALS:
    MEMCPY E1000_MAC_ADDRESS,ETHERNET_MAC_ADDRESS,0x06
    mov dword [ETHERNET_DRIVER_SPECIFIC_SEND_FUNC], E1000_SEND_PACKET
    mov dword [ETHERNET_DRIVER_SPECIFIC_INTERRUPT_FUNC], E1000_DRIVER_ISR
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
    add esp, 4
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

    push dword 0x00000001
    push dword E1000_REG_EEPROM
    call E1000_WRITE_COMMAND    ; write 0x1 to the EEPROM port.
    add esp, 8

    mov ecx, 0x00000400     ; 1024 iterations (to consume some time and allow a response)
 .repSearch:
    push dword E1000_REG_EEPROM
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



; Enable the E1000 hardware IRQ.
E1000_IRQ_ENABLE:
    push dword 0x0001F6DC
    push dword E1000_REG_IMASK
    call E1000_WRITE_COMMAND
    add esp, 8

    ;push dword (0x000000FF & ~4)
    ;push dword E1000_REG_IMASK
    ;call E1000_WRITE_COMMAND
    ;add esp, 8

    push dword 0x000000C0
    call E1000_READ_COMMAND
    add esp, 4
 .leaveCall:
    ret



; Called as a device-specific ISR for IRQ handling.
E1000_DRIVER_ISR:
    pushad

    PrintString szETHERNET_PROCESS_NAME,0x0F ;TEST CODE
 .leaveCall:
    popad
    ret



; Enable RX on the device.
; Sets up buffer descriptors that point to memory spaces of 8192 bytes each within the Ethernet Controller process...
E1000_RX_ENABLE:
    pushad

    ; zero out RX buffer descriptor space.
    xor eax, eax    ; EAX = 0
    xor ecx, ecx    ; ECX = 0
    mov ecx, E1000_RX_DESC_NEEDED_RAM   ; Number of bytes in RX descriptor table (32 table x 16 bytes each)
    mov edi, dword [ETHERNET_RX_DESC_BUFFER_BASE]   ;EDI = RX buffer base ptr
    push edi
    rep stosb
    pop edi     ; EDI = RX buffer base

    ; Referenced in ETHERNET_SETUP.asm, RX & TX Desc tables are 0x800 each, so 0x1000 offset is where RX buffers start.
    ; The RX Data buffer size is listed below (0x40000!)
    add edi, 0x1000
    mov dword [ETHERNET_RX_DATA_BUFFER_BASE], edi
    mov ecx, ((E1000_RX_FRAME_ALLOC_SIZE * E1000_NUM_RX_DESC)/4)    ;65536(0x10000) DWORDs
    xor eax, eax    ; just in case
    rep stosd   ; zero out 0x40000 of memory.

    ; Set up descriptor addresses to point to each 8192-byte RX buffer chunk.
    mov ecx, E1000_NUM_RX_DESC  ; Counter = number of RX descriptors
    mov edi, dword [ETHERNET_RX_DESC_BUFFER_BASE]   ; return to the base of the RX desc table
    add edi, 4  ; EDI = low DWORD of .addr struct space in the first RX desc.
    mov esi, dword [ETHERNET_RX_DATA_BUFFER_BASE]   ; set ESI to the beginning of RX data buffer.
 .setDescAddrs: ; set RX buffer descriptor addresses.
    mov dword [edi], esi    ; address @ESI into memory @EDI
    add edi, E1000_RX_DESC_SIZE ; add RX descriptor size to go to next .addr
    add esi, E1000_RX_FRAME_ALLOC_SIZE  ; increment ESI by 8192 bytes (frame allocation size of RX buffer chunk/piece)
    loop .setDescAddrs

    ; Write information to the Ethernet device to initialize RX abilities.
    ;push dword 0x00000000  ;value
    ;push dword E1000_REG_TXDESCHI   ;port - try changing this to LO & next to HI if stops functioning? Not sure if wiki is wrong
    ;call E1000_WRITE_COMMAND
    ;add esp, 8

    ;push dword [ETHERNET_RX_DESC_BUFFER_BASE]   ;value
    ;push dword E1000_REG_TXDESCLO   ; port
    ;call E1000_WRITE_COMMAND
    ;add esp, 8

    ; Low Desc Base DWORD = addr of the RX desc buffer base
    push dword [ETHERNET_RX_DESC_BUFFER_BASE]
    push dword E1000_REG_RXDESCLO
    call E1000_WRITE_COMMAND
    add esp, 8

    ; High Desc Base DWORD = 0x0 (not on an x64 machine)
    push dword 0x00000000
    push dword E1000_REG_RXDESCHI
    call E1000_WRITE_COMMAND
    add esp, 8

    ; Tell how large the RX descs buffer/table is.
    push dword (E1000_NUM_RX_DESC * E1000_RX_DESC_SIZE)
    push dword E1000_REG_RXDESCLEN
    call E1000_WRITE_COMMAND
    add esp, 8

    ; Tell to start @ RX_DESC[0]
    push dword 0x00000000
    push dword E1000_REG_RXDESCHEAD
    call E1000_WRITE_COMMAND
    add esp, 8

    ; ... And end at RX_DESC[15]
    push dword (E1000_NUM_RX_DESC);-1)
    push dword E1000_REG_RXDESCTAIL
    call E1000_WRITE_COMMAND
    add esp, 8

    ; Set the required RX Control Register values for basic operation.
    push dword (E1000_RCTL_EN|E1000_RCTL_SBP|E1000_RCTL_UPE|E1000_RCTL_MPE|E1000_RCTL_LBM_NONE|E1000_RTCL_RDMTS_HALF|E1000_RCTL_BAM|E1000_RCTL_SECRC|E1000_RCTL_BSIZE_8192);2048)
    push dword E1000_REG_RCTRL
    call E1000_WRITE_COMMAND
    add esp, 8

 .leaveCall:
    popad
    ret



; Enable TX on the device.
E1000_TX_ENABLE:    ;.status = tx_desc + 12
    pushad

    ; Clear first, then set up the TX descriptor table.
    xor eax, eax
    xor ecx, ecx
    mov edi, dword [ETHERNET_TX_DESC_BUFFER_BASE]
    mov ecx, (E1000_NUM_TX_DESC * E1000_TX_DESC_SIZE)
    push edi    ; save
    rep stosb   ; zero out the tx_desc table
    pop edi     ; restore EDI to TX_DESC_BUFFER_BASE

    ; Set the TX_DESC status fields to the Desc Done (DD) signal.
    add edi, 12 ; offset into TX_DESC #1 status field (see struct at top of this document)
    xor eax, eax    ; clear junk just in case
    mov al, 0x01;E1000_TSTA_DD  ; Desc Done signal
    mov ecx, E1000_NUM_TX_DESC  ; Counter = # of TX_DESC entries
 .setDescStatuses:
    mov strict byte [edi], al
    add edi, E1000_TX_DESC_SIZE
    loop .setDescStatuses

    ; Write information to the Ethernet device to initialize TX abilities...
    push dword 0x00000000
    push dword E1000_REG_TXDESCHI
    call E1000_WRITE_COMMAND
    add esp, 8

    push dword [ETHERNET_TX_DESC_BUFFER_BASE]
    push dword E1000_REG_TXDESCLO
    call E1000_WRITE_COMMAND
    add esp, 8

    push dword (E1000_NUM_TX_DESC * E1000_TX_DESC_SIZE)
    push dword E1000_REG_TXDESCLEN
    call E1000_WRITE_COMMAND
    add esp, 8

    push dword 0x00000000
    push dword E1000_REG_TXDESCHEAD
    call E1000_WRITE_COMMAND
    add esp, 8

    push dword (E1000_NUM_TX_DESC)
    push dword E1000_REG_TXDESCTAIL
    call E1000_WRITE_COMMAND
    add esp, 8

    push dword (E1000_TCTL_EN|E1000_TCTL_PSP|(15 << E1000_TCTL_CT_SHIFT)|(64 << E1000_TCTL_COLD_SHIFT)|E1000_TCTL_RTLC)
    push dword E1000_REG_TCTRL
    call E1000_WRITE_COMMAND
    add esp, 8

    ; The below lines of code overrides the block before it (TCTRL) but both are here
    ;  to highlight that the previous one works with e1000 cards, but for the e1000e cards
    ;  you should set the TCTRL register as follows. For detailed description of each bit,
    ;  please refer to the Intel Manual.
    ; In the case of I217 and 82577LM packets will not be sent if the TCTRL is not configured using the following bits.
    ;writeCommand(REG_TCTRL,  0b0110000000000111111000011111010);
    ;push dword 00110000000000111111000011111010b    ;0x3003F0FA
    ;push dword E1000_REG_TCTRL
    ;call E1000_WRITE_COMMAND
    ;add esp, 8

    ;writeCommand(REG_TIPG,  0x0060200A);
    ;push dword 0x0060200A
    ;push dword E1000_REG_TIPG
    ;call E1000_WRITE_COMMAND
    ;add esp, 8
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 .leaveCall:
    popad
    ret


E1000_CLEAR_MULTICAST_TABLE:
    pushad

    mov ecx, 0x00000080 ; 0x80 iterations
    mov edi, 0x00005200 ; multicast table array area (5200-527C)
    sub edi, 4  ; set it down one to account for the starting counter of 0x80
    ; `-- don't want to write to 0x5400!
    xor eax, eax    ; set to 0
 .repeat:
    push ecx    ; save current counter
    push edi    ; save base ptr (0x5200)
    shl ecx, 2  ;x4
    add edi, ecx    ; EDI = 0x5200 + ecx*4

    push dword eax  ; - write value = 0
    push dword edi  ; - port = EDI
    call E1000_WRITE_COMMAND
    add esp, 8

    pop edi     ; return to base
    pop ecx     ; return to current count
    loop .repeat    ; decrement and repeat, bleed on finish.
 .leaveCall:
    popad
    ret



; Set the Link State to UP in the CTRL register.
E1000_SET_LINK_UP:
    push eax
    func(E1000_READ_COMMAND,E1000_REG_CTRL)
    or eax, E1000_ECTRL_SLU
    func(E1000_WRITE_COMMAND,E1000_REG_CTRL,eax)
    pop eax
 .leaveCall:
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; INPUTS:
;   ARG1 = Base ptr to packet data.
;   ARG2 = Length of packet.
; Device-specific packet sending function.
E1000_SEND_PACKET:
    push ebp
    mov ebp, esp
    pushad

    movzx eax, byte [E1000_TX_CURSOR]   ; get current offset into the desc table
    mov edi, dword [ETHERNET_TX_DESC_BUFFER_BASE] ; EDI = base of desc table
    add edi, eax    ; EDI = addr of offset into desc table

    ;struc e1000_tx_desc
    ;    .addr: resq 1 (High<<32|Low)
    ;    .length: resw 1
    ;    .cso: resb 1
    ;    .cmd: resb 1
    ;    .status: resb 1
    ;    .css: resb 1
    ;    .special: resw 1
    ;endstruc
    push eax
    mov dword [edi], 0x00000000 ; TX_DESC_TABLE[cursor]->addrHighDword = 0
    mov eax, dword [ETHERNET_PACKET_SEND_BUFFER_BASE]
    mov dword [edi+4], eax   ; TX_DESC_TABLE[curspr]->addrLowDword = Send buffer ptr
    mov eax, dword [ebp+12]     ;packet length
    mov dword [edi+8], eax
    mov byte [edi+11], (E1000_CMD_EOP|E1000_CMD_IFCS|E1000_CMD_RS|E1000_CMD_RPS)    ; ->cmd = commands
    mov byte [edi+12], 0x00 ;->status = 0
    pop eax

    mov byte [E1000_TX_CURSOR_OLD], al  ; Put prev cursor into old slot

    ; TX_CURSOR = (TX_CURSOR + 1) % E1000_NUM_TX_DESC   <-- formula keeps cursor circular and in the descs table
    inc al
    xor ebx, ebx
    mov bl, 8;mov bl, E1000_NUM_TX_DESC
    div bl  ; AH = modulus result (remainder)
    mov byte [E1000_TX_CURSOR], ah  ; store new cursor position.

    ; Write out the TX_CURSOR position as the new TAIL.
    movzx eax, byte [E1000_TX_CURSOR]   ; put new cursor back into EAX
    ;func(E1000_WRITE_COMMAND,E1000_REG_TXDESCTAIL,eax)
    push dword eax
    push dword E1000_REG_TXDESCTAIL
    call E1000_WRITE_COMMAND
    add esp, 8

    ;while( !(tx_descs[old_cur]->status & 0xff));
    ; EDI is still pointing to the TX_DESC_TABLE[old_cursor] base.
 .loopTX:
    cmp byte [edi+12], 0x00 ; TX_DESC_TABLE[old_cursor]->status == 0?
    je .exitLoopTX  ;should be JNE (see ! above), but hangs until TX is working...
    jmp .loopTX
 .exitLoopTX:

    ;PrintString szETHERNET_DEVICE_FAILURE,0x02 ;TEST CODE - testing reachability...
 .leaveCall:
    popad
    pop ebp
    ret
