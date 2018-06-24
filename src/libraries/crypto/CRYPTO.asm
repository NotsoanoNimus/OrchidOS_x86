; CRYPTO.asm
; -- Header file containing all global functions, definitions, & references for the crypto library.

%include "libraries/crypto/md5/MD5.asm"     ; MD5 library.

CRYPTO_RESULT_BUFFER:   ; the result buffer is at the base and is 1024 bytes long. This will be expanded as the crypto library grows.
CRYPTO_BUFFER_BASE_POINTER  dd 0x00000000
CRYPTO_BUFFER_SIZE         equ 0x00001000   ; 4 KiB of operable RAM
CRYPTO_PROCESS_ID           db 0x00
CRYPTO_PROCESS_FAILURE      db FALSE

; Wrapper function to handle all Crypto Platform initialization.
CRYPTO_PLATFORM_INITIALIZE:
    pushad
    call CRYPTO_REGISTER_PROCESS    ; Register the Crypto process.
    call CRYPTO_MD5_INIT            ; Setup memory pointers for the MD5 algorithm.
 .leaveCall:
    popad
    ret

szCRYPTO_PROCESS_DESC_STRING db "Crypto Platform", 0
CRYPTO_REGISTER_PROCESS:
    func(MEMOPS_KMALLOC_REGISTER_PROCESS,CRYPTO_BUFFER_SIZE,szCRYPTO_PROCESS_DESC_STRING)
    ; EAX = Buffer base for crypto process; BL = PID
    or eax, eax     ; EAX = 0 = error.
    jz .error
    mov dword [CRYPTO_BUFFER_BASE_POINTER], eax
    mov byte [CRYPTO_PROCESS_ID], bl
    jmp .leaveCall
 .error:
    mov byte [CRYPTO_PROCESS_FAILURE], TRUE
 .leaveCall:
    ret
