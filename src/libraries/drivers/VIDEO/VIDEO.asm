; VIDEO.asm
; --- Very basic graphics driver for VBE/VESA modes.
; TODO: Implement layered buffering support for DWM hooks later on.

%include "libraries/drivers/VIDEO/FONT.asm"

; NO INPUTS.
; NO OUTPUTS. CF on error.
; -- Pushes the double buffer into the LFB (to display the update).
VIDEO_pushBuffer:
	pushad
	clc

	; Clear
	;xor eax, eax
	;mov edi, [DOUBLE_LFB_BUFFER]


	popad
	ret


; INPUTS:
;	1: EDI = LFB starting address.
;	2: EAX = Color.
; NO OUTPUTS.
VIDEO_clearDesktop:
	pushad			; 32 bytes.
	push ebp		; 4 bytes.
	mov ebp, esp
	mov dword edi, [ebp + 40]		;arg1: LFB double buffer addy
	mov dword eax, [ebp + 44]		;arg2: color

	mov ecx, [SCREEN_PIXEL_COUNT]
	xor edx, edx
	mov byte dl, [BYTES_PER_PIXEL]
 .putPixel:
	mov DWORD [edi], eax
	add edi, edx

	dec ecx
	or ecx, ecx
	jz .leaveCall
	jmp .putPixel

 .leaveCall:
	pop ebp
	popad
	ret


; INPUTS:
;	1: EBX = (x | y<<16) location
;	2: LFB address !OFFSET!.
;	3: Pixel color.
; NO OUTPUTS. CF if error.
; -- Same as putPixel, but the LFB OFFSET is already calculated.
VIDEO_putPixel_noCalc:
	pushad
	push ebp
	mov ebp, esp

	pop ebp
	popad
	ret


; INPUTS:
;	1: EBX, 0-15 = xpos // 16-31 = ypos
;	2: EAX = color.
; NO OUTPUTS. CF if OOB or failure otherwise.
; -- Paints a pixel the given color.
VIDEO_putPixel:
	pushad			; 32
	push ebp		; 4 (+4 EIP)
	mov ebp, esp

	mov dword ebx, [ebp + 40]	; arg1 (Y,X)

	push word bx	; XPOS
	shr ebx, 16
	push word bx	; YPOS
	call VIDEO_selectPixel		; EAX = pixel's linear address.
	add esp, 4

	mov dword edi, [SCREEN_FRAMEBUFFER_ADDR]		; Should change to buffer 2? Probably not for the simple put operation.
	add edi, eax

	mov dword eax, [ebp + 44]	; arg2 (Color)
	mov dword [edi], eax

	pop ebp
	popad
	ret


; INPUTS:
;	1: YPOS word
;	2: XPOS word
; OUTPUTS:
;	EAX = Offset from LFB_BASE, linear address of pixel.
; +- Calculates a pixel's linear address based on an X,Y input.
; `---> FORMULA: pixelOffset (from LFB_BASE) = y*pitch + (x*(bpp/8))
VIDEO_selectPixel:
	push ebx		;4
	push ecx		;4
	push edx		;4
	push ebp		;4 +4EIP
	mov ebp, esp

	;mov dword ebx, [ebp + 20]
	xor edx, edx 	; clear EDX for 32-bit MUL instructions.
	xor ebx, ebx
	xor eax, eax
	xor ecx, ecx

	mov word ax, [ebp + 20]		; EAX = xpos
	mov word bx, [ebp + 22]		; EBX = ypos

	mov word cx, [SCREEN_PITCH]
	mul ecx			; EAX = (Y * PITCH)
	push eax		; save

	xor ecx, ecx
	xor eax, eax
	mov byte cl, [BYTES_PER_PIXEL]
	mov ax, bx		; EAX = X
	mul ecx			;  * (BPP/8)

	mov ebx, eax	; EBX = [X*(BPP/8)]
	pop eax			; restore EAX (Y*PITCH)
	add eax, ebx	; add them. EAX = (Y*PITCH) + [X*(BPP/8)].

	pop ebp
	pop edx
	pop ecx
	pop ebx
	ret


; INPUTS:
;	1: EBX = starting pixel.
;	2: ECX = final pixel.
;	3: EAX = border color.
; NO OUTPUTS. CF if error.
VIDEO_drawRectangle:
	pushad
	push ebp
	mov ebp, esp

	mov dword ebx, [ebp + 40]	; arg1: start pixel
	mov dword ecx, [ebp + 44]	; arg2: end pixel

	push ebx
	push word bx
	shr ebx, 16
	push word bx
	call VIDEO_selectPixel
	add esp, 4
	pop ebx

	mov dword edi, [SCREEN_FRAMEBUFFER_ADDR]
	add edi, eax			; edi is ready to paint.

	call VIDEO_checkCoordinates
	jc .errorCoords

	push ebx
	push ecx
	and ebx, 0xFFFF0000
	and ecx, 0xFFFF0000
	shr ebx, 16
	shr ecx, 16
	; Set EDX = difference in Y values.
	mov edx, ecx
	sub edx, ebx		; EDX = dY ((endY-startY))
	cmp edx, 0			; Being double-sure everything is alright.
	jle .errorArgs
	pop ecx
	pop ebx

	; Get delta-X in ECX.
	and ecx, 0x0000FFFF
	and ebx, 0x0000FFFF
	sub ecx, ebx		;ECX = difference (delta-X)
	mov dword eax, [ebp + 48]	; arg3: color
	mov dword ebx, [SCREEN_PITCH]
	and ebx, 0x0000FFFF		; EBX = SCREEN_PITCH, trimmed.
 .drawRect:
	push ecx	;save dX
	push edi	;save rectangle base pixel.
	; draw top horizontal line
  .horizTop:
	mov dword [edi], eax
	add edi, [BYTES_PER_PIXEL]
	loop .horizTop

	; chop off the extra added BPP
	sub edi, [BYTES_PER_PIXEL]
	;push edx 	;save dY
	mov ecx, edx
  .vertRight:
	mov dword [edi], eax
	add edi, ebx
	loop .vertRight

	; chop off extra pitch addition...
	sub edi, ebx
	pop edi		;restore edi to base
	mov ecx, edx	;doing vertLeft, need dY
  .vertLeft:
	mov dword [edi], eax
	add edi, ebx
	loop .vertLeft

	; chopping
	sub edi, ebx
	pop ecx 	;restore original dX
  .horizBot:
	mov dword [edi], eax
	add edi, [BYTES_PER_PIXEL]
	loop .horizBot


	jmp .leaveCall

 .errorArgs:
	stc
	pop ecx
	pop ebx
 .errorCoords:
	stc
 .leaveCall:
	pop ebp
	popad
	ret


; INPUTS:
;	1: EBX = starting pixel.
;	2: ECX = final pixel.    (x | [y<<16])
;	3: EAX = color. (after selectPixel)
; NO OUTPUTS. Carry set if error.
VIDEO_fillRectangle:
	pushad
	push ebp
	mov ebp, esp

	xor edx, edx				; EDX = delta-Y
	mov dword ebx, [ebp + 40]	;arg1 (start)
	mov dword ecx, [ebp + 44]	;arg2 (end)

	push ebx
	push word bx	;XPOS
	shr ebx, 16
	push word bx	;YPOS
	call VIDEO_selectPixel		; only calculate the offset once. (Thanks, Omar!)
	add esp, 4
	pop ebx

	mov dword edi, [SCREEN_FRAMEBUFFER_ADDR]
	add edi, eax		; edi pointing to the start space, let's go!

	call VIDEO_checkCoordinates
	jc .errorCoords

	push ebx
	push ecx
	and ebx, 0xFFFF0000
	and ecx, 0xFFFF0000
	shr ebx, 16
	shr ecx, 16
	; Set EDX = difference in Y values.
	mov edx, ecx
	sub edx, ebx		; EDX = dY ((endY-startY))
	cmp edx, 0			; Being double-sure everything is alright.
	jle .errorArgs
	pop ecx
	pop ebx

	; Get delta-X in ECX.
	and ecx, 0x0000FFFF
	and ebx, 0x0000FFFF
	sub ecx, ebx		;ECX = difference (delta-X)
	mov dword eax, [ebp + 48]	;arg3 (color)
 .drawRect:
	; ECX = dX here
	push ecx
  .subDrawLoop:
	mov dword [edi], eax
	add edi, [BYTES_PER_PIXEL]
	loop .subDrawLoop
	; Move EDI down a whole line (using PITCH).
	mov ecx, [SCREEN_PITCH]
	and ecx, 0x0000FFFF
	add edi, ecx
	; Get dX back.
	pop ecx

	; Basically CR/LF the drawing.
	push eax
	push ebx
	push edx		; have to save edx due to mul
	xor eax, eax
	xor ebx, ebx

	mov eax, ecx
	mov byte bl, [BYTES_PER_PIXEL]
	mul ebx
	sub edi, eax	; step backward by dX*BBP (go to beginning of new line)

	pop edx
	pop ebx
	pop eax

	dec edx
	or edx, edx
	jz .doneDraw
	jmp .drawRect

 .doneDraw:
	clc
	jmp .leaveCall

 .errorArgs:
	stc
	pop ecx
	pop ebx		;preserve the stack. No crashing.
 .errorCoords:
	stc
 .leaveCall:
	pop ebp
	popad
	ret


; INPUTS:	(improve later to draw diagonal lines as well)
;	1: EBX = Starting Pixel.
;	2: ECX = Final Pixel.
;	3: EAX = Color.
;	4: Vertical? (TRUE = 0x01 = vertical // FALSE = 0x00 = horizontal)
; NO OUTPUTS. CF is error.
VIDEO_drawLine:
	; FINISH LATER
	; FINISH LATER
	; FINISH LATER

	pushad			;32
	push ebp		;4 (+4EIP)
	mov ebp, esp

	mov dword ebx, [ebp + 40]	;arg1: starting (y,x)
	mov dword ecx, [ebp + 44]	;arg2: final (y,x)

	mov dword eax, [ebp + 48]	;arg3: color
	mov byte dl, [ebp + 52]		;arg4: vertical (BOOL)

	pop ebp
	popad
	ret


; INPUTS:
;	EBX = start pixel
;	ECX = end pixel
; OUTPUTS:
;	EDX = delta-Y
;	CF on error.
; --- Check for erroneous input.
VIDEO_checkCoordinates:
	clc
	push ebx
	push ecx
	and ebx, 0x0000FFFF	;checking X values
	and ecx, 0x0000FFFF	; against each other.
	cmp ebx, ecx
	jge .errorArgs		; the start X cannot be >= the end X
	cmp bx, [SCREEN_WIDTH]
	jg .errorArgs
	cmp cx, [SCREEN_WIDTH]
	jg .errorArgs
	pop ecx
	pop ebx

	; testing Y values.
	push ebx
	push ecx
	and ebx, 0xFFFF0000
	and ecx, 0xFFFF0000
	shr ebx, 16
	shr ecx, 16
	cmp ebx, ecx
	jge .errorArgs		; the start Y cannot be >= the end X
	cmp bx, [SCREEN_HEIGHT]
	jg .errorArgs
	cmp cx, [SCREEN_HEIGHT]
	jg .errorArgs
	; Set EDX = difference in Y values.
	mov edx, ecx
	sub edx, ebx		; EDX = dY ((endY-startY))
	cmp edx, 0			; Being double-sure everything is alright.
	jle .errorArgs
	pop ecx
	pop ebx
	jmp .leaveCall

 .errorArgs:
	pop ecx
	pop ebx
	stc
 .leaveCall:
	ret
