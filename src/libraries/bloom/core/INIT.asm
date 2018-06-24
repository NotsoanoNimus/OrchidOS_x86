; /libraries/bloom/INIT.asm
; -- Used to initialize Orchid's 'blooming' mode.
; -- Runs external scripts at startup, with

; Include the user's custom scripts ledger.
%include "bloom/LEDGER.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Primary initiation super-functions for both modes.

BLOOM_SHELL_MODE:
 .leaveCall:
    ret



BLOOM_GUI_MODE:
 .leaveCall:
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Platform initialization functions.

BLOOM_PLATFORM_INITIALIZE:
    pushad
    call BLOOM_PLATFORM_REGISTER_PROCESS
 .leaveCall:
    popad
    ret


szBLOOM_PROCESS_NAME db "Orchid Bloom Platform", 0
BLOOM_PLATFORM_REGISTER_PROCESS:
    func(MEMOPS_KMALLOC_REGISTER_PROCESS,BLOOM_PROCESS_REQUIRED_RAM,szBLOOM_PROCESS_NAME)
    or eax, eax     ; EAX = 0?
    jz .error
    mov strict byte [BLOOM_PROCESS_ID], bl
    mov dword [BLOOM_PROCESS_BASE_PTR], eax
    jmp .leaveCall
 .error:
    mov byte [BLOOM_PROCESS_FAILURE], TRUE
 .leaveCall:
    ret
