; CLS.asm
; -- Clear the screen.


COMMAND_CLS:
	pushad
	call SCREEN_CLS
	mov bx, 0x0001
	call SCREEN_UpdateCursor
	popad
	ret
