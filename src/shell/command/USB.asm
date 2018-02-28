; USB.asm
; -- Lists available USB devices and debug information. Used for drive or device configuration.
; ---- Will later be used to configure USB devices based on specific device types (hosts/buses, SCSI, mouse, keyboard, etc.)

szUSBCMDDevDebug db "[DEBUG] USB Devices DWORD(SC1<<16|SC2):", 0
szUSBDeviceConn db "XXXXXXXX", 0

COMMAND_USB:
    pushad
    mov edi, PARSER_ARG1
    cmp strict byte [edi], 0x00
    jne .hasArg1
    call USBCMD_outputPortInfos
 .hasArg1:

 .leaveCall:
    popad
    ret



USBCMD_outputPortInfos: ;outputs ALL BARIO port SC1&2 INFO, and
    pushad
    PrintString szUSBCMDDevDebug,0x0A

    ;testing the readFromBARIO function.
    mov edi, UHCI_BARIO_1
 .testing:
    cmp word [edi], 0x0000
    je .break_bariotest

    ; Create ROO.
    xor eax, eax
    mov word ax, [edi]      ;get BAR I/O port address
    shl eax, 16
    mov ah, UHCI_PORTSC1
    mov al, WORD_OPERATION
    push dword eax	;EAX = (BARIO<<16|Offset<<8|OperationType) --> ROO variable.
    call USB_UHCI_readFromBARIO
    mov cx, ax  ; copy result into CX
    shl ecx, 16 ; move SC1 to top of ECX
    pop dword eax   ;get back ROO variable.
    mov ah, UHCI_PORTSC2    ; get port 2 from copy var
    push dword eax
    call USB_UHCI_readFromBARIO
    add esp, 4
    mov cx, ax

    ; Print result and reset buffers
    mov eax, ecx
    xor ecx, ecx
    mov esi, szUSBDeviceConn+8
    call UTILITY_DWORD_HEXtoASCII
    PrintString szUSBDeviceConn,0x0D

    ; clean buffer.
    mov cl, 8   ; 8 bytes in szUSBDeviceConn
    xor eax, eax
    mov al, '0'
    push edi
    mov edi, szUSBDeviceConn
    rep stosb
    pop edi

    ; next port
    add edi, 2
    jmp .testing
 .break_bariotest:
    popad
    ret
