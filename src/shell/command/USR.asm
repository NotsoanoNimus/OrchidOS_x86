; USR.asm
; --- Initiate the changes required to move to Ring 3 and into userspace.

COMMAND_USR:
	mov byte [currentMode], USER_MODE
	ret

szUserMode db "Initiating user space...", 0
KERNEL_initUserSpace:
	mov byte [currentMode], SHELL_MODE
	PrintString szUserMode,0x09
	mov byte [currentMode], USER_MODE
	; ... do something here.
	ret
