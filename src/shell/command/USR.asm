; USR.asm
; --- Initiate the changes required to move to Ring 3 and into userspace.

_commandUSR:
	mov byte [currentMode], USER_MODE
	ret
	
szUserMode db "Initiating user space...", 0
_initUserSpace:
	push eax
	xor eax, eax
	mov al, [currentMode]
	mov byte [currentMode], SHELL_MODE
	mov bl, 0x09
	mov esi, szUserMode
	call _screenWrite
	mov byte [currentMode], al
	pop eax
	ret
	
	