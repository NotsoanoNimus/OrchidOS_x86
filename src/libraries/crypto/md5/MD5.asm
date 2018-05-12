; MD5.asm
; -- Primary functions for hashing data in RAM and storing in the CRYPT process' memory.
; -- Command in SHELL_MODE will have two modes: one to retrieve the most recently-computed hash,
; ---- and another to compute an MD5 from a starting loc in memory for a specific length.

; 256 bytes into the base ptr of the Crypto Platform process is the MD5 RAM section
CRYPTO_MD5_BUFFER_BASE_OFFSET   equ 0x00000100
; This section is 2KiB long.
CRYPTO_MD5_BUFFER_LENGTH        equ 0x00000800
