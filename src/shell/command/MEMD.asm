; MEMD.asm
; --- Dump memory to the command shell in SHELL_MODE only.

szMEMDInfo		db "Dumping memory at physical address 0x00000000"
szMEMDAddr		db ", with offset 0x0000"
szMEMDOffset	db "...", 0
szMEMDOutput	times 79 db 0x20	; Actual output area.
				db 0
szMEMDSyntax	db "MEMD SYNTAX -> ARG1: 32-bit physical Address (hex) // ARG2: Length (max 0x100)", 0
szMEMDError		db "ARG2 ERROR: Input value is invalid (should be 1-100 in hex)!", 0
szMEMDError2	db "ARG1 ERROR: Number must be 32-bit hex; do not precede address by '0x'.", 0


_commandMEMD:
	pushad
	xor ebx, ebx

	mov edi, PARSER_ARG1
	push edi
	cmp byte [edi], 0x00
	je .syntax
	mov edi, PARSER_ARG2
	cmp byte [edi], 0x00
	je .syntax
	mov edi, PARSER_ARG3
	cmp byte [edi], 0x00
	jne .syntax
	pop edi

	; Check arg1
	mov byte bl, [PARSER_ARG1_LENGTH]
	cmp bl, 8
	jg .err1
	mov esi, PARSER_ARG1
	call UTILITY_HEX_STRINGtoINT		; EAX = conversion.
	jc .err1
	mov edx, eax						; store into EDX

	; Check arg2
	mov byte bl, [PARSER_ARG2_LENGTH]
	cmp bl, 4
	jg .err2
	mov esi, PARSER_ARG2
	call UTILITY_HEX_STRINGtoINT		; EAX = conversion.
	jc .err2
	cmp eax, 0x100
	ja .err2
	mov ecx, eax						; Store into ECX

	; Round ECX to the nearest 16 bytes.
	or ecx, ecx		; first check if the user entered a zero...
	je .err2		;   if so, GTFO.
	dec ecx			; done in case of user inputs that are already even multiples of 0x10. Don't want an extra row.
	add ecx, 0x10
	and ecx, 0xFFFFFFF0		; 1111...11110000b.

	; Alter the information string.
	push ecx
	xor ecx, ecx
	mov byte cl, [PARSER_ARG1_LENGTH]
	mov edi, szMEMDAddr
	sub edi, ecx
	mov esi, PARSER_ARG1
	rep movsb
	mov byte cl, [PARSER_ARG2_LENGTH]
	mov edi, szMEMDOffset
	sub edi, ecx
	mov esi, PARSER_ARG2
	rep movsb
	pop ecx
	; Output the information string.
	mov esi, szMEMDInfo
	mov bl, 0x02
	call _screenWrite

	; Get to work.
	mov esi, edx		; Set ESI = base addr.
   .doOutput:
	call MEMD_generateOutput
	cmp ecx, 0
	jle .leaveCall
	jmp .doOutput

	;jmp .leaveCall

 .err1:
	mov esi, szMEMDError2
	mov bl, 0x0C
	jmp .writeMSG
 .err2:
	mov esi, szMEMDError
	mov bl, 0x0C
	jmp .writeMSG
 .syntax:
 	pop edi
	mov bl, 0x09
	mov esi, szMEMDSyntax
 .writeMSG:
	call _screenWrite
	jmp .leaveCall
 .leaveCall:
 	; clean up the string buffers.
	mov edi, szMEMDAddr-8
	mov eax, 0x30		;'0'
	mov cl, 8
	rep stosb
	mov edi, szMEMDOffset-4
	mov cl, 4
	rep stosb
	mov eax, 0x20202020	;"    "
	mov edi, szMEMDOutput
	mov cl, 19			; 19 DWORDs = 76 bytes. The last few bytes are always spaces anyway.
	rep stosd
	popad
	ret


; Don't worry about trashing anything, end of MEMD command has a popad. This is called at the last part of it.
; INPUTS:
;	ECX = len
;	EDX = Base address.
MEMD_generateOutput:
	push ecx
	xor ecx, ecx
	xor eax, eax
	mov edi, szMEMDOutput+10 ; +2 = end of first grouping's first byte. +8 for initial spacing

	mov cl, 16
 .genOut:
 	lodsb
	push esi
	mov esi, edi
	call UTILITY_BYTE_HEXtoASCII
	mov byte [edi+1], 0x20		; Insert separator space.
	pop esi

	mov al, cl
	dec al
	push ecx
	mov cl, 4
	div cl
	or ah, ah		; is the remainder 0?
	je .insertGap
   .back_insertGap:
	pop ecx

	xor ah, ah
	add edi, 3
	loop .genOut
	jmp .leaveCall

 .insertGap:
 	add edi, 4		; each additional space between columns = 4
	jmp .back_insertGap

 .leaveCall:
 	push esi
 	mov esi, szMEMDOutput
	mov bl, 0x07
	call _screenWrite
	pop esi
	pop ecx
	sub ecx, 16
	ret
