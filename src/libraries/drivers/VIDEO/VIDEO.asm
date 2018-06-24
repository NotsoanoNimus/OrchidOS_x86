; VIDEO.asm
; --- Very basic graphics driver for VBE/VESA modes.
; TODO: Implement layered buffering support for DWM hooks later on.

%include "libraries/drivers/VIDEO/core/FONT.asm"
%include "libraries/drivers/VIDEO/core/PIXEL_OPS.asm"

%include "libraries/drivers/VIDEO/core/draw/PRIMITIVES.asm"
%include "libraries/drivers/VIDEO/core/objects/WINDOW.asm"

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
	FunctionSetup
	pushad
	mov dword edi, [ebp+8]		;arg1: LFB double buffer addy
	mov dword eax, [ebp+12]		;arg2: color

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
	popad
	FunctionLeave


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
;	4: Vertical? (TRUE = 0x01 = vertical // FALSE = 0x00 = horizontal)
; NO OUTPUTS. CF is error.
VIDEO_drawLine:
	; FINISH LATER
	; FINISH LATER
	; FINISH LATER
	FunctionSetup
	pushad

	mov dword ebx, [ebp+8]	;arg1: starting (y,x)
	mov dword ecx, [ebp+12]	;arg2: final (y,x)

	mov dword eax, [ebp+16]	;arg3: color
	mov byte dl, [ebp+20]	;arg4: vertical (BOOL)

	popad
	FunctionLeave


; INPUTS:
;	EBX = start pixel
;	ECX = end pixel
; OUTPUTS:
;	EDX = delta-Y
;	CF on error.
; --- Check for erroneous input.
VIDEO_checkCoordinates:
	clc
	MultiPush ebx,ecx
	and ebx, 0x0000FFFF	;checking X values
	and ecx, 0x0000FFFF	; against each other.
	cmp ebx, ecx
	jge .errorArgs		; the start X cannot be >= the end X
	cmp bx, [SCREEN_WIDTH]
	jg .errorArgs
	cmp cx, [SCREEN_WIDTH]
	jg .errorArgs
	MultiPop ecx,ebx

	; testing Y values.
	MultiPush ebx,ecx
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
	MultiPop ecx,ebx
	jmp .leaveCall

 .errorArgs:
 	MultiPop ecx,ebx
	stc
 .leaveCall:
	ret




; INPUTS:
;   ARG1 = Location of start output.
;   ARG2 = Base Ptr of String
;   ARG3 = Foreground Color
;   ARG4 = Background Color
; -- Write a string of ASCII characters to the screen, given it is within the printable range (32d-126d)
; == DEPs:
; ==== VIDEO_OUTPUT_CHAR(Startpos, (uint32) index into MONOSPACE_FONT, fgColor, bgColor)
VIDEO_WRITE_STRING_CURRENT_CHARACTER_COORDS dd 0x00000000
VIDEO_WRITE_STRING:
    FunctionSetup
    pushad
    ZERO eax,ecx
    mov ebx, dword [ebp+8]      ; EBX = arg1 = starting coords (y<<16|x)
    mov esi, dword [ebp+12]  ; ESI = arg2 = base of string

 .getChars:
    lodsb   ; AL = byte [ESI]; ESI++
    or al, al   ; null-terminator?
    jz .leaveCall
    cmp al, 126 ; char > 126 ASCII?
    jg .unknownChar
    cmp al, 32  ; < 32 ASCII
    jl .unknownChar

    ; Check the coordinates for validity...
    push ecx ; save regs that get altered
    movzx ecx, word [SCREEN_HEIGHT]   ; Get screen height val
    shl ecx, 16 ; ECX high WORD = Max Y
    mov cx, word [SCREEN_WIDTH] ; Get screen width val
    call VIDEO_checkCoordinates ;(ECX = end coord, EBX = base coord [looking to check this mainly])
    jc .badCoord    ; if bad coord, leave
    pop ecx ;restore

	; THE BELOW LINE IS NOT NECESSARY.
    ;sub al, 32  ; chop off the char to get index into font table
    and eax, 0x000000FF     ; AL only.

	; %1 = coords, %2 = char, %3 = fgColor, %4 = bgColor
	func(VIDEO_OUTPUT_CHAR,ebx,eax,[ebp+16],[ebp+20])
    add bx, 8   ; add 8 pixels to the x coord.
    jmp .getChars

 .unknownChar:
    ; print ?
 .badCoord:
 .leaveCall:
    popad
    FunctionLeave



; INPUTS:
;   ARG1 = Start (top-left position) (Y<<16|X)
;   ARG2 = Character (index into MONOSPACE_FONT table)
;   ARG3 = Foreground Color
;   ARG4 = Background Color
; -- Draws a character based on foreground & background color.
; == DEPs:
; ==== VIDEO_putPixel; EBX = coord location, EAX = color of pixel
VIDEO_OUTPUT_CHAR_CURRENT_PIXEL_COORDS dd 0x00000000
VIDEO_OUTPUT_CHAR:
    FunctionSetup
    pushad

    mov edx, dword [ebp+8] ; arg1 - set starting point
    mov dword [VIDEO_OUTPUT_CHAR_CURRENT_PIXEL_COORDS], edx
    mov edx, dword [ebp+12] ; arg2 - which char
	sub edx, 0x20	; subtract 20 (since we're not outputting the first 0x20 ascii chars)
    shl edx, 4  ; EDX *= 16
    add edx, MONOSPACE_FONT ; add system font table base to get start of character bitmap
    mov esi, edx    ; ESI = 16-byte font character bitmap entry.

    ZERO eax,ebx,ecx,edx
 .getNextRow:
    lodsb       ; AL = [ESI], ESI++
    mov bl, 0x80    ; BL = 10000000b
    push ecx    ; save ECX (meta-loop counter)
    xor ecx, ecx    ; set it to 0 for sub-counting
 .drawRow:
    push eax    ; save AL
    push ebx    ; save BL
    and al, bl  ; and AL w/ BL. If AL comes out a 0, it's a background bit on the bitmap
    mov ebx, dword [VIDEO_OUTPUT_CHAR_CURRENT_PIXEL_COORDS] ; EBX = pixel coord

    or al, al
    jnz .foregroundColor

   .backgroundColor:
    mov eax, dword [ebp+20] ;EAX = arg4 - bg color
    jmp .drawPixel
   .foregroundColor:
    mov eax, dword [ebp+16] ;EAX = arg3 - fg color
   .drawPixel:
   	func(VIDEO_putPixel,ebx,eax)

    ; prepare for next iteration...
    pop ebx     ; restore ebx (BL)
    shr bl, 1   ; move to the next bit of the bitmap.
    mov eax, dword [VIDEO_OUTPUT_CHAR_CURRENT_PIXEL_COORDS]
    inc eax     ; add to the X coord
    mov dword [VIDEO_OUTPUT_CHAR_CURRENT_PIXEL_COORDS], eax ; put it back
    pop eax     ; restore AL
    inc ecx     ; increment counter
    cmp ecx, 8  ; check that whole byte of bitmap was checked/entered
    jae .doneRow    ; if count > 8, next row
    jmp .drawRow    ; else continue

 .doneRow:
    push eax ;save
    mov eax, dword [VIDEO_OUTPUT_CHAR_CURRENT_PIXEL_COORDS]
    sub eax, 8  ; go back 8 pixels in X direction
    add eax, 0x00010000 ; add 1 in the high WORD (Y coord)
    mov dword [VIDEO_OUTPUT_CHAR_CURRENT_PIXEL_COORDS], eax
    pop eax ;restore

    ; Retrieve and increment counter, check if it's run 16 times.
    pop ecx
    inc ecx
    cmp ecx, 16
    jae .leaveCall
    jmp .getNextRow

 .leaveCall:
    popad
    FunctionLeave
