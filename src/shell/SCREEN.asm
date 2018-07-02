; SCREEN.asm
; -- Contains all SHELL_MODE functions for controlling the user interface.


SCREEN_CLS:
	pushad
	mov edi, 0x000B80A0		; Only clear from row 1 and down, to not delete the overlay.
	mov ecx, 0x0F00
	mov eax, 0x0F200F20		;black bg, white fg -- spaces.
	rep stosd
	popad
	ret


SCREEN_Scroll:
	pushad
	xor eax, eax
	mov esi, 0xB8140; Start collecting data at row #2 (technically 3)
	mov edi, 0xB80A0; Place that data to the previous row
	mov ecx, 0x1040	; 160 chars per row, 26 rows (grabbing any overflows)
	rep movsb

	; Clear bottom row
	mov edi, 0x0B8000 + 0x0F00	; row 24, col 0
	mov ah, byte [DEFAULT_COLOR]
	mov al, 0x20
	rep stosw

	; Put cursor at pos 0,24
	mov bx, 0x0018	;column 0, row 24
	call SCREEN_UpdateCursor

	popad
	ret


; This function will update both the cursor and the video memory index based on cursor position
SCREEN_UpdateCursor:;BL = row, BH = column
	pushad
	mov word [SHELL_CURSOR_OFFSET], bx

	push ebx

	xor eax, eax
	xor cx, cx
	mov cl, bh		; cx = cols
	shl cx, 1		; cl x2
	movzx ax, bl	; al = rows
	mov dx, 0x00A0	; video mem row width
	mul dx			; ax = rows * row width
	add ax, cx		; ax = rows*width + cols

	mov word [SHELL_VIDEO_INDEX], ax

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

SCREEN_Write:	; (ARG1)ESI = string index, (ARG2)BL = color attrib
	pushad
	xor edx, edx
	mov edi, 0x0B8000
	movzx eax, word [SHELL_VIDEO_INDEX]
	movzx edx, word [SHELL_CURSOR_OFFSET]
	add edi, eax
	xor eax, eax
	mov ah, bl
	;Check SHELL_CURSOR_OFFSET real quick
	cmp dl, 25
	jl .continuePrint
	call SCREEN_Scroll
	movzx edx, word [SHELL_CURSOR_OFFSET]
 .continuePrint:
	lodsb
	or al, al
	jz .endPrint
	stosw
	inc dh		; next col
	cmp dh, 80	; end of line?
	jl .skipNextRow

	xor dh, dh	; reset cols
	inc dl		; next cursor row
	cmp dl, 25	; need to scroll?
	jl .skipNextRow
	call SCREEN_Scroll
	mov dl, 24		; set back to row 24 (0x18)

 .skipNextRow:
	jmp .continuePrint
 .endPrint:
	;end of printed line, so inc the row and reset column
	inc dl
	xor dh, dh
	cmp dl, 25
	jl .return
	call SCREEN_Scroll
	mov dl, 24
 .return:
	mov bx, dx
	call SCREEN_UpdateCursor
	popad
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This is mainly for printing user input.
; USER BUFFER = inputBuffer (255 chars/bytes --> 32 QWORDS) <-- HAVING TROUBLE WRITING THIS IN
; index = input index
SCREEN_PrintChar:	; ah = color attrib, al = char
	pushad
	mov ah, byte [SHELL_MODE_TEXT_COLOR]			; text attrib
	movzx ecx, word [SHELL_INPUT_INDEX]
	ZERO ebx,edx

	; set up video positioning
	mov bx, word [SHELL_CURSOR_OFFSET]
	mov edi, 0x000B8000
	movzx edx, word [SHELL_VIDEO_INDEX]
	add edi, edx

	; BACKSPACE is a priority request, as well as ENTER and ESCAPE.
	; ...meaning they ignore the inputBuffer index
	cmp al, 0x08	; al = BACKSPACE?
	je .backspace
	cmp al, 0x0A	; al = LF?
	je .nextLine
	cmp al, 0x1B	; al = ESC?
	je .escapeHit

	; Check index to see if we're already at max characters.
	cmp cx, 0x00FF	;255
	jge .return

	;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Special character check
	;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Disable arrows for now
	;cmp al, 0x0D
	;je .upArrow

	; Caps lock, or other special character below space??
	; ---> Later on extract important ones, like TAB and ESCAPE, etc. when needed.
	cmp al, 0x19
	jle .return

	;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Capitalized letter check.
	; Save state of EAX, store it in parser as a lowercase...
	; ... but make it display as whatever case it actually is.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push dword eax
	cmp al, 0x41	;'A'
	jl .notCaps
	cmp al, 0x5A 	;'Z'
	jg .notCaps
	; Letter is a capital letter.
	add al, 0x20	; 0x20 is the difference between caps and lowercase letters.
 .notCaps:

	; Handle the input buffer.
	mov byte [SHELL_INPUT_BUFFER+ecx], al

	pop dword eax
	stosw

	inc cx	; add to input index
	inc bh	; add to cursor xpos

	cmp bh, 80
	jl .return
	xor bh, bh
	inc bl
	cmp bl, 25
	jl .return
	mov bl, 24
	call SCREEN_Scroll
	jmp .return

 .escapeHit:
	; delete user input based on length of input index
	MultiPush ecx,eax
	shl ecx, 1	;ecx x2 --> set each char offset = attrib+char setting
	sub edi, ecx	;go backwards the amnt of chars in vid mem
	mov al, 0x20	;space
	mov ah, 0x0F	;write the default color for ESC presses.

	push edi	;save backwards pos
	rep stosw
	pop edi
	MultiPop eax,ecx

	; take cursor backwards.
	push ecx
 .escCursorSet:
	cmp ecx, 0		; index empty?? Could be user mashing ESC
	jz .escLoopEnd
	cmp bl, 1		; first row?
	jne .escNotFirstRow
	xor bh, bh		; reset cursor cols and keep row 1
	jmp .escLoopEnd
 .escNotFirstRow:
	cmp bh, 0		; 1st pos in cols?
	jne .escSkipColEnd	;no, go down
	mov bh, 0x4F	; yes, set to end of prev col
	dec bl			; and go a row up
	loop .escCursorSet
	jmp .escLoopEnd
 .escSkipColEnd:
	dec bh
	loop .escCursorSet
 .escLoopEnd:
	pop ecx
	xor cx, cx	; clear input index
	call PARSER_ClearInput
	jmp .return

 .backspace:
	cmp cx, 0	;no input buffer?
	je .return
	cmp bh, 0
	jnz .bkspNotEOC
	cmp bl, 1
	je .return
	dec bl
	mov bh, 0x50
	jmp .return
 .bkspNotEOC:
	dec bh
	mov al, 0x20	; space
	mov ah, 0x0F	; default color
	mov word [edi-2], ax
	dec cx		;decrease input index
	mov byte [SHELL_INPUT_BUFFER+ecx], 0x00	;kill the previous input
	jmp .return

 .nextLine:
	inc bl			; next row
	xor bh, bh		; cols = 0
	xor cx, cx		; clear input index
	cmp bl, 25
	jl .noScroll
	mov bl, 24
	call SCREEN_Scroll
 .noScroll:
	mov byte [SHELL_COMMAND_IN_QUEUE], TRUE		; tell the parser there's a command waiting.
	jmp .return

 .upArrow:
	; Display shadow buffer and memcpy it to input buffer
	; This is not happening until a better keyboard driver is implemented.
	;MEMCPY SHELL_SHADOW_BUFFER,SHELL_INPUT_BUFFER,0x100
	;MEMCPY SHELL_SHADOW_INDEX,SHELL_INPUT_INDEX,0x02
	jmp .leaveCall
 .return:
	mov word [SHELL_INPUT_INDEX], cx
   .leaveCall:
	call SCREEN_UpdateCursor
	popad
	ret


szScreenPause		db "Press any key to continue...", 0
SCREEN_Pause:
	cmp byte [SYSTEM_CURRENT_MODE], SHELL_MODE
	jne .leaveCall

	sti
	MultiPush esi,ebx
	PrintString szScreenPause,0x0D
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
	call TIMER_updateTimeDisplay
  .noTimerUpdate:
	;...
	jmp .waiting
 .breakWait:
 	mov byte [KEYBOARD_DISABLE_OUTPUT], 0x00
	mov byte [KEYBOARD_BUFFER], bl 		; restore original key in buffer.
	MultiPop ebx,esi
 .leaveCall:
	ret
