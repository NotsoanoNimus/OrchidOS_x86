; ETHERNET_SETUP.asm
; -- Setup and Init functions for the onboard Ethernet device.
; ---- May be split into multiple directories/files later
;      depending on the amount of vendors that become supported.

%include "libraries/drivers/ethernet/setup/intel/E1000_NIC.asm"

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
    call ETHERNET_INTEL_E1000_initialize
    pop eax
    jmp .leaveCall

 .leaveCall:
    call ETHERNET_SETUP_SAVE_IDS
    mov byte [ETHERNET_INITIALIZED], TRUE   ; wrap up ethernet initialization.
    ret


; INPUTS:
;   EAX = DeviceID<<16|VendorID
; OUTPUTS: NONE
ETHERNET_SETUP_SAVE_IDS:
    mov strict word [ETHERNET_VENDOR_ID], ax
    shr eax, 16
    mov strict word [ETHERNET_DEVICE_ID], ax
 .leaveCall:
    ret


szETHERNET_PROCESS_NAME db "Ethernet Controller", 0     ; 19 chars long, we are safe.
; Registers the system Ethernet process, allocates TX/RX buffer space in the Heap.
ETHERNET_REGISTER_PROCESS:
    push szETHERNET_PROCESS_NAME    ; arg2 - String name of process
    push ETHERNET_REQUIRED_RAM      ; arg1 - How much space is needed.
    call MEMOPS_KMALLOC_REGISTER_PROCESS    ; EAX = base ptr to RAM allocation, EBX(BL) = PID.
    add esp, 8
    or eax, eax     ; EAX = 0?
    jz .error       ; Tell the Ethernet driver & system about it.
    mov strict byte [ETHERNET_PROCESS_ID], bl
    mov dword [ETHERNET_PROCESS_BASE], eax
    jmp .leaveCall
 .error:
    ; also have to deallocate memory, perform cleanup tasks.
    mov byte [ETHERNET_PROCESS_FAILURE], TRUE
 .leaveCall:
    ret


szETHERNETIntel_E1000_found db "Discovered compatible Intel Gigabit Ethernet Controller.", 0
ETHERNET_INTEL_E1000_initialize:
    PrintString szETHERNETIntel_E1000_found,0x0A
    call ETHERNET_INTEL_E1000_NIC_START
    call ETHERNET_INTEL_E1000_NIC_SET_GLOBALS
 .leaveCall:
    ret
