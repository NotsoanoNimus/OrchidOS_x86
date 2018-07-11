[ORG 0x10000]
[BITS 32]
GLOBAL kernel_main

jmp kernel_main
nop

; The MACROS file is essential to the source of this project, and will
;  describe many of the shorthand methods used henceforth.
%include "misc/MACROS.asm"			; NASM Macros and Pre-Processor definitions for global implementation.
%include "core/GLOBAL_definitions.asm"	; Global, pervasive variables and predefined constants for orchid.

%include "libraries/LIBRARIES.asm"	; Include all libraries and functions necessary to run the system.
%include "misc/IDT.asm"				; Interrupt Descriptor Table and ISRs.
%include "misc/INIT.asm"			; For setting global variables/device Initialization.
%include "libraries/drivers/DRIVERS.asm"	; SYSTEM DRIVERS (mouse, HDD, USB, and all other PCI devices)

%include "stem/STEM.asm"			; STEM system control and flow components.

%include "shell/SHELL.asm"			; All shell components for operating in the fallback mode.
%include "desktop/DESKTOP.asm"		; All desktop/GUI components.

; Include BLOOM utilities here, so it can rely on the other libraries...
%include "bloom/BLOOM.asm"

; UTILITY HAS A 'BITS 16' DIRECTIVE IN IT, BE CAREFUL TO PLACE IT ACCORDINGLY.
%include "misc/UTILITY.asm"		; Miscellaneous utility functions used across the system & kernel, such as numeric conversions or ASCII outputs.


[BITS 32]
TEST_STRING_PTR db "test", 0
kernel_main:
	cld
	clc
	cli
	; Before interacting with the shell: check BOOT_ERROR_FLAGS for bit 1 to see whether shell or gui mode.
	push eax
	mov dword eax, [BOOT_ERROR_FLAGS]
	and eax, 0x00000001
	cmp eax, 1
	jne .shellMode
	mov byte [SYSTEM_CURRENT_MODE], GUI_MODE
	jmp .skipShellMode
 .shellMode: mov byte [SYSTEM_CURRENT_MODE], SHELL_MODE	; default to SHELL MODE
 .skipShellMode:
	call INIT_PICandIDT		; "INIT.asm" - Load the Interrupt Descriptor Table.
	call INIT_getSystemInfo ; "INIT.asm" - Get information about the system: RAM, CPU, CMOS time/date, running disk. Sets up globals as well.
	call HEAP_INITIALIZE	; "MEMOPS.asm" - Initialize the Heap. Flat memory model.
	call PIT_initialize		; "PIT.asm" - Initialize the Programmable Interval Timer.
	call INIT_START_SYSTEM_DRIVERS	; "INIT.asm" - Start the system drivers that must be run after everything else is initialized.
	call INIT_START_SYSTEM_PROCESSES ; "INIT.asm" - Start system services/processes.

	; if GUI_MODE...
	cmp byte [SYSTEM_CURRENT_MODE], GUI_MODE
	je KERNEL_modeGUI		; If GUI_MODE is flagged, go there.

	; ... else ...
	; This is SHELL_MODE space.
	call INIT_kernelWelcomeDisplay

	; SHELL_MODE 'blooming' phase.
	call BLOOM_SHELL_MODE

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; SHELL_MODE debugging/snippet code typically goes below, before idling.


	; Build a fake ARP request.
	mov [0x10000000], dword 0xFFFFFFFF
	mov [0x10000004], word 0xFFFF
	MEMCPY ETHERNET_MAC_ADDRESS,0x10000006,0x06
	mov [0x1000000C], byte 0x08
	mov [0x1000000D], byte 0x06
	mov [0x1000000E], byte 0x00
	mov [0x1000000F], byte 0x01
	mov [0x10000010], byte 0x08
	mov [0x10000011], byte 0x00
	mov [0x10000012], byte 0x06
	mov [0x10000013], byte 0x04
	mov [0x10000014], byte 0x00
	mov [0x10000015], byte 0x01
	MEMCPY ETHERNET_MAC_ADDRESS,0x10000016,0x06
	mov [0x1000001C], dword 0x0F02000A	; IP 10.0.2.15
	mov [0x10000020], dword 0x00000000
	mov [0x10000024], word 0x0000
	mov [0x10000026], dword 0x0102000A	; Requesting MAC of IP 10.0.2.1

	;func(E1000_READ_COMMAND,E1000_REG_TCTRL)
	;func(E1000_READ_PHY,26)	;Read the PHY, Register 26.
	;func(COMMAND_DUMP)

	;func(E1000_WRITE_COMMAND,0x2C00,0x00000008)

	;mov ebx, VIA_DEVICE_PCI_WORD
	;func(VT6103_READ_COMMAND,0x0001)
	;func(COMMAND_DUMP)

	;01180110 = TX Data buffer, where the above ARP req will be copied for transmission.
	; try ARP request
	;func(ETHERNET_SEND_PACKET,0x10000000,0x00000100);02A)
	;SLEEP 10
	;func(ETHERNET_SEND_PACKET,0x10000000,0x0000002A)

	mov esi, TEST_STRING_PTR
	func(strlen,esi)	; EAX = strlen
	func(MD5_COMPUTE_HASH,esi,eax)	; Hash it.

	SYSCALL(7)

	;func(VIDEO_GRID_SNAP_AND_TRANSLATE,VIDEO_COORDS(0x203,0x089))
	;VIDEO_MANIPULATE_COORDS eax,+,edx,ecx
	;call COMMAND_DUMP


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

	push eax
	mov al, byte [SYSTEM_TIME_UPDATE]
	and al, TRUE
	cmp al, TRUE
	pop eax
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
	; GUI-only initialization functions for setting up the desktop.
	call DESKTOP_ENV_REGISTER_INITIAL_WINDOWS
	; GUI_MODE BLOOM here.
	call BLOOM_GUI_MODE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MAIN KERNEL IDLE LOOP. GUI MODE   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	sti
 .repHalt:
 	;call VIDEO_SCREEN_UPDATE	; update the screen according to the timer interrupt.
	hlt
	jmp .repHalt


times  (KERNEL_SIZE_SECTORS*512)-($-$$)-15 db 0			; Pad out the kernel to an even multiple of 512
db "ORCHID-CORE-END"	; kernel signature
