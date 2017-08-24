; CLS.asm
; -- Clear the screen.


_commandCLS:
	pushad
	call _screenCLS
	mov bx, 0x0001
	call _screenUpdateCursor
	popad
	ret
