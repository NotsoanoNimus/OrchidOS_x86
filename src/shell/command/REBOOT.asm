; REBOOT.asm
; -- Reboot the PC by   C R A S H I N G   T H E   S Y S T E M

bREBOOTPending	db FALSE

szREBOOTWarning     db "A reboot is now pending. To finalize it, enter the REBOOT command again.", 0
szREBOOTWarning2    db "  -- If you wish to cancel this, enter anything other than REBOOT.", 0
szREBOOTFinal       db "Rebooting...", 0
COMMAND_REBOOT:
    ; On the first call, set the pending reboot. On the next call, initiate reboot.
    cmp byte [bREBOOTPending], TRUE
    je .comeCrashingDown

    mov byte [bREBOOTPending], TRUE
    PrintString szREBOOTWarning,0x09
    PrintString szREBOOTWarning2
 .leaveCall:
    ret

 .comeCrashingDown:
    call COMMAND_SHUTDOWN_ZERO_MEMORY
    ; Let the user know, at least.
    PrintString szREBOOTFinal,0x0B
    SLEEP 7     ; 7x200ms = ~1.5s
    ; Crash this system, with no survivors.
    lidt [NULL_IDT]
    int 0
   .failsafe:   ; here in case the IDT method does not triple-fault anything.
    hlt
    jmp .failsafe
