; PRIMITIVES.asm
; -- Primitive shape functions for drawing on video.


; INPUTS:
;	1: EBX = starting pixel.
;	2: ECX = final pixel.
;	3: EAX = border color.
; NO OUTPUTS. CF if error.
VIDEO_drawRectangle:
	FunctionSetup
	pushad
	mov dword ebx, [ebp+8]	; arg1: start pixel
	mov dword ecx, [ebp+12]	; arg2: end pixel

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

	MultiPush ebx,ecx
	and ebx, 0xFFFF0000
	and ecx, 0xFFFF0000
	shr ebx, 16
	shr ecx, 16
	; Set EDX = difference in Y values.
	mov edx, ecx
	sub edx, ebx		; EDX = dY ((endY-startY))
	cmp edx, 0			; Being double-sure everything is alright.
	jle .errorArgs
	MultiPop ecx,ebx

	; Get delta-X in ECX.
	and ecx, 0x0000FFFF
	and ebx, 0x0000FFFF
	sub ecx, ebx		;ECX = difference (delta-X)
	mov dword eax, [ebp+16]	; arg3: color
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
	MultiPop ecx,ebx
 .errorCoords:
	stc
 .leaveCall:
	popad
	FunctionLeave


; INPUTS:
;	1: EBX = starting pixel.
;	2: ECX = final pixel.    (x | [y<<16])
;	3: EAX = color. (after selectPixel)
; NO OUTPUTS. Carry set if error.
VIDEO_fillRectangle:
	FunctionSetup
	pushad

	xor edx, edx			; EDX = delta-Y
	mov dword ebx, [ebp+8]	;arg1 (start)
	mov dword ecx, [ebp+12]	;arg2 (end)

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

	MultiPush ebx,ecx
	and ebx, 0xFFFF0000
	and ecx, 0xFFFF0000
	shr ebx, 16
	shr ecx, 16
	; Set EDX = difference in Y values.
	mov edx, ecx
	sub edx, ebx		; EDX = dY ((endY-startY))
	cmp edx, 0			; Being double-sure everything is alright.
	jle .errorArgs
	MultiPop ecx,ebx

	; Get delta-X in ECX.
	and ecx, 0x0000FFFF
	and ebx, 0x0000FFFF
	sub ecx, ebx		;ECX = difference (delta-X)
	mov dword eax, [ebp+16]	;arg3 (color)
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
	MultiPush eax,ebx,edx
	; `--> have to save edx due to mul
	ZERO eax,ebx
	mov eax, ecx
	mov byte bl, [BYTES_PER_PIXEL]
	mul ebx
	sub edi, eax	; step backward by dX*BBP (go to beginning of new line)
	MultiPop edx,ebx,eax

	dec edx
	or edx, edx
	jz .doneDraw
	jmp .drawRect

 .doneDraw:
	clc
	jmp .leaveCall

 .errorArgs:
	stc
	MultiPop ecx,ebx
 .errorCoords:
	stc
 .leaveCall:
	popad
	FunctionLeave


; INPUTS:	(improve later to draw diagonal lines as well)
;	1: EBX = Starting Pixel.
;	2: ECX = Final Pixel.
;	3: EAX = Color.
; NO OUTPUTS. CF is error.
; Draw a line with any direction based on the start and the destination.
VIDEO_drawLine_B dd 0x00000000 ; y-intercept
VIDEO_drawLine_M dw 0x0000 ; slope
VIDEO_drawLine:
	FunctionSetup
	pushad
    clc
    mov edi, dword [SCREEN_FRAMEBUFFER_ADDR]
	mov dword ebx, [ebp+8]	;arg1: starting (y,x)
	mov dword ecx, [ebp+12]	;arg2: final (y,x)
	mov dword eax, [ebp+16]	;arg3: color
    mov dword [VIDEO_drawLine_B], 0x00000000
    mov word [VIDEO_drawLine_M], 0x0000

    ; Set EDI to point to the start of the line in the framebuffer.
    MultiPush eax,ebx
	push word bx	;XPOS
	shr ebx, 16
	push word bx	;YPOS
	call VIDEO_selectPixel ; EAX = offset.
	add esp, 4
    add edi, eax
    MultiPop ebx,eax

    ; RUNNING THE CHECK BELOW CUTS OF AN ENTIRE QUADRANT OF LINE DIRECTION
    ; Check the coordinates to verify the start & end points.
    ;call VIDEO_checkCoordinates
    ;jc .error

    ; y = mx + b
    ;  first thing to get is the slope of the equation using the delta.
    ;   -----> m = y2-y1 / x2-x1
    ; EDX = (dy<<16|dx)
    push ebx ; save EBX
    mov edx, ecx    ; edx = finalpos, DX = X2, BX = X1
    sub dx, bx      ; X2 - X1
    rol edx, 16     ; shift X to Y and Y to X
    rol ebx, 16     ; ^
    sub dx, bx      ; Y2 - Y1
    rol edx, 16     ; EDX now = (Y2-Y1 << 16|X2-X1)

    ;mov ebx, edx    ; copy the result into ebx
    ;MultiPush eax,edx
    ;ZERO eax,edx
    ;rol ebx, 16     ; BX now = Y2-Y1
    ;mov ax, bx      ; Set numerator to (Y2-Y1)
    ;rol ebx, 16     ; BX = (X2-X1)
    ;or bx, bx   ; DO NOT DIVIDE BY A ZERO
    ;jz .verticalLine
    ;idiv bx ; DX:AX div by BX ---> DX = remainder, AX = quotient
    ;MultiPop edx,eax
    pop ebx ; restore EBX

    ; b = y - [(y2-y1)*x]/(x2-x1)   --> Find B using the starting coordinates.
    MultiPush eax,ebx,ecx,edx
    mov ecx, edx    ; ECX = [(y2-y1)<<16|(x2-x1)]
    ZERO eax,edx
    rol ecx, 16 ; CX = (y2-y1)
    mov ax, bx  ; AX = X (start)
    imul cx ; DX = High WORD, AX = Low WORD
    rol ecx, 16 ; CX = (x2-x1)
    or cx, cx   ; DO NOT DIV BY ZERO
    jz .verticalLine
    idiv cx ; DX:AX div by CX --> AX = quotient, DX = remainder
    rol ebx, 16 ; BX = Y (start)
    mov dx, bx
    and eax, 0x0000FFFF
    sub edx, eax; EDX = Y - (mx)
    mov dword [VIDEO_drawLine_B], edx
    MultiPop edx,ecx,ebx,eax
    jmp .drawMe

 .verticalLine:
    MultiPop edx,ecx,ebx,eax

 .drawMe:
    jmp .leaveCall

 .error:
    stc
 .leaveCall:
	popad
	FunctionLeave
