[ORG 0x10000]
[BITS 32]
GLOBAL kernel_main

jmp kernel_main
nop

%include "misc/MACROS.asm"			; NASM Macros and Pre-Processor definitions for global implementation.
%include "GLOBAL_definitions.asm"	; Global, pervasive variables and predefined constants for orchid.

%include "libraries/memops/MEMORY.asm"	; Memory operations on data held in RAM.
%include "misc/IDT.asm"				; Interrupt Descriptor Table and ISRs.
%include "shell/PARSER.asm"			; Parser in the case of SHELL_MODE.
%include "shell/SCREEN.asm"			; SHELL_MODE basic screen wrapper functions.
%include "misc/INIT.asm"			; For setting global variables/device Initialization.

%include "libraries/drivers/DRIVERS.asm"	; SYSTEM DRIVERS (mouse, HDD, USB, and all other PCI devices)

; Include BLOOM utilities here, so it can rely on the other libraries...

; UTILITY HAS A 'BITS 16' DIRECTIVE IN IT, BE CAREFUL TO PLACE IT ACCORDINGLY.
%include "misc/UTILITY.asm"		; Miscellaneous utility functions used across the system & kernel, such as numeric conversions or ASCII outputs.



[BITS 32]
kernel_main:
	cld
	clc
	cli
	call INIT_PICandIDT		; "INIT.asm" - Load the Interrupt Descriptor Table.
	call INIT_getSystemInfo ; "INIT.asm" - Get information about the system: RAM, CPU, CMOS time/date, running disk. Sets up globals as well.
	call MEMOPS_initHeap	; "MEMOPS.asm" - Initialize the Heap at 0x100000 to 0x1100000 (16 MiB wide). Flat memory model.
	call PIT_initialize		; "PIT.asm" - Initialize the Programmable Interval Timer.
	call INIT_START_SYSTEM_DRIVERS	; "INIT.asm" - Start the system drivers that must be run after everything else is initialized.
	; ENTER 'blooming' MODE HERE.

	; ENTER 'bloomed' MODE HERE.

	; Before interacting with the shell: check BOOT_ERROR_FLAGS for bit 1 to see whether shell or gui mode.
	; This is GUI_MODE space.
	mov DWORD eax, [BOOT_ERROR_FLAGS]
	and eax, 0x00000001
	cmp eax, 1
	je KERNEL_modeGUI		; If GUI_MODE is flagged, go there.

	; This is SHELL_MODE space.
	call INIT_kernelWelcomeDisplay
	mov byte [SYSTEM_CURRENT_MODE], SHELL_MODE	;SHELL MODE

	; SHELL_MODE debugging/snippet code typically goes below, before idling.




	; Hang and wait for some ISRs.
	sti
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MAIN KERNEL IDLE LOOP. SHELL MODE ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 .repHalt:
	call PARSER_CheckQueue				; Checking if there's a queued command.
	cmp byte [SYSTEM_CURRENT_MODE], USER_MODE	; was the mode changed?
	je .usrMode

	cmp byte [SYSTEM_TIME_UPDATE], TRUE
	jne .noTimerUpdate
	call TIMER_updateTimeDisplay
 .noTimerUpdate:
	hlt									; Halt and wait for any processor interruption.
	jmp kernel_main.repHalt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 .usrMode:
	call KERNEL_initUserSpace		; "USR.asm" - Handle the initialization of userspace from the command file that called it.
	hlt						; This section will do nothing right now except hang the system.



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  MAIN KERNEL GUI MODE FUNCTION  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
KERNEL_modeGUI:
	mov byte [SYSTEM_CURRENT_MODE], GUI_MODE

	; Test the GUI by creating a modernist masterpiece.
	push dword 0x00009999					; cyan color.
	push dword [SCREEN_FRAMEBUFFER_ADDR]	; LFB addy
	call VIDEO_clearDesktop
	add esp, 8

	mov ecx, 10000
	mov ebx, 0x01000100		;Try placing pixel at 256,256 (y, x)
 .test:
	push dword 0x000000FF		; Color - blue
	push dword ebx				; x | (y << 16)
	call VIDEO_putPixel
	add esp, 8
	inc ebx
	loop .test

	push dword 0x00FFBB00	; color = orange
	push dword 0x01700120	; final(y,x)
	push dword 0x00500050	; start(y,x)
	call VIDEO_fillRectangle
	add esp, 12

	push dword 0x00FF0000	; color = red
	push dword 0x020002F0	; final(y,x)
	push dword 0x00500200	; start(y,x)
	call VIDEO_drawRectangle
	add esp, 12
	push dword 0x00FF0000	; color = red
	push dword 0x020102F1	; final(y,x)
	push dword 0x004F01FF	; start(y,x)
	call VIDEO_drawRectangle
	add esp, 12
	push dword 0x00000000	; color = black
	push dword 0x01FF02EF	; final(y,x)
	push dword 0x00510201	; start(y,x)
	call VIDEO_drawRectangle
	add esp, 12

	push dword 0x00FFFFFF	; color =
	push dword 0x02040304	; final(y,x)
	push dword 0x02000300	; start(y,x)
	call VIDEO_drawRectangle
	add esp, 12

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MAIN KERNEL IDLE LOOP. GUI MODE   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	sti
 .repHalt:
	hlt
	jmp .repHalt


times  (KERNEL_SIZE_SECTORS*512)-($-$$) db 0			; Pad out the kernel to an even multiple of 512
