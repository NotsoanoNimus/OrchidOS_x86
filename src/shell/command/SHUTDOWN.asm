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

    call COMMAND_SHUTDOWN_ZERO_MEMORY

    ; test whether it's a hardware shutdown, or an emulator shutdown.
    cmp byte [IS_ON_EMULATOR], TRUE
    je .emulatorShutdown

    cmp byte [IS_ACPI_ENABLED], TRUE
    je .alreadyEnabled
    call ACPI_enable
  .alreadyEnabled:
    SLEEP 7         ; 7x200ms = ~1.5s
    ZERO eax,edx
    ; SHUT IT DOWN.
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
    ZERO eax,edx

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



; INPUTS:
;   NONE
; OUTPUTS:
;   NONE
; Clears all non-kernel & non-vital memory zones on the system.
; -- This function is only ever used before a shutdown or reboot.
; This is NOT graceful, as it forces destruction of running process handles & heap space.
; -- Therefore a shutdown is REQUIRED when this command is called, no matter what.
COMMAND_SHUTDOWN_ZERO_MEMORY:
    MultiPush eax,ecx,edi
    ZERO eax

    ; clear the VFS
    mov edi, VFS_BUFFER_BASE
    mov ecx, (VFS_BUFFER_SIZE/4)
    rep stosd

    ; clear the Heap
    mov edi, HEAP_START
    mov ecx, dword [HEAP_CURRENT_SIZE]
    rep stosb

    ; Zero from 0xF00 to 0x7C00
    mov edi, 0x500
    mov ecx, ((0x7C00-0xF00)/4)
    rep stosd

    ; Zero from 0x7E00 to 0x10000
    mov edi, 0x7E00
    mov ecx, ((0x10000-0x7E00)/4)
    rep stosd

    ; Clean up Kernel variables that may give valuable info.
    mov edi, VFS_TABLE_ENTRY    ; this single table actually exists in kernel mem and is memcpy'd when creating new files
    mov ecx, VFS_TABLE_ENTRY_LENGTH
    rep stosb

    jmp .leaveCall

 .leaveCall:
    MultiPop edi,ecx,eax
    ret
