; PIT.asm
;	Programmable Interval Timer device "driver"

PIT_COMMAND			equ 0x43
PIT_CHANNEL_0		equ 0x40
PIT_CHANNEL_1		equ 0x41
PIT_CHANNEL_2		equ 0x42

%include "libraries/drivers/timer/TIMER.asm"

PIT_initialize:		; initialize the PIT.
	pushad
	mov eax, 0x852B		; Reload value of 34091 for about 34.9999Hz (great for keeping proper time)
	mov [PIT_RELOAD_VALUE], eax

	; Actually initialize the PIT now.
	pushfd
	mov al, 00110100b		; Channel 0, lo/hi-byte, rate generator
	out PIT_COMMAND, al

	mov ax, [PIT_RELOAD_VALUE]
	out PIT_CHANNEL_0, al
	mov al, ah
	out PIT_CHANNEL_0, al
	
	popfd
	popad
	ret
