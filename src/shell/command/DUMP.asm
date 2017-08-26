; DUMP.asm
; -- Dump the contents of the registers, segments, and indices.
szOutputStart			db "Current register/segment/index states:", 0
szDUMPOutput1			db "      xxx: 0x00000000"
szDUMPOutput2			db "      xxx: 0x00000000"
szDUMPOutput3			db "      xxx: 0x00000000", 0
dd 0x0

; Can get all ASCII reps except EAX's & ESI's.
%macro GetASCIIFromReg 3
 .GetASCII%1:
 	mov eax, %1
	mov esi, szDUMPOutput%2+21			; +21 = End of buffer for each line.
	call UTILITY_DWORD_HEXtoASCII	; EAX = conversion.
	mov esi, szDUMPOutput%2+1			; base +spacers
    mov dword [esi], "    "
	mov dword [esi+4], %3
	mov dword [esi+8], ": 0x"		; needed JIC buffers get cleared...
%endmacro

; INPUTS:
;	ARG1 = buffer#
DUMP_cleanOutputBuffers:
	push ebp
	push eax
	push ebx
	push ecx
	push edi
	mov ebp, esp

	xor ebx, ebx
	xor eax, eax
	xor ecx, ecx
	mov al, 0x20	; " " char to place in buffer(s).
	mov dword ebx, [ebp+24]	;arg1
	; only buffers 2&3 should ever need to be cleaned. When #2 is req, #3 will be cleaned automatically with it.
	cmp ebx, 0x00000002
	je .clear2
	cmp ebx, 0x00000003
	je .clear3
	jmp .leaveCall

 .clear2:
 	mov cl, 21		; 21 chars in each buffer.
	mov edi, szDUMPOutput2
	rep stosb
 .clear3:
 	mov cl, 21		; 21 chars in each buffer.
	mov edi, szDUMPOutput3
	rep stosb
 .leaveCall:
	pop edi
	pop ecx
	pop ebx
	pop eax
	pop ebp
	ret


; self-explanatory. BL (color) set externally before call.
DUMP_outputString:
	mov esi, szDUMPOutput1
	call _screenWrite
	ret



_commandDUMP:
	pushad
	pushf

	push esi

	push ebx
	mov bl, 0x0D
	mov esi, szOutputStart
	call _screenWrite
	pop ebx

	; EAX.
	mov esi, szDUMPOutput1+21
	call UTILITY_DWORD_HEXtoASCII
	mov esi, szDUMPOutput1+1
    mov dword [esi], "    "
	mov dword [esi+4], " EAX"
	GetASCIIFromReg EBX,2," EBX"
	GetASCIIFromReg ECX,3," ECX"
	; Print EAX/EBX/ECX
	mov bl, 0x0D
	call DUMP_outputString

	GetASCIIFromReg EDX,1," EDX"
	pop esi
	mov eax, esi
	mov esi, szDUMPOutput2+21
	call UTILITY_DWORD_HEXtoASCII
	mov esi, szDUMPOutput2+1
    mov dword [esi], "    "
	mov dword [esi+4], " ESI"
	GetASCIIFromReg EDI,3," EDI"
	; Print EDX/ESI/EDI
	call DUMP_outputString

	GetASCIIFromReg EBP,1," EBP"
	GetASCIIFromReg ESP,2," ESP"
	push dword 0x00000003	; clean buffer 3 only.
	call DUMP_cleanOutputBuffers
	add esp, 4
	; Print EBP/ESP/---
	mov bl, 0x0C
	call DUMP_outputString

	GetASCIIFromReg CS,1,"  CS"
	GetASCIIFromReg DS,2,"  DS"
	GetASCIIFromReg ES,3,"  ES"
	; Print CS/DS/ES
	mov bl, 0x0E
	call DUMP_outputString

	GetASCIIFromReg FS,1,"  FS"
	GetASCIIFromReg GS,2,"  GS"
	GetASCIIFromReg SS,3,"  SS"
	; Print FS/GS/SS
	call DUMP_outputString

	pop eax		; EAX = EFLAGS "original"
	mov esi, szDUMPOutput1+21
	call UTILITY_DWORD_HEXtoASCII
	mov esi, szDUMPOutput1+1
	mov dword [esi], "  EF"
	add esi, 4
	mov dword [esi], "LAGS"
	push dword 0x00000002	;clean other buffers.
	call DUMP_cleanOutputBuffers
	add esp, 4
	; Print EFLAGS.
	mov bl, 0x09
	call DUMP_outputString


	popad
	ret
