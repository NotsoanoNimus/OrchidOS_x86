;KEYMAP.asm

; Will take (1) input code and (2) desired output code
; ---Maps keycodes to their ascii equivalents.
%macro KeyMap 2
	cmp al, %1
	jne _keyboardMapping.not%1
	mov al, %2
	jmp _keyboardMapping.return
 .not%1:
%endmacro

%macro CKeyMap 2
	cmp al, %1
	jne _keyboardMapping.capsnot%1
	mov al, %2
	jmp _keyboardMapping.return
 .capsnot%1:
%endmacro

; ARG -> #1: al = keycode
_keyboardMapping:	; start with actual key chars first, special chars last
	push ebx

	cmp al, 0xF0	;LSHIFT released
	jne _keyboardMapping.not0xF0
	in al, KEYBOARD_DATA	; read key from buffer
	cmp al, 0x2A
	jne .not0xF0
	and byte [bKEYBOARDSTATUS], 11111101b	;clear bit 1
	jmp _keyboardMapping.returnShift
 .not0xF0:
; 	cmp al, 0xB6
;	jne _keyboardMapping.not0xB6
;	mov al, 0x15	; Same code as RSHIFT press, but this will toggle the bShiftOn off
;	and byte [bKEYBOARDSTATUS], 11111101b		;clear bit 2
;	jmp _keyboardMapping.return
; .not0xB6:

	; LEFT SHIFT
	cmp al, 0x2A
	jne _keyboardMapping.not0x2A
	mov al, 0x14
	xor byte [bKEYBOARDSTATUS], 00000010b	;set ShiftOn status
	jmp _keyboardMapping.returnShift
 .not0x2A:
	; RIGHT SHIFT
	cmp al, 0x36
	jne _keyboardMapping.not0x36
	mov al, 0x15
	xor byte [bKEYBOARDSTATUS], 00000010b	;set ShiftOn status
	jmp _keyboardMapping.returnShift
 .not0x36:
	;Caps Lock, toggle the boolean
	cmp al, 0x3A		; Caps
	jne _keyboardMapping.not0x3A
	xor byte [bKEYBOARDSTATUS], 00000001b		;toggle capslock
	mov al, 0x11		; caps lock indicator
	jmp _keyboardMapping.returnCaps
 .not0x3A:
	KeyMap 0x01,0x1B	; ESC
	KeyMap 0x0E,0x08	; 'BACKSPACE'
	KeyMap 0x1D,0x12	; 'LEFT CTRL'
	KeyMap 0x38,0x16	; 'LEFT ALT'
	KeyMap 0x39,0x20	; 'SPACE'
	KeyMap 0x3B,0x01	; 'F1'
	KeyMap 0x3C,0x02	; 'F2'
	KeyMap 0x3D,0x03	; 'F3'
	KeyMap 0x3E,0x04	; 'F4'
	KeyMap 0x3F,0x05	; 'F5'
	KeyMap 0x40,0x06	; 'F6'
	KeyMap 0x41,0x07	; 'F7'
	KeyMap 0x42,0x08	; 'F8'
	KeyMap 0x43,0x09	; 'F9'
	KeyMap 0x44,0x10	; 'F10
	KeyMap 0x45,0x00	; 'NUMLOCK'
	KeyMap 0x46,0x00	; 'SCROLL LOCK'
	KeyMap 0x1C,0x0A	; 'ENTER'
	KeyMap 0x0F,0x09	; 'TAB'
	KeyMap 0x37,0x2A	; '* NUMPAD'
	; NUMPAD characters disabled for now. Using the evens for cursor movement.
	KeyMap 0x47,0x37	; '7 NUMPAD'
	KeyMap 0x48,0xA4	; '8 NUMPAD' --> UP ARROW
	KeyMap 0x49,0x39	; '9 NUMPAD'
	KeyMap 0x4A,0x2D	; '- NUMPAD'
	KeyMap 0x4B,0xA2	; '4 NUMPAD' --> LEFT ARROW
	KeyMap 0x4C,0x35	; '5 NUMPAD'
	KeyMap 0x4D,0xA3	; '6 NUMPAD' --> RIGHT ARROW
	KeyMap 0x4E,0x2B	; '+ NUMPAD'
	KeyMap 0x4F,0x31	; '1 NUMPAD'
	KeyMap 0x50,0xA1	; '2 NUMPAD' --> DOWN ARROW
	KeyMap 0x51,0x33	; '3 NUMPAD'
	KeyMap 0x52,0x30	; '0 NUMPAD'
	KeyMap 0x53,0x2E	; '. NUMPAD'
	KeyMap 0x57,0x18	; 'F11'
	KeyMap 0x58,0x19	; 'F12'

	mov byte bl, [bKEYBOARDSTATUS]
	and bl, 00000010b	;Checking L/RSHIFT
	or bl, bl
	jnz .shiftSet

	KeyMap 0x02,0x31	; '1'
	KeyMap 0x03,0x32	; '2'
	KeyMap 0x04,0x33	; '3'
	KeyMap 0x05,0x34	; '4'
	KeyMap 0x06,0x35	; '5'
	KeyMap 0x07,0x36	; '6'
	KeyMap 0x08,0x37	; '7'
	KeyMap 0x09,0x38	; '8'
	KeyMap 0x0A,0x39	; '9'
	KeyMap 0x0B,0x30	; '0'
	KeyMap 0x0C,0x2D	; '-'
	KeyMap 0x0D,0x3D	; '='
	KeyMap 0x1A,0x5B	; '['
	KeyMap 0x1B,0x5D	; ']'
	KeyMap 0x27,0x3B	; ';'
	KeyMap 0x28,0x27	; '''
	KeyMap 0x29,0x60	; '`'
	KeyMap 0x2B,0x5C	; '\'
	KeyMap 0x33,0x2C	; ','
	KeyMap 0x34,0x2E	; '.'
	KeyMap 0x35,0x2F	; '/'

	; Check capslock status here, otherwise it is a waste.
	xor ebx, ebx
	mov bl, [bKEYBOARDSTATUS]
	and bl, 00000011b		; is either shift or capslock set?
	cmp bl, 00000000b
	jne _keyboardMapping.capsOn

	KeyMap 0x10,0x71	; 'q'
	KeyMap 0x11,0x77	; 'w'
	KeyMap 0x12,0x65	; 'e'
	KeyMap 0x13,0x72	; 'r'
	KeyMap 0x14,0x74	; 't'
	KeyMap 0x15,0x79	; 'y'
	KeyMap 0x16,0x75	; 'u'
	KeyMap 0x17,0x69	; 'i'
	KeyMap 0x18,0x6F	; 'o'
	KeyMap 0x19,0x70	; 'p'
	KeyMap 0x1E,0x61	; 'a'
	KeyMap 0x1F,0x73	; 's'
	KeyMap 0x20,0x64	; 'd'
	KeyMap 0x21,0x66	; 'f'
	KeyMap 0x22,0x67	; 'g'
	KeyMap 0x23,0x68	; 'h'
	KeyMap 0x24,0x6A	; 'j'
	KeyMap 0x25,0x6B	; 'k'
	KeyMap 0x26,0x6C	; 'l'
	KeyMap 0x2C,0x7A	; 'z'
	KeyMap 0x2D,0x78	; 'x'
	KeyMap 0x2E,0x63	; 'c'
	KeyMap 0x2F,0x76	; 'v'
	KeyMap 0x30,0x62	; 'b'
	KeyMap 0x31,0x6E	; 'n'
	KeyMap 0x32,0x6D	; 'm'
	; This is in case the keycode isn't recognized.
	xor al, al
	jmp _keyboardMapping.return

	; Caps lock characters
 .capsOn:
 .shiftSet:
	CKeyMap 0x10,0x51	; 'Q'
	CKeyMap 0x11,0x57	; 'W'
	CKeyMap 0x12,0x45	; 'E'
	CKeyMap 0x13,0x52	; 'R'
	CKeyMap 0x14,0x54	; 'T'
	CKeyMap 0x15,0x59	; 'Y'
	CKeyMap 0x16,0x55	; 'U'
	CKeyMap 0x17,0x49	; 'I'
	CKeyMap 0x18,0x4F	; 'O'
	CKeyMap 0x19,0x50	; 'P'
	CKeyMap 0x1E,0x41	; 'A'
	CKeyMap 0x1F,0x53	; 'S'
	CKeyMap 0x20,0x44	; 'D'
	CKeyMap 0x21,0x46	; 'F'
	CKeyMap 0x22,0x47	; 'G'
	CKeyMap 0x23,0x48	; 'H'
	CKeyMap 0x24,0x4A	; 'J'
	CKeyMap 0x25,0x4B	; 'K'
	CKeyMap 0x26,0x4C	; 'L'
	CKeyMap 0x2C,0x5A	; 'Z'
	CKeyMap 0x2D,0x58	; 'X'
	CKeyMap 0x2E,0x43	; 'C'
	CKeyMap 0x2F,0x56	; 'V'
	CKeyMap 0x30,0x42	; 'B'
	CKeyMap 0x31,0x4E	; 'N'
	CKeyMap 0x32,0x4D	; 'M'
	CKeyMap 0x28,0x22	; '"'
	CKeyMap 0x02,0x21	; '!'
	CKeyMap 0x03,0x40	; '@'
	CKeyMap 0x04,0x23	; '#'
	CKeyMap 0x05,0x24	; '$'
	CKeyMap 0x06,0x25	; '%'
	CKeyMap 0x07,0x5E	; '^'
	CKeyMap 0x08,0x26	; '&'
	CKeyMap 0x09,0x2A	; '*'
	CKeyMap 0x0A,0x28	; '('
	CKeyMap 0x0B,0x29	; ')'
	CKeyMap 0x0C,0x5F	; '_'
	CKeyMap 0x0D,0x2B	; '+'
	CKeyMap 0x1A,0x7B	; '{'
	CKeyMap 0x1B,0x7D	; '}'
	CKeyMap 0x27,0x3A	; ':'
	CKeyMap 0x29,0x7E	; '~'
	CKeyMap 0x2B,0x7C	; '|'
	CKeyMap 0x33,0x3C	; '<'
	CKeyMap 0x34,0x3E	; '>'
	CKeyMap 0x35,0x3F	; '?'
	; This is in case the keycode isn't recognized.
	xor al, al
	jmp _keyboardMapping.return

 .return:
	pop ebx
	ret

 .returnShift:		; separate return to set shell indicator.
 	cmp byte [currentMode], SHELL_MODE
	jne .return
	mov bl, [bKEYBOARDSTATUS]
	and bl, 00000010b
	cmp bl, 00000010b
	jne .flagDown
	mov word [SHELL_SHIFT_INDICATOR], 0x341E
	jmp .return
   .flagDown:
   	mov word [SHELL_SHIFT_INDICATOR], 0x301F
	jmp .return

 .returnCaps:	; update shell and keyboard LED
	mov bl, [bKEYBOARDSTATUS]
	and bl, 00000001b
	;shl bl, 2	; if bit is set, BL now = 4 (00000100b)
	;mov bh, 0xFE		; LED command
	;call KEYBOARD_sendSpecialCmd
	cmp byte [currentMode], SHELL_MODE
	jne .return
	cmp bl, 00000001b
	jne .arrowDown
	mov word [SHELL_CAPS_INDICATOR], 0x3418
	jmp .return
   .arrowDown:
   	mov word [SHELL_CAPS_INDICATOR], 0x3019
 	jmp .return
