; CRYPTO.asm
; -- Header file containing all global functionsm definitions, & references for the crypto library.

CRYPTO_BUFFER_BASE_POINTER  dd 0x00000000
CRYPTO_BUFFER_SIZE         equ 0x00001000   ; 4 KiB of operable RAM
CRYPTO_PROCESS_ID           db 0x00
CRYPTO_PROCESS_FAILURE      db FALSE

;MD5 reserved memory space.

szCRYPTO_PROCESS_DESC_STRING db "Crypto Platform", 0
CRYPTO_REGISTER_PROCESS:
    push dword szCRYPTO_PROCESS_DESC_STRING
    push dword CRYPTO_BUFFER_SIZE
    call MEMOPS_KMALLOC_REGISTER_PROCESS    ; EAX = Buffer base for crypto process; BL = PID
    add esp, 8
    or eax, eax     ; EAX = 0 = error.
    jz .error
    mov dword [CRYPTO_BUFFER_BASE_POINTER], eax
    mov byte [CRYPTO_PROCESS_ID], bl
    jmp .leaveCall
 .error:
    mov byte [CRYPTO_PROCESS_FAILURE], TRUE
 .leaveCall:
    ret
