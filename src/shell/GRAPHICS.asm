; GRAPHICS.asm
;	Includes intro functions and display overlays, as well as refreshers for the upper status bar.
; -- This file is largely useless except for load-time flair.

szIntro1 db "                                          88          88          88", 0
szIntro2 db "                                          88          ^^          88", 0
szIntro3 db "                                          88                      88", 0
szIntro4 db "         ,adPPYba,  8b,dPPYba,  ,adPPYba, 88,dPPYba,  88  ,adPPYb,88", 0
szIntro5 db "        a8^     ^8a 88P'   ^Y8 a8^     ^^ 88P'    ^8a 88 a8^    `Y88", 0
szIntro6 db "        8b       d8 88         8b         88       88 88 8b       88", 0
szIntro7 db "         8a,   ,a8^ 88         ^8a,   ,aa 88       88 88 ^8a,   ,d88", 0
szIntro8 db "         `^YbbdP^'  88          `^Ybbd8^' 88       88 88  `^8bbdP^Y8", 0
szGraphic1 db "                                        _", 0
szGraphic2 db "                                    _ (`-`) _", 0
szGraphic3 db "                                  /` '.\ /.' `\ ", 0
szGraphic4 db "                                  ``'-.,=,.-'``", 0
szGraphic5 db "                                    .'//v\\'.", 0
szGraphic6 db "                                   (_/\ ^ /\_)", 0
szGraphic7 db "                                       '-'", 0


_introOverlay:
	pushad
	; Clear the screen fully
	mov edi, 0x000B8000
	mov ecx, 2000	;80*25 WORDS
	mov ax, 0x3320	; Color 33, all spaces (text matches BG so cursor doesn't show)
	push edi
	rep stosw		; Full CLS
	pop edi

	mov bx, 0x0001	; go to row 8, col 0
	call _screenUpdateCursor
	; Write the intro graphic!
	mov bl, 0x3F	; Cyan BG, White text
	mov esi, szIntro1
	call _screenWrite
	mov esi, szIntro2
	call _screenWrite
	mov esi, szIntro3
	call _screenWrite
	mov esi, szIntro4
	call _screenWrite
	mov esi, szIntro5
	call _screenWrite
	mov esi, szIntro6
	call _screenWrite
	mov esi, szIntro7
	call _screenWrite
	mov esi, szIntro8
	call _screenWrite

	mov bx, 0x000A
	call _screenUpdateCursor
	mov bl, 0x30	; Cyan BG, black text
	mov esi, szGraphic1
	call _screenWrite
	mov esi, szGraphic2
	call _screenWrite
	mov esi, szGraphic3
	call _screenWrite
	mov esi, szGraphic4
	call _screenWrite
	mov esi, szGraphic5
	call _screenWrite
	mov esi, szGraphic6
	call _screenWrite
	mov esi, szGraphic7
	call _screenWrite

	;reset cursor
	xor bx, bx
	call _screenUpdateCursor

	mov eax, 10		;10x200ms = 2s
	sti
	call _SLEEP
	cli

	popad
	ret


; Refresh Overlay function refreshes on timer calls and other changes
_graphicsRefreshOverlay:
	pushad
	call _screenCLS				; Clears all but line 1. That will be handled momentarily...

	movzx bx, [cursorOffset]
	push ebx	; save original cursor position

	mov bx, 0x0000
	call _screenUpdateCursor	; Set cursor to 0,0 position to write header.
	mov esi, szOverlay
	xor dx, dx
	mov bl, 0x3F
	call _screenWrite			; Write the header.

	pop ebx		; get original cursor pos and put it back
	call _screenUpdateCursor
	popad
	ret
