; BLOOM_definitions.asm
; -- All required names/definitions for the BLOOM subsystem/module.

BLOOM_PROCESS_REQUIRED_RAM  equ 0x00010000  ; 64KiB required.
BLOOM_PROCESS_ID             db 0x00        ; BLOOM PID
BLOOM_PROCESS_BASE_PTR       dd 0x00000000
BLOOM_PROCESS_FAILURE        db FALSE
