; SNIPPETS.asm
; -- Contains test codes that I'd like to save for later debugging.
; ---- They're saved here because they distract from functional codes elsewhere.


    ; SUCCESSFULLY LISTS THE INFO BELOW @0x72000. Use `MEMD 72000 20` to check it out.
    MEMCPY ETHERNET_MAC_ADDRESS,0x72000,0x06
    MEMCPY ETHERNET_VENDOR_ID,0x72010,0x02
    MEMCPY ETHERNET_DEVICE_ID,0x72012,0x02


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Strscan working and in action!
    mov [0x2003], word "Fi"
    mov [0x2010], dword "Find"
    mov [0x3006], dword "Find"
    mov [0x300A], dword " me!"
    push dword szTESTME
    call VFS_GET_FILE_ID
    mov [0x72000], dword eax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; debugging - check connectivity of each UHCI usb device. Works to display connected status of all UHCI-compatible ports!
    ; --> When checking ports found in the BARIO variables, simply type dump in the console when the system starts
    ;      and look at the addr EDI is pointing to. MEMD it to see the stored BARIOs.
    mov edi, UHCI_BARIO_1
  .testing:
    cmp word [edi], 0x0000		; is there no next port?
    je .break_test				; if not, leave
    ; Create ROO variable.
    xor eax, eax
    mov word ax, [edi]
    shl eax, 16
    mov ah, UHCI_PORTSC1
    mov al, UHCI_WORD_OPERATION
    push dword eax
    call USB_UHCI_DEBUG_outputPortVariable
    add esp, 4
    mov ah, UHCI_PORTSC2
    call USB_UHCI_DEBUG_outputPortVariable
    add esp, 4
    add edi, 2		; next port in line
    jmp .testing
  .break_test:

    ;testing the readFromBARIO function.
    mov edi, UHCI_BARIO_1
    cmp word [edi], 0x0000
    je .break_bariotest
    ; Create ROO.
    xor eax, eax
    mov word ax, [edi]
    shl eax, 16
    mov ah, UHCI_PORTSC1
    mov al, UHCI_WORD_OPERATION
    push dword eax	;EAX = (BARIO<<16|Offset<<8|OperationType) --> ROO variable.
    call USB_UHCI_readFromBARIO
    add esp, 4
    mov bl, 0x0A
    mov esi, szUSBDeviceConn+8
    call UTILITY_DWORD_HEXtoASCII
    mov esi, szUSBDeviceConn
    call _screenWrite
  .break_bariotest:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; debugging - Placed in the kernel's main loop to test the KMALLOC and KFREE of the heap.
    KMALLOC 8
    ; This snippet here is what the regular MALLOC function syscall will do later.
    ;  It will account for headers and footers while writing a program into allocated memory.
    mov edi, eax		; set EDI to return address of alloc start
    mov ecx, 0x3B
    mov eax, 0x0f0f0f0f
    add edi, 0x0C		; don't overwrite the header...
    rep stosd
    KMALLOC 13			; alloc 00100000 to 00100100
    KMALLOC 128			; alloc 00100100 to 00100200
    KMALLOC 0x358		; alloc 00100200 to 00100600
    KMALLOC 0x00FF0000	; alloc 00100600 to 010F0600
    KMALLOC 0x00008123	; alloc 010F0600 to 010F8800
    KMALLOC 0x01000000	; alloc 010F8800 to 020F8800
    KMALLOC 0x10000000	; alloc 020F8800 to 10000000
    KFREE 0x00100000		; successfully clears memory at 0x100000
    KFREE 0x00100100		; Now see if it combines holes.
    KFREE 0x00100200
    KMALLOC 8				; Yes, it worked! Use "MEMD 100000 100" and "MEMD 100100 100" to compare and check.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; debugging - find out where the ACPI kernel info is stored internally, to read the values through memd.
	; Starts at ACPI_VERSION, since that's the first linear variable space adjacent to all of the others ahead of it.
	;mov esi, ACPI_VERSION
	;call _commandDUMP
	; debugging - check if MEMCMP & MEMCPY work. There is an "RSD PTR " in the RSDP address.
	; Check with MEMD at the address that EAX returns to verify that "PTR " exists at that location --> SUCCESS!
	MEMCMP DWORD_OPERATION,[ACPI_RSDP],0x20,"PTR "
	; now use EAX as the source address of the MEMCPY, to copy 50 bytes from the RSDP to 0x50000.
	MEMCPY eax,0x00050000,0x00000050
	call COMMAND_DUMP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; verify endianness change functions
    mov [0x00100100], dword 0x01020304
    mov [0x00100104], dword 0x05060708
    mov [0x00100108], dword 0x090a0b0c
    mov [0x0010010C], dword 0x0d0e0f10
    push 0x00000004
    push 0x00100100
    call DATA_DWORD_switch_endian
