; GRAPHICS.asm
; -- Includes intro functions and display overlays, as well as refreshers for the upper status bar.
; ---- This file is largely useless except for load-time flair.

szSPLASHIntro1 db "                                          88          88          88", 0
szSPLASHIntro2 db "                                          88          ^^          88", 0
szSPLASHIntro3 db "                                          88                      88", 0
szSPLASHIntro4 db "         ,adPPYba,  8b,dPPYba,  ,adPPYba, 88,dPPYba,  88  ,adPPYb,88", 0
szSPLASHIntro5 db "        a8^     ^8a 88P'   ^Y8 a8^     ^^ 88P'    ^8a 88 a8^    `Y88", 0
szSPLASHIntro6 db "        8b       d8 88         8b         88       88 88 8b       88", 0
szSPLASHIntro7 db "         8a,   ,a8^ 88         ^8a,   ,aa 88       88 88 ^8a,   ,d88", 0
szSPLASHIntro8 db "         `^YbbdP^'  88          `^Ybbd8^' 88       88 88  `^8bbdP^Y8", 0
szSPLASHGraphic1 db "                                        _", 0
szSPLASHGraphic2 db "                                    _ (`-`) _", 0
szSPLASHGraphic3 db "                                  /` '.\ /.' `\ ", 0
szSPLASHGraphic4 db "                                  ``'-.,=,.-'``", 0
szSPLASHGraphic5 db "                                    .'//v\\'.", 0
szSPLASHGraphic6 db "                                   (_/\ ^ /\_)", 0
szSPLASHGraphic7 db "                                       '-'", 0

; Shell strings. Move them later, as they're technically not global variables of major importance...
szOverlay				db "Orchid -> SHELL"
						times (80-32)-(0x0+($-szOverlay)) db 0x20
szShellDate				db "XXXX XXX XX, 20XX",
szShellTimeZone			db ", UTC"
szShellTime				db "[xx:xx:xx]"
						db 0



GRAPHICS_introOverlay:
	pushad
	; Clear the screen fully, and paint a cyan backdrop.
	mov edi, 0x000B8000
	mov ecx, 2000	;80*25 WORDS
	mov ax, 0x3320	; Color 33, all spaces (text matches BG so cursor doesn't show)
	push edi
	rep stosw		; Full CLS
	pop edi

	; Write the intro graphic.
	mov bx, 0x0001	; go to col 0, row 1
	call SCREEN_UpdateCursor
	PrintString szSPLASHIntro1,0x3F	;Cyan & White: Orchid's theme.
	PrintString szSPLASHIntro2
	PrintString szSPLASHIntro3
	PrintString szSPLASHIntro4
	PrintString szSPLASHIntro5
	PrintString szSPLASHIntro6
	PrintString szSPLASHIntro7
	PrintString szSPLASHIntro8
	PrintString szSPLASHGraphic1,0x30
	PrintString szSPLASHGraphic2
	PrintString szSPLASHGraphic3
	PrintString szSPLASHGraphic4
	PrintString szSPLASHGraphic5
	PrintString szSPLASHGraphic6
	PrintString szSPLASHGraphic7

	;reset cursor
	xor bx, bx
	call SCREEN_UpdateCursor

	; 10x200ms = 2s
	SLEEP_noINT 10

	popad
	ret


; Refresh Overlay function refreshes on timer calls and other changes
GRAPHICS_setShellOverlay:
	pushad
	call SCREEN_CLS				; Clears all but line 1. That will be handled momentarily...

	movzx bx, [SHELL_CURSOR_OFFSET]
	push ebx	; save original cursor position

	mov bx, 0x0000
	call SCREEN_UpdateCursor	; Set cursor to 0,0 position to write header.
	PrintString szOverlay,0x3F

	pop ebx		; get original cursor pos and put it back
	call SCREEN_UpdateCursor
	popad
	ret
