; MEMD.asm
; -- Dump memory to the command shell in SHELL_MODE only.
; ---- SYNTAX: MEMD start-physical-address length-of-read [ascii-dump]

szMEMDInfo		db "Dumping memory at physical address 0x00000000"
szMEMDAddr		db ", with offset 0x0000"
szMEMDOffset	db "...", 0
szMEMDOutput	times 79 db 0x20	; Actual output area.
				db 0
szMEMDSyntax	db "MEMD SYNTAX -> ARG1: 32-bit physical Address (hex) // ARG2: Length (max 0x100)", 0
szMEMDError		db "ARG2 ERROR: Input value is invalid (should be 1-100 in hex)!", 0
szMEMDError2	db "ARG1 ERROR: Number must be 32-bit hex; do not precede address by '0x'.", 0
szMEMDError3	db "ARG3 ERROR: Argument (if included) should be a number (0 or 1).", 0


COMMAND_MEMD:
	pushad
	xor ebx, ebx

	; guarantee required arguments.
	mov edi, PARSER_ARG1
	push edi
	cmp byte [edi], 0x00
	je .syntax
	mov edi, PARSER_ARG2
	cmp byte [edi], 0x00
	je .syntax
	; Arg3 does not matter (it's optional).
	;mov edi, PARSER_ARG3
	;cmp byte [edi], 0x00
	;je .syntax
	pop edi

	; Check arg1
	mov byte bl, [PARSER_ARG1_LENGTH]
	cmp bl, 8
	ja .err1
	mov esi, PARSER_ARG1
	call UTILITY_HEX_STRINGtoINT		; EAX = conversion.
	jc .err1
	mov edx, eax						; store into EDX

	; Check arg2
	mov byte bl, [PARSER_ARG2_LENGTH]
	cmp bl, 4
	ja .err2
	mov esi, PARSER_ARG2
	call UTILITY_HEX_STRINGtoINT		; EAX = conversion.
	jc .err2
	cmp eax, 0x100
	ja .err2
	mov ecx, eax						; Store into ECX

	; Check arg3
	mov byte bl, [PARSER_ARG3_LENGTH]
	cmp bl, 0	; no arg3? Skip these checks.
	je .arg3CheckOver
	mov esi, PARSER_ARG3
	call UTILITY_HEX_STRINGtoINT
	jc .err3
	cmp eax, 1
	jne .noASCIIOutput
	mov ebx, 0x00000001	 ; if arg3 = '1', set ASCII-DUMP flag to true
	jmp .arg3CheckOver
   .noASCIIOutput:
    xor ebx, ebx	; make sure EBX is 0.
	cmp eax, 0		; anything else but 0 is error.
	jne .err3
   .arg3CheckOver:

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

	push ebx
	; Output the information string.
	PrintString szMEMDInfo,0x02
	pop ebx

	; Get to work.
	mov esi, edx		; Set ESI = base addr.
   .doOutput:
	call MEMD_generateOutput
	cmp ecx, 0
	jle .leaveCall
	jmp .doOutput

 .err1:
	mov esi, szMEMDError2
	mov bl, 0x0C
	jmp .writeMSG
 .err2:
	mov esi, szMEMDError
	mov bl, 0x0C
	jmp .writeMSG
 .err3:
 	mov esi, szMEMDError3
	mov bl, 0x0C
	jmp .writeMSG
 .syntax:
 	pop edi
	mov bl, 0x09
	mov esi, szMEMDSyntax
 .writeMSG:
	call SCREEN_Write
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
;   EBX = 0x1 if ASCII dump.
MEMD_generateOutput:
	MultiPush ecx,ebx
	ZERO eax,ecx
	mov edi, szMEMDOutput+10 ; +2 = end of first grouping's first byte. +8 for initial spacing

	mov cl, 16
 .genOut:
	cmp ebx, 0x00000001	; If EBX = 1 (ASCII-DUMP)
	je .ASCIIDUMP		; goto ASCIIDUMP, else bleed & proceed normally.

   .notASCIIDUMP:
 	lodsb
	push esi
	mov esi, edi
	call UTILITY_BYTE_HEXtoASCII
	pop esi
	jmp .continue

   .ASCIIDUMP:	; As of now, supports any ASCII but 0 because 0 is indication of a null-termination.
	lodsb
	cmp al, 0
	je .ASCIIUnknown
	;cmp al, 32
	;jb .ASCIIUnknown
	jmp .ASCIIInsert
	.ASCIIUnknown:
	mov byte [edi], '*'
	jmp .continue
	.ASCIIInsert:
	mov byte [edi], al
	;bleed

 .continue:  ; this part of process works for both output types.
	mov byte [edi+1], 0x20		; Insert separator space.
	;pop esi

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
	PrintString szMEMDOutput,0x07
	MultiPop ebx,ecx
	sub ecx, 16
	ret
