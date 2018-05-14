; ETHERNET_SETUP.asm
; -- Setup and Init functions for the onboard Ethernet device.
; ---- May be split into multiple directories/files later
;      depending on the amount of vendors that become supported.

%include "libraries/drivers/ethernet/setup/intel/E1000_NIC.asm"
%include "libraries/drivers/ethernet/setup/via/VT6103_NIC.asm"

; Called by the primary Ethernet driver to delegate setup responsibility to this component file.
; -- Reads device ID stored from PCI_INFO earlier.
; -- If no matching ethernet device was found, will exit and continue system initialization.
szETHERNET_DEVICE_FAILURE   db "Onboard Ethernet adapter failed to initialize.", 0
ETHERNET_SETUP_begin:
    call ETHERNET_REGISTER_PROCESS
    cmp byte [ETHERNET_PROCESS_FAILURE], TRUE
    je .issueInit

    xor ecx,ecx
    xor eax,eax

    mov edi, PCI_INFO
    add edi, 4          ; Set EDI at the first PCI entry's (DevID<<16|VenID) DWORD.
    mov cl, byte [PCI_INFO_NUM_ENTRIES] ; CL = counter

 .searchForEthernetDevice:
    mov eax, dword [edi]
    ; Here will be a list of all supported ethernet Vendor ID's & Device ID's to match against.
    ; The first and only one for the moment will be supported by QEMU.

    ;Intel E1000 NIC Gigabit Ethernet Controller (QEMU).
    ;  This driver should theoretically be able to support all three devices listed below.
    cmp eax, ETHERNET_INTEL_E1000_DEVICE_ID
    je .Intel_E100
    cmp eax, ETHERNET_INTEL_I217_DEVICE_ID
    je .Intel_E100
    cmp eax, ETHERNET_INTEL_82577LM_DEVICE_ID
    je .Intel_E100

    ;VIA Technologies VT6103 Rhine II Ethernet Controller.
    cmp eax, ETHERNET_VIA_VT6103_RHINE_II
    je .VIA_VT6103

    ; Decrement counter, check if there are still more devices to iterate.
    add edi, 20     ; Each PCI entry is 20 bytes long (5 DWORDs).
    dec cl
    or cl, cl
    jnz .searchForEthernetDevice
 .issueInit:
    ; This code is run when no Ethernet device is found. Tell the system about it.
    ; Don't forget to kfree the allocated Heap space.
    or dword [BOOT_ERROR_FLAGS], 0x00000100 ; Set bit8 of BOOT_ERROR_FLAGS
    xor eax, eax        ; Vendor & Device IDs = 0
    PrintString szETHERNET_DEVICE_FAILURE,0x0C
    jmp .leaveCall

 .Intel_E100:
    push eax    ; save vendor/device ID info
    push edi    ; save EDI ptr
    call ETHERNET_REGISTER_IRQ  ;required call before all driver inits.
    pop edi     ; restore it
    call ETHERNET_INTEL_E1000_initialize
    pop eax
    jmp .leaveCall

 .VIA_VT6103:
    push eax    ; save vendor/device ID info
    push edi    ; save EDI ptr
    call ETHERNET_REGISTER_IRQ
    pop edi     ; restore
    call ETHERNET_VIA_VT6103_initalize
    pop eax     ; restore
    jmp .leaveCall

 .leaveCall:
    call ETHERNET_SETUP_SAVE_IDS
    mov byte [ETHERNET_INITIALIZED], TRUE   ; wrap up ethernet initialization.
    ret



; Register the Ethernet Hardware IRQ# (INT 42d).
; -- THIS FUNCTION MUST ALWAYS BE CALLED BEFORE AN ETHERNET DRIVER INITIALIZATION!
ETHERNET_IRQ_OFFSET equ 0x0A    ; IRQ 10 (IRQ0+10) = INT 42 as a direct Ethernet INT.
ETHERNET_REGISTER_IRQ:
    ; SINCE EDI = ETHERNET_ENTRY+4, subtract 4 to get the PCI device ID (Bus, Slot/Dev, func)
    push ecx
    sub edi, 4
    mov ecx, dword [edi]    ; ECX = PCI device
    mov cl, 0x3C ;read Interrupt PIN & LINE from PCI device.

    push dword ecx  ; PCI device address
    call PCI_configReadWord ; EAX = WORD at 0x3C PCI for Ethernet device (INT_PIN<<8|INT_LINE)
    pop dword ecx   ; restore arg in case trashed.
    mov al, ETHERNET_IRQ_OFFSET    ; IRQ 10 (IRQ0+10)

    push dword eax  ; AX = value to write.
    push dword ecx  ; ECX = PCI dev addr
    call PCI_WRITE_WORD_TO_PORT
    add esp, 8
    pop ecx
 .leaveCall:
    ret





; INPUTS:
;   EAX = DeviceID<<16|VendorID
; OUTPUTS: NONE
; -- A small, light function to save the PCI Ethernet device's VID & DID
ETHERNET_SETUP_SAVE_IDS:
    mov strict word [ETHERNET_VENDOR_ID], ax
    shr eax, 16
    mov strict word [ETHERNET_DEVICE_ID], ax
 .leaveCall:
    ret






; -- Called from the IDT as a primary ISR function when the Ethernet hardware forces a PIC interrupt.
; -- This function will look for the device-specific ISR to call.
ETHERNET_IRQ_FIRED:
    push eax
    mov eax, dword [ETHERNET_DRIVER_SPECIFIC_INTERRUPT_FUNC]
    or eax, eax     ; Check if the variable was ever set. Dangerous to call a dynamic location.
    jz .leaveCall
    call eax
 .leaveCall:
    pop eax
    ret




; Registers the system Ethernet process, allocates TX/RX buffer space in the Heap.
szETHERNET_PROCESS_NAME db "Ethernet Controller", 0     ; 19 chars long, we are safe.
ETHERNET_REGISTER_PROCESS:
    push szETHERNET_PROCESS_NAME    ; arg2 - String name of process
    push ETHERNET_REQUIRED_RAM      ; arg1 - How much space is needed.
    call MEMOPS_KMALLOC_REGISTER_PROCESS    ; EAX = base ptr to RAM allocation, EBX(BL) = PID.
    add esp, 8
    or eax, eax     ; EAX = 0?
    jz .error       ; Tell the Ethernet driver & system about it.
    mov strict byte [ETHERNET_PROCESS_ID], bl
    push eax    ; save base
    mov dword [ETHERNET_PROCESS_BASE], eax
    ; Both the RX & TX descriptor tables get 0x800 bytes each, so 0x1000 is reserved.
    mov dword [ETHERNET_RX_DESC_BUFFER_BASE], eax    ; RX buffer base = process base
    add eax, 0x800  ; the E1000 only needs 0x400(512bytes), but alloc 2x for other adapter needs.
    mov dword [ETHERNET_TX_DESC_BUFFER_BASE], eax    ; TX buffer base = process base + (sizeof RX buffer(0x800))
    pop eax     ; restore base
    push eax
    add eax, ETHERNET_PACKET_SEND_BUFFER_OFFSET ; Point to the beginning of the TX buffer (0x70000 into process RAM)
    mov dword [ETHERNET_PACKET_SEND_BUFFER_BASE], eax
    pop eax
    jmp .leaveCall
 .error:
    ; also have to deallocate memory, perform cleanup tasks.
    mov byte [ETHERNET_PROCESS_FAILURE], TRUE
 .leaveCall:
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Driver initalize super-functions.

; Initialize the KVM/QEMU E1000 Generic Intel Ethernet driver.
szETHERNETIntel_E1000_found db "Discovered compatible Intel Gigabit Ethernet Controller.", 0
ETHERNET_INTEL_E1000_initialize:
    pushad
    PrintString szETHERNETIntel_E1000_found,0x0A
    call ETHERNET_INTEL_E1000_NIC_START
    call ETHERNET_INTEL_E1000_NIC_SET_GLOBALS
 .leaveCall:
    popad
    ret



; Initialize the VIA ethernet driver.
szETHERNETVIA_VT61013_found db "Discovered compatible VIA Rhine II Fast Ethernet Controller.", 0
ETHERNET_VIA_VT6103_initalize:
    pushad
    PrintString szETHERNETVIA_VT61013_found,0x0A
    call ETHERNET_VIA_VT6103_NIC_START
    call ETHERNET_VIA_VT6103_NIC_SET_GLOBALS
 .leaveCall:
    popad
    ret
