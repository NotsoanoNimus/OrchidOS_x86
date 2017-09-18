; SHUTDOWN.asm
; -- Shut the system down using ACPI.

bSHUTDOWNPending    db FALSE

szSHUTDOWNWarning   db "A shutdown is now pending. To finalize it, enter the SHUTDOWN command again.", 0
szSHUTDOWNWarning1  db "  -- If you wish to cancel this, enter anything other than SHUTDOWN.", 0
szSHUTDOWNFinal     db "Shutting down...", 0
szSHUTDOWNNotPoss   db "Shutdown error! Manually shut the system down with the power switch.", 0
szSHUTDOWNEmulator  db "Shutdown", 0
COMMAND_SHUTDOWN:
    CheckErrorFlags 0x00000040,.errorNoShutdown     ; If bit 6 of BEF is set, SD is not possible.

    cmp byte [bSHUTDOWNPending], TRUE               ; was it already called once?
    je .shutdownTheSystem                           ; if so, shut it down.

    mov byte [bSHUTDOWNPending], TRUE
    PrintString szSHUTDOWNWarning,0x06
    PrintString szSHUTDOWNWarning1
 .leaveCall:
    ret


    ; Called if BOOT_ERROR_FLAGS, bit 6 is set.
 .errorNoShutdown:
    PrintString szSHUTDOWNNotPoss,0x0C
    jmp .leaveCall


 .shutdownTheSystem:
    PrintString szSHUTDOWNFinal,0x0B

    ; test whether it's a hardware shutdown, or an emulator shutdown.
    cmp byte [IS_ON_EMULATOR], TRUE
    je .emulatorShutdown

    cmp byte [IS_ACPI_ENABLED], TRUE
    je .alreadyEnabled
    call ACPI_enable
  .alreadyEnabled:
    SLEEP 7         ; 7x200ms = ~1.5s
    ; SHUT IT DOWN.
    xor eax, eax
    xor edx, edx
    mov dword edx, [ACPI_PM1a_CNT]  ; EDX = power mgmt control register 1a
    mov ax, [ACPI_S5_SLP_TYPa]
    or ax, ACPI_SLP_EN      ; AX = SLP_EN | SLP_TYPa

    out dx, ax     ; Perform shutdown.

    PrintString szSHUTDOWNNotPoss,0x0C
    cli
   .errorHWSD:
    hlt
    jmp .errorHWSD


 .emulatorShutdown:
    SLEEP 7

    xor eax, eax
    xor edx, edx

    ; Older QEMU and Bochs support shutting down by outputting the string "Shutdown" byte-by-byte to port 0x8900.
    mov dx, 0x8900
    mov esi, szSHUTDOWNEmulator
   .outputSD:
    lodsb
    out dx, al
    or al, al
    jz .emulatorSDnotWorking
    jmp .outputSD

    ; Option 1 above (for older QEMU & BOCHS) did not work. Try newer QEMU method.
    ; This method REQUIRES this option with QEMU: -device isa-debug-exit,iobase=0xF4,iosize=0x04
  .emulatorSDnotWorking:
    xor al, al
    out 0xF4, al

    ; If code reaches here, emulator shutdown failed... Hang and tell the user to press the switch.
    PrintString szSHUTDOWNNotPoss,0x0C
    cli
    .haltEm:
        hlt
        jmp .haltEm
