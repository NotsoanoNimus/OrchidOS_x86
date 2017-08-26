; UTILITY.asm
; -- Contains utility functions used across the system and kernel.


; INPUTS:
;	ESI = End of output buffer.
; 	EAX = DWORD number to convert.
; NO OUTPUTS.
; -- Outputs an ASCII representation of a hex value into the buffer specified.
; ---- This function will be consolidated eventually, in the same manner as UTILITY_HEX_STRINGtoINT.
UTILITY_DWORD_HEXtoASCII:
	cmp byte [currentMode], SHELL_MODE
	jne .leaveCall

	push esi
	push ecx
	push ebx
	push eax

	xor ebx, ebx
	mov ecx, 8		; always an 8-char output.
 .writeToBuffer:
	dec esi
	mov bl, al
	and al, 0x0F	; save low nibble
	cmp al, 0x09
	ja .hex1
	add al, 0x30
	jmp .notHex1
 .hex1:
	add al, 0x37
 .notHex1:
	mov byte [esi], al

	dec esi
	mov al, bl		; restore original byte
	shr al, 4
	cmp al, 0x09
	ja .hex2
	add al, 0x30
	jmp .notHex2
 .hex2:
	add al, 0x37
 .notHex2:
	mov byte [esi], al

	shr eax, 8
	sub ecx, 2		; two passes/bytes down.
	or ecx, ecx		; check if done
	jz .doneWrite
	jmp .writeToBuffer

 .doneWrite:
	pop eax
	pop ebx
	pop ecx
	pop esi
 .leaveCall:
	ret

; same args as above, except AX is the part that's output, NOT EAX!!
UTILITY_WORD_HEXtoASCII:
	cmp byte [currentMode], SHELL_MODE
	jne .leaveCall

	push esi
	push ecx
	push ebx
	push eax

	xor ebx, ebx
	mov ecx, 4		; always a 4-char output.
 .writeToBuffer:
	dec esi
	mov bl, al
	and al, 0x0F	; save low nibble
	cmp al, 0x09
	ja .hex1
	add al, 0x30
	jmp .notHex1
 .hex1:
	add al, 0x37
 .notHex1:
	mov byte [esi], al

	dec esi
	mov al, bl		; restore original byte
	shr al, 4
	cmp al, 0x09
	ja .hex2
	add al, 0x30
	jmp .notHex2
 .hex2:
	add al, 0x37
 .notHex2:
	mov byte [esi], al

	shr eax, 8
	sub ecx, 2		; two passes/bytes down.
	or ecx, ecx		; check if done
	jz .doneWrite
	jmp .writeToBuffer

 .doneWrite:
	pop eax
	pop ebx
	pop ecx
	pop esi
 .leaveCall:
	ret

; same args as above, except AL is the part that's output, NOT EAX!!
UTILITY_BYTE_HEXtoASCII:
	cmp byte [currentMode], SHELL_MODE
	jne .leaveCall

	push esi
	push ecx
	push ebx
	push eax

	xor ebx, ebx
	mov ecx, 2		; always a 2-char output.
 .writeToBuffer:
	dec esi
	mov bl, al
	and al, 0x0F	; save low nibble
	cmp al, 0x09
	ja .hex1
	add al, 0x30
	jmp .notHex1
 .hex1:
	add al, 0x37
 .notHex1:
	mov byte [esi], al

	dec esi
	mov al, bl		; restore original byte
	shr al, 4
	cmp al, 0x09
	ja .hex2
	add al, 0x30
	jmp .notHex2
 .hex2:
	add al, 0x37
 .notHex2:
	mov byte [esi], al

	shr eax, 8
	sub ecx, 2		; two passes/bytes down.
	or ecx, ecx		; check if done
	jz .doneWrite
	jmp .writeToBuffer

 .doneWrite:
	pop eax
	pop ebx
	pop ecx
	pop esi
 .leaveCall:
	ret


; INPUTS:
;	BL = ASCII representation of hex number.
; OUTPUTS:
; 	BL = converted.
; -- Converts an ASCII byte to its hex complement. CF if invalid ASCII code.
UTILITY_INTERNAL_convertASCIItoHEX:
	cmp bl, 0x39
	jbe .notHex
	cmp bl, 0x46
	jbe .uppercase
	cmp bl, 0x66
	jbe .lowercase
	jmp .error		; if it matched no prev parameters, it is OOB and is an error.

 .uppercase:	; already checked for digit versions, so if it's lower than the uppercase chars it's an error.
 	cmp bl, 0x41
	jb .error
	sub bl, 0x37
	jmp .leaveCall
 .lowercase:
 	cmp bl, 0x61
	jb .error
	sub bl, 0x57
	jmp .leaveCall
 .notHex:
 	cmp bl, 0x30
	jb .error
	sub bl, 0x30
	jmp .leaveCall

 .error:
 	xor bl, bl
 	stc
	ret
 .leaveCall:
 	clc
	ret


; INPUTS: (non-stack)
;	ESI = Start of string to interpret. Typically going to be a parser argument.
;	BL  = Magnitude of the number to extract, max of 08h for a whole DWORD in eax.
; OUTPUTS:
;	EAX = Converted number.
; -- Converts an ASCII string to a hex number. Sets EAX=0 and CF on error.
; --- This function scans the ASCII at ESI linearly (left-to-right), and does not account for endian-ness.
; --- The scan assumes that the start point is the highest power of 16 (e.g. BL=05h, ESI should start at X0000).
UTILITY_HEX_STRINGtoINT:
	push ebx
	push ecx
	push edx
	push esi
	and ebx, 0x000000FF
	xor ecx, ecx
	xor edx, edx
	xor eax, eax
	mov cl, bl		; CL = Digit count. Used for shifting results.
	dec cl			;  `--> has to be decremented so shifting works properly,
	mov al, 0x04
	mul cl			; AL = BL arg * 4
	mov cl, al		; CL = shifter. Decremented by four for every digit retrieved.
	xor eax, eax

	; A DWORD requests a scan of 8 bytes, WORD = 4, BYTE = 2. NIBBLE = 1. BL represents digits to fetch.
 .convert:
 	mov byte bl, [esi]
	call UTILITY_INTERNAL_convertASCIItoHEX		; set BL = hex #
	jc .error
	shl ebx, cl

	or eax, ebx		; enter EBX's result into EAX.
	inc esi
	cmp cl, 0
	jle .leaveCall
	sub cl, 4
	xor ebx, ebx
	jmp .convert

 .error:
 	stc
	jmp .return
 .leaveCall:
 	clc
 .return:
 	pop esi
 	pop edx
 	pop ecx
 	pop ebx
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; INPUTS:
;	ARG1: AX = error code. (LOW WORD OF DWORD FROM STACK)
; NO OUTPUTS.
; -- System Blue-Screen-Of-Death. Bad crash. :(  Goes back to Real Mode to display crash message.
; ---- This will be JMPed to (NOT CALLED) on irrecoverable IDT software IRQs & crashes.
iBSODErrASCII	dd 0x00000000
				dd 0x00000000
SYSTEM_BSOD:
	; Mask everything...
	mov al, 0xFF
	out PIC1_DATA, al
	mov al, 0xFF
	out PIC2_DATA, al

	mov dword eax, [esp]		; Get the pushed error code.
	mov esi, SYSTEM_BSOD_ERROR_CODE+8	; Map it to the memory at the end of ST2.
	call UTILITY_DWORD_HEXtoASCII

	;Regress to Real Mode. No need to save CR0 since the computer has crashed.
	cli

	; Re-map PIC.
	mov bh, 0x08	; Master vector offset
	mov bl, 0x70	; Slave vector offset
	call PIC_remap

	; Unmask everything...
	mov al, 0x00
	out PIC1_DATA, al
	mov al, 0x00
	out PIC2_DATA, al

	jmp REAL_MODE_CODE_SELECTOR:SYSTEM_BSOD_beginRMSwitch
	hlt

[BITS 16]
SYSTEM_BSOD_beginRMSwitch:
	mov eax, REAL_MODE_DATA_SELECTOR
	mov ds, eax
	mov es, eax
	mov fs, eax
	mov gs, eax
	mov ss, eax

	; Disable Protected Mode (and paging, just in case it's implemented later)
	mov eax, cr0
	and eax, 0x7FFFFFFE		; Turn off bit 31 (Paging) and bit 0 (ProtMode)
	mov cr0, eax

	;[BITS 16]
	jmp 0x0000:SYSTEM_BSOD_FUNCTION		;SYSTEM_BSOD_FUNCTION code located at end of ST2!!
	;jmp REAL_MODE_CODE_SELECTOR:SYSTEM_BSOD_enterRealMode
