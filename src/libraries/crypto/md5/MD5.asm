; MD5.asm
; -- Primary functions for hashing data in RAM and storing in the CRYPT process' memory.
; -- Command in SHELL_MODE will have two modes: one to retrieve the most recently-computed hash,
; ---- and another to compute an MD5 from a starting loc in memory for a specific length.

; Important to note is that the algorithm's granularity is a per-byte hashing,
; -- meaning it is impossible to hash exactly 315 bits with this algorithm.
; -- It would instead round to the next whole byte (8-bit boundary).

; Include the MD5 internal functions file.
%include "libraries/crypto/md5/MD5_GUTS.asm"



; 1 KiB into the base ptr of the Crypto Platform process is the MD5 RAM section
CRYPTO_MD5_BUFFER_BASE_OFFSET   equ 0x00000400
; This section is 2096 bytes long. Subject to change, because I don't know how RAM-intense the MD5 algo will be,
; ... but a large buffer is needed for potentially-large data.
CRYPTO_MD5_BUFFER_MEMCPY_ZONE_SIZE	equ 0x00000800
CRYPTO_MD5_BUFFER_LENGTH			equ (CRYPTO_MD5_BUFFER_MEMCPY_ZONE_SIZE + 0x30) ;+48 for the result stuff at the beginning


; Initialize the MD5 memory pointers.
CRYPTO_MD5_INIT:
	push edi
	mov edi, dword [CRYPTO_BUFFER_BASE_POINTER]	; EDI = base of Crypto Plat process.
	add edi, CRYPTO_MD5_BUFFER_BASE_OFFSET	; + Offset to start of MD5-reserved memory.
	push edi
	add edi, MD5_RESULT_OFFSET			; Go to the ptr where the hex output is stored.
	mov dword [MD5_RESULT_POINTER], edi	; Store the base result pointer.
	pop edi		; EDI = MD5 base
	push edi
	add edi, MD5_RESULT_STRING_OFFSET	; Go to the ptr where the ASCII output is stored.
	mov dword [MD5_RESULT_ASCII_POINTER], edi	; Store the base ASCII result pointer.
	pop edi		; EDI = MD5 base
	push edi
	add edi, MD5_MEMCPY_ZONE_OFFSET		; Go to the ptr where the parsed data is copied.
	mov dword [MD5_MEMCPY_ZONE_POINTER], edi	; Store the base of the MEMCPY zone.
	pop edi		; EDI = MD5 base
	;mov [edi], dword 0x78563412 ;TEST CODE (works)
 .leaveCall:
 	pop edi
 	ret


; INPUTS:
; 	ARG1 = Buffer Base
;	ARG2 = Buffer Length
; OUTPUTS: none, CF on error.
; -- The core MD5 function wrapper that will take an input and process the unique hash digest string into RAM.
; ---- There will be a separate function to output the results in both ASCII and pure Hexadecimal.
; DEFINITIONS:
;	'PASS': One complete hashing (4-round sequence) over a 16-byte segment of the input. There are 4 passes at minimum.
;	'ROUND': One subsection of the computation algorithm that involves one of the interal F-I functions.
;	'BLOCK': A 64-byte segment of the input buffer. There is always at least ONE of these, due to the 512-bit nature of the MD5 algorithm.
;	'INPUT BUFFER': The data to be hashed, both referenced and computed at a BYTE granularity.
MD5_COMPUTE_HASH:
	FunctionSetup
	pushad
	ZERO eax,ebx,ecx,edx

	mov edi, dword [MD5_RESULT_POINTER]	; EDI = base ptr to 16-byte result storage.
	mov esi, dword [ebp+8]	; ESI = Base of buffer
	mov ecx, dword [ebp+12]	; ECX = Length --> NEEDS HARD LIMIT BASED ON AVAILABLE RAM AND PASS COUNTER (16,320 is looking likely)

	; Copy the content to the internal buffer to be padded out.
	push edi
	mov edi, dword [MD5_MEMCPY_ZONE_POINTER]
	MEMCPY esi,edi,ecx
	pop edi

	call MD5_INTERNAL_GET_PASS_COUNT	; EAX = # passes // BX = lengthof(last 64-byte block of data) mod 64
	func(MD5_INTERNAL_PAD_DATA,ecx)		; Using that information, pad the input buffer to the necessary length.

	; AL is still pass count. Begin computation.
	and eax, 0x000000FF	; all other data in EAX is unimportant.
	ZERO ecx	; prepare counter variable.
	;shl al, 2	; multiply pass count by 4, since the 64-byte chunks are computed 16 bytes at a time.
	mov cl, al	; Set the counter with the new pass value.
	push ecx	; --save counter
	push edi	; initial push of edi
	mov esi, dword [MD5_MEMCPY_ZONE_POINTER]	; ESI = starting base of mem to hash.
	; setup the initial four A,B,C,D values, respectively.
	; ! This may be invalid due to endianness, if the algo doesn't work and all else is solid, modify this.
	mov eax, dword 0x67452301
	mov ebx, dword 0xefcdab89
	mov ecx, dword 0x98badcfe
	mov edx, dword 0x10325476
	jmp .pass_skipInitialPush

 .pass:
 	push ecx	; save counter...
	push edi	; save base ptr position in case it changes inside the pass function.
	mov eax, dword [edi]	; EAX = 1st DWORD
	mov ebx, dword [edi+4]	; EBX = 2nd
	mov ecx, dword [edi+8]	; ECX = 3rd
	mov edx, dword [edi+12]	; EDX = 4th
   .pass_skipInitialPush:

	call MD5_INTERNAL_PASS

	; Store the results of the complex computations.
	pop edi	; restore in case of change
	mov dword [edi], eax
	mov dword [edi+4], ebx
	mov dword [edi+8], ecx
	mov dword [edi+12], edx

	add esi, 64;16; next segment of the block

	; restore the counter, and loop
	pop ecx
	loop .pass

	; Should be finished. Need to also convert the string to ASCII.

 .leaveCall:
 	;call MD5_INTERNAL_CLEAN_VARIABLES	; Clean up the guts.
 	popad
 	FunctionLeave
