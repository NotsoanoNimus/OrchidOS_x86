; CRYPTO.asm
; -- Header file containing all function references for the crypto library.

CRYPTO_BUFFER_BASE_POINTER  dd 0x00000000
CRYPTO_BUFFER_SIZE         equ 0x00001000   ; 4 KiB of operable RAM

szCRYPTO_PROCESS_DESC_STRING db "Crypto Platform", 0
CRYPTO_REGISTER_PROCESS:
    push dword szCRYPTO_PROCESS_DESC_STRING
    push dword CRYPTO_BUFFER_SIZE
    call MEMOPS_KMALLOC_REGISTER_PROCESS
    add esp, 8
 .leaveCall:
    ret
