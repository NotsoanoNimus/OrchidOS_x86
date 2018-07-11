; SYSCALL.asm
; -- System call registration and handling, macros and related services for users to directly interact with the kernel.


; The primary entry function for System Calls.
szSYSCALLTEST db "SYSCALL TEST", 0
ISR_SYSCALL:
    call COMMAND_DUMP
    PrintString szSYSCALLTEST,0x0D
    ret
