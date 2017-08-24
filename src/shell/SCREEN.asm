; 32-BIT SCREEN OPERATIONS

%include "shell/GRAPHICS.asm"


_screenCLS:
	pushad
	mov edi, 0xB80A0
	;mov ecx, 0x03E8
	mov ecx, 0x0F00
	mov eax, 0x0F200F20
	rep stosd
	popad
	ret


_screenScroll:
	pushad

	xor eax, eax
	;mov esi, 0xB80A0; Start collecting data at row 2
	;mov edi, 0xB8000; Place that data to the previous row
	mov esi, 0xB8140; Start collecting data at row #2 (technically 3)
	mov edi, 0xB80A0; Place that data to the previous row
	mov ecx, 0x1040	; 160 chars per row, 26 rows (grabbing any overflows)
	;mov ecx, 0x0DC0		; 160 chars per row, 22 rows
 .repeatScroll:
	lodsb			; load BYTE from ESI
	stosb			; store it into EDI
	loop _screenScroll.repeatScroll		; repeat until ECX = 0

	; Clear bottom row
	mov edi, 0x0B8000 + 0x0F00	; row 24, col 0
	mov ah, [DEFAULT_COLOR]
	mov al, 0x20
	rep stosw
	;mov ecx, 0x28	;40 DWORDs (160)
	;mov eax, 0x0F200F20
	;rep stosd

	; Put cursor at pos 0,24
	mov bx, 0x0018	;column 0, row 24
	call _screenUpdateCursor

	popad
	ret


; This function will update both the cursor and the video memory index based on cursor position
_screenUpdateCursor:;BL = row, BH = column
	pushad
	mov word [cursorOffset], bx

	push ebx

	xor eax, eax
	xor cx, cx
	mov cl, bh		; cx = cols
	shl cx, 1		; cl x2
	movzx ax, bl	; al = rows
	mov dx, 0x00A0	; video mem row width
	mul dx			; ax = rows * row width
	add ax, cx		; ax = rows*width + cols

	mov word [videoMemIndex], ax

	pop ebx
	xor eax, eax

	mov ax, bx
	and ax, 0x00FF	; ax = rows
	mov cl, 80
	mul cl			; row * 80

	mov cx, bx
	shr cx, 8		; high byte to low (cl = bh = cols)
	add ax, cx		; add the rows onto cols
	mov cx, ax

	mov al, 0x0F	; Port outputs to VGA I/O
	mov dx, 0x03D4
	out dx, al

	mov ax, cx
	mov dx, 0x03D5
	out dx, al

	mov al, 0x0E
	mov dx, 0x03D4
	out dx, al

	mov ax, cx
	shr ax, 8
	mov dx, 0x03D5
	out dx, al

	popad
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_screenWrite:	; (ARG1)ESI = string index, EDX = [screenOffset], (ARG2)BL = color attrib
	pushad
	xor edx, edx
	mov edi, 0x0B8000
	mov eax, [videoMemIndex]
	mov edx, [cursorOffset]
	add edi, eax
	xor eax, eax
	mov ah, bl
	;Check cursorOffset real quick
	cmp dl, 25
	jl _screenWrite.continuePrint
	call _screenScroll
	mov edx, [cursorOffset]
 .continuePrint:
	lodsb
	or al, al
	jz _screenWrite.endPrint
	stosw
	inc dh		; next col
	cmp dh, 80	; end of line?
	jl _screenWrite.skipNextRow

	xor dh, dh	; reset cols
	inc dl		; next cursor row
	cmp dl, 25	; need to scroll?
	jl _screenWrite.skipNextRow
	call _screenScroll
	mov dl, 24		; set back to row 24 (0x18)

 .skipNextRow:
	jmp _screenWrite.continuePrint
 .endPrint:
	;end of printed line, so inc the row and reset column
	inc dl
	xor dh, dh
	cmp dl, 25
	jl _screenWrite.return
	call _screenScroll
	mov dl, 24
 .return:
	mov bx, dx
	call _screenUpdateCursor
	;mov word [cursorOffset], dx
	popad
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This is mainly for printing user input.
; USER BUFFER = inputBuffer (255 chars/bytes --> 32 QWORDS) <-- HAVING TROUBLE WRITING THIS IN
; index = inputIndex
_screenPrintChar:	; ah = color attrib, al = char
	pushad
	mov ah, [SHELL_MODE_TEXT_COLOR]			; text attrib
	mov cx, [inputIndex]
	and ecx, 0x0000FFFF		; keep only CX

	xor ebx, ebx
	xor edx, edx

	; set up video positioning
	mov bx, [cursorOffset]
	mov edi, 0x000B8000
	mov edx, [videoMemIndex]
	add edi, edx

	; BACKSPACE is a priority request, as well as ENTER and ESCAPE.
	; ...meaning they ignore the inputBuffer index
	cmp al, 0x08	; al = BACKSPACE?
	je _screenPrintChar.backspace
	cmp al, 0x0A	; al = LF?
	je _screenPrintChar.nextLine
	cmp al, 0x1B	; al = ESC?
	je _screenPrintChar.escapeHit

	; Check index to see if we're already at max characters.
	cmp cx, 0x00FF	;255
	jge _screenPrintChar.return

	;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Special character check
	;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Disable arrowsfor now
	cmp al, 0xA4
	je _screenPrintChar.return
	;je _screenPrintChar.upArrow
	cmp al, 0xA1
	je _screenPrintChar.return
	;je _screenPrintChar.downArrow
	cmp al, 0xA2
	je _screenPrintChar.return
	;je _screenPrintChar.leftArrow
	cmp al, 0xA3
	je _screenPrintChar.return
	;je _screenPrintChar.rightArrow

	; Caps lock, or other special character below space??
	; ---> Later on extract important ones, like TAB and ESCAPE, etc. when needed.
	cmp al, 0x19
	jle _screenPrintChar.return

	; Handle the input buffer.
	mov byte [KERNEL_OFFSET+inputBuffer+ecx], al

	stosw

	inc cx	; add to inputIndex
	inc bh	; add to cursor xpos
	;add edx, 2

	cmp bh, 80
	jl _screenPrintChar.return
	xor bh, bh
	inc bl
	cmp bl, 25
	jl _screenPrintChar.return
	mov bl, 24
	call _screenScroll
	jmp _screenPrintChar.return

 .escapeHit:
	; delete user input based on length of inputIndex
	push ecx
	;push edi
	push eax

	shl ecx, 1	;ecx x2 --> set each char offset = attrib+char setting
	sub edi, ecx	;go backwards the amnt of chars in vid mem
	mov al, 0x20	;space

	push edi	;save backwards pos
	rep stosw
	pop edi

	pop eax
	;pop edi
	pop ecx

	; take cursor backwards.
	push ecx
 .escCursorSet:
	cmp ecx, 0		; index empty?? Could be user mashing ESC
	jz _screenPrintChar.escLoopEnd
	cmp bl, 1		; first row?
	jne _screenPrintChar.escNotFirstRow
	xor bh, bh		; reset cursor cols and keep row 1
	jmp _screenPrintChar.escLoopEnd
 .escNotFirstRow:
	cmp bh, 0		; 1st pos in cols?
	jne _screenPrintChar.escSkipColEnd	;no, go down
	mov bh, 0x4F	; yes, set to end of prev col
	dec bl			; and go a row up
	loop _screenPrintChar.escCursorSet
	jmp _screenPrintChar.escLoopEnd
 .escSkipColEnd:
	dec bh
	loop _screenPrintChar.escCursorSet
 .escLoopEnd:
	pop ecx
	xor cx, cx	; clear inputIndex
	call _parserClearInput
	jmp _screenPrintChar.return

 .backspace:
	cmp cx, 0	;no input buffer?
	je _screenPrintChar.return
	cmp bh, 0
	jnz _screenPrintChar.bkspNotEOC
	cmp bl, 1
	je _screenPrintChar.return
	dec bl
	mov bh, 0x50
	jmp _screenPrintChar.return
 .bkspNotEOC:
	dec bh
	mov al, 0x20
	mov word [edi-2], ax
	dec cx		;decrease inputIndex
	mov byte [INPUT_BUFFER+ecx], 0x00	;kill the previous input
	jmp _screenPrintChar.return

 .nextLine:
	inc bl			; next row
	xor bh, bh		; cols = 0
	xor cx, cx		; clear inputIndex
	cmp bl, 25
	jl _screenPrintChar.noScroll
	mov bl, 24
	call _screenScroll
 .noScroll:
	;mov word [videoMemIndex], 0x0000	; clear the buffer
	mov byte [COMMAND_QUEUE], 00000001b		; tell the parser there's a command waiting.
	;call _screenClearInputBuffer
	jmp _screenPrintChar.return

 .downArrow:
	cmp bl, 25
	jge _screenPrintChar.return
	inc bl
	jmp _screenPrintChar.return
 .upArrow:
	cmp bl, 1
	jle _screenPrintChar.return
	dec bl
	jmp _screenPrintChar.return
 .leftArrow:
	cmp bh, 0
	jz _screenPrintChar.return
	dec bh		; decrement
	dec cx		; and the inputIndex position; this won't work for now, with the ESCAPE method...
	jmp _screenPrintChar.return
 .rightArrow:
	cmp bh, 80
	jge _screenPrintChar.return
	inc bh
	jmp _screenPrintChar.return

 .return:
	;mov word [videoMemIndex], dx
	mov word [inputIndex], cx
	call _screenUpdateCursor
	;mov word [cursorOffset], bx
	popad
	ret


szScreenPause		db "Press any key to continue...", 0
_screenPause:
	cmp byte [currentMode], SHELL_MODE
	jne .leaveCall

	push esi
	push ebx
	mov bl, 0x0D
	mov esi, szScreenPause
	call _screenWrite
	xor ebx, ebx
	mov byte bl, [KEYBOARD_BUFFER]		; Save key in buffer.
	mov byte [KEYBOARD_BUFFER], 0x00
	mov byte [KEYBOARD_DISABLE_OUTPUT], 0x01
 .waiting:
	hlt		; wait for interruption
	cmp byte [KEYBOARD_BUFFER], 0x00	; was there a change in the keyboard?
	jne .breakWait
	; Does the time need an update?
	mov dl, [SYSTEM_TIME_UPDATE]		; check timer update flags.
	and dl, 0x01						; check only bit 1
	cmp dl, 1
	jne .noTimerUpdate
	call _updateTimeDisplay
  .noTimerUpdate:
	;...
	jmp .waiting
 .breakWait:
 	mov byte [KEYBOARD_DISABLE_OUTPUT], 0x00
	mov byte [KEYBOARD_BUFFER], bl 		; restore original key in buffer.
	pop ebx
	pop esi
 .leaveCall:
	ret
