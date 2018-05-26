; MD5.asm
; -- Primary functions for hashing data in RAM and storing in the CRYPT process' memory.
; -- Command in SHELL_MODE will have two modes: one to retrieve the most recently-computed hash,
; ---- and another to compute an MD5 from a starting loc in memory for a specific length.

; Include the MD5 internal functions file.
%include "libraries/crypto/md5/MD5_GUTS.asm"



; 1 KiB into the base ptr of the Crypto Platform process is the MD5 RAM section
CRYPTO_MD5_BUFFER_BASE_OFFSET   equ 0x00000400
; This section is 2KiB long. Subject to change, because I don't know how RAM-intense the MD5 algo will be.
CRYPTO_MD5_BUFFER_LENGTH        equ 0x00000800



; The core MD5 function wrapper that will take an input and process the unique hash digest string into RAM.
; -- There will be a separate function to output the results in both ASCII and pure Hexadecimal.
MD5_COMPUTE_HASH:
	FunctionSetup
	pushad

	; setup the initial four A,B,C,D values, respectively.
	; ! This may be invalid due to endianness, if the algo doesn't work and all else is solid, modify this.
	; Will relocate to an internal function soon.
	mov eax, dword 0x67452301
	mov ebx, dword 0xefcdab89
	mov ecx, dword 0x98badcfe
	mov edx, dword 0x10325476

 .leaveCall:
 	popad
 	FunctionLeave
