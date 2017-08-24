; KEYBOARD.asm
; -- Orchid generic US keyboard driver.

KEYBOARD_DATA		equ 0x60
KEYBOARD_COMMAND	equ 0x64

ISR_keyboardHandler: ;AL = key return
	xor eax, eax
	xor ebx, ebx
	mov edi, 0x000B8000
	mov eax, [videoMemIndex]
	add edi, eax
	mov bx, [cursorOffset]

	mov dl, 1				; IRQ#1
	call PIC_sendEOI		; acknowledge the interrupt to PIC

	in al, KEYBOARD_COMMAND
	and al, 0001b
	jz ISR_keyboardHandler.noBuffer

	in al, KEYBOARD_DATA	; read key from buffer
	cmp al, 0
	jle ISR_keyboardHandler.noBuffer

	call _keyboardMapping	; set al to the proper key
	; KEY IS IN AL RIGHT HERE.
	mov byte [KEYBOARD_BUFFER], al

	cmp byte [currentMode], SHELL_MODE	; Shell mode?
	jne ISR_keyboardHandler.notShellMode
	cmp byte [KEYBOARD_DISABLE_OUTPUT], 0x01
	je ISR_keyboardHandler.notShellMode
	call _screenPrintChar	; print it or handle accordingly
 .notShellMode:
 .noBuffer:
	ret


; INPUTS:
;	BH = Command Byte
;	BL = Data byte, if applicable. If 0xFF, assuming no data byte is needed.
; CF on error.
KEYBOARD_sendSpecialCmd:
	push eax
	push ecx
	mov al, bh
	out KEYBOARD_DATA, al
	mov cl, 200
 	.bideTime: loop .bideTime

	in al, KEYBOARD_DATA
	cmp al, 0xFF
	je .error
	cmp al, 0x00
	je .error

 	cmp bl, 0xFF
	je .leaveCall
	mov al, bl
	out KEYBOARD_DATA, al
	jmp .leaveCall
 .error:
 	stc
 .leaveCall:
 	pop ecx
	pop eax
	ret

KEYBOARD_initialize:
	push ebx
	mov bh, 0xF0	;Get/Set current Scan Code cmd.
	mov bl, 0x01	; set scan code 2
	call KEYBOARD_sendSpecialCmd
	pop ebx
	ret


bKEYBOARDSTATUS		db 0x00		; keyboard status byte for shifts, capslock, etc.
; Bit 0 = Caps lock
; Bit 1 = SHIFT Status (1=on // 0=off)

%include "idt/keyboard/KEYMAP.asm"
