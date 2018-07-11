; STEM.asm
; -- STEM header-file centralization and meta functions for system control and security.

%include "stem/stream/ISTREAM.asm"
%include "stem/stream/OSTREAM.asm"

%include "stem/task/TASKMAN.asm"

%include "stem/core/SYSCALL.asm"


STEM_PROCESS_BASE_PTR   dd 0x00000000
STEM_PROCESS_ALLOC      dd 0x00002000   ; 8 KiB of RAM
STEM_PROCESS_ID         db 0x00
STEM_PROCESS_FAILURE    db FALSE

szSTEM_PROCESS_DESC db "STEM Platform", 0
STEM_INIT:
    func(MEMOPS_KMALLOC_REGISTER_PROCESS,STEM_PROCESS_ALLOC,szSTEM_PROCESS_DESC)
    or eax, eax
    jz .error
    mov dword [STEM_PROCESS_BASE_PTR], eax
    mov strict byte [STEM_PROCESS_ID], bl
    call ISTREAM_INIT
    call OSTREAM_INIT
    jmp .leaveCall
 .error:
    mov byte [STEM_PROCESS_FAILURE], TRUE   ; this will be a critical failure
 .leaveCall:
    ret
