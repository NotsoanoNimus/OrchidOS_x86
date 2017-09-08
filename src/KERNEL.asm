[ORG 0x10000]
[BITS 32]
GLOBAL kernel_main

jmp kernel_main
nop

; Misc information.
%define ORCHID_VERSION "0.3"
KERNEL_OFFSET			equ 0x10000
KERNEL_SIZE_SECTORS		equ 0x0040			; Change this in every other file based on the growth of the kernel.
COMMAND_QUEUE			equ KERNEL_OFFSET+commandInQueue	; FOR EXTERNAL USE ONLY!
INPUT_BUFFER			equ KERNEL_OFFSET+inputBuffer		; !!! ^^
SYSTIME_IRQ_ADJ			equ KERNEL_OFFSET+szShellTime+1		; !!! ^^
CMOSDATE_SHELL_ADJ		equ KERNEL_OFFSET+szShellDate
DEFAULT_COLOR			equ 0x0F		; Default color to use for all graphical/screen ops
SYSTIME_VIDEO_LOCATION	equ 0x000B808C
SYSDATE_VIDEO_LOCATION	equ 0x000B8060
SHELL_SHIFT_INDICATOR	equ 0x000B8058
SHELL_CAPS_INDICATOR	equ 0x000B8056
SHELL_MODE_TEXT_COLOR	 db 0x0F		; Default 0x0F attrib. Used by keyboard input. Changed by COLOR command.
SYSTEM_TIME_UPDATE		 db 0			; used by the shell's main loop to update the time.
SYSTEM_BSOD_FUNCTION	equ 0x11DB		; PA to jmp to when computer crashes.
SYSTEM_BSOD_ERROR_CODE	equ 0x11F8		; DWORD ASCII rep at PA 0x11F8 (end of ST2 loader) for displaying BSOD death code.

; Internal system state information.
BOOT_ERROR_FLAGS		equ 0x0FFC		; Error flags for startup. DWORD of bit-flags. Right underneath the ST2L.
; Bit 0: GUI Mode (1), SHELL Mode (0)
; Bit 1: Unable to load system memory information (1), All clear (0).
; Bit 7: Unalbe to load ACPI information for power management.

; More internal system state info.
BOOT_MODE				equ 00000000b
SHELL_MODE				equ 00000001b
GUI_MODE				equ 00000010b
USER_MODE				equ 00000100b
currentMode				db BOOT_MODE	;flags for OS' current mode (set to BOOT MODE - 00b by default)
KEYBOARD_DISABLE_OUTPUT db 0x00

; File system information.
RESERVED_SECTORS		equ 35			; 35 for now, CHANGE AS KERNEL GROWS.
SECTORS_PER_FAT			equ 1024
NUMBER_OF_FATS			equ 2
ROOT_DIR_START_SECTOR	equ (RESERVED_SECTORS+(SECTORS_PER_FAT*NUMBER_OF_FATS))

; GDT selector values.
NULL_SELECTOR 			equ 0
DATA_SELECTOR			equ 8			; (1 shl 3) Flat data selector (ring 0)
CODE_SELECTOR			equ 16			; (2 shl 3) 32-bit code selector (ring 0)
USER_DATA_SELECTOR		equ 24
USER_CODE_SELECTOR		equ 32
REAL_MODE_DATA_SELECTOR	equ 40
REAL_MODE_CODE_SELECTOR	equ 48

; Memory map information from BOOT.
SYSTEM_RAM				dq 0			; Total RAM on the system. Does not distinguish between mem types (free / reserved).
MMAP_SIZE				db 0			; How many entries are there in the system memory map created by the Bootloader?
MEM_INFO				equ 0x500		; Storage starting location for memory map.

; Some heap info.
HEAP_INFO				equ 0x6FFF0		; 16 bytes of heap info. Of main interest to the kernel is the PID count field. See MEMOPS for format.
RUNNING_PROCESSES		equ 0x70000		; Base ptr to an array of running processes. Max size of 1000h (4KiB). See memops for more.

; Connected device info.
PCI_INFO				equ 0x71000		; Base ptr to filled info about PCI Devices. 1KiB of space (up to 71400h)

; Processor info.
CPU_INFO				equ 0x700		; Store CPU info starting at 0x700. Assume MEM_INFO won't be larger than 0x200 (>20 entries)

; Video/Graphics information.
VGA_INFORMATION			equ 0x800		; Store the VGA/VIDEO info starting at 0x800, for 0x400 bytes (to 0xc00).
VESA_CURRENT_MODE_INFO 	equ 0xC00		; Store VESA info from 0xC00 to 0xE00.
VESA_DESIRED_MODE		equ 0x0118		; Tentative mode. Will change later to be more flexible than supporting only one standard.
SCREEN_PITCH			equ VESA_CURRENT_MODE_INFO+0x10		;how many bytes per line. (WORD)
SCREEN_WIDTH			equ VESA_CURRENT_MODE_INFO+0x12		; WORD
SCREEN_HEIGHT			equ VESA_CURRENT_MODE_INFO+0x14		; WORD
SCREEN_BPP				equ VESA_CURRENT_MODE_INFO+0x19		; BYTE
SCREEN_FRAMEBUFFER_ADDR	equ VESA_CURRENT_MODE_INFO+0x28		; DWORD
SCREEN_OFFSCREEN_MEMORY equ VESA_CURRENT_MODE_INFO+0x30		; Amount of memory outside the framebuffer, off-screen (extra mem). (WORD)
;SCREEN_BACKBUFFER		equ 0x100000						; Second buffer for LFB is going to be allocated at 0x100000 (1MiB into phys mem).
; This will not happen because the SystemWindowManager process will control the management of GUI layers.
BYTES_PER_PIXEL			db 0x00
SCREEN_FRAMEBUFFER		dd 0x00000000
SCREEN_LFB_SIZE_KB		dw 0x0000
SCREEN_PIXEL_COUNT		dd 0x00000000

; Keyboard info. Move later once more generic keyboard driver is loaded.
KEYBOARD_BUFFER			db 0			; ASCII value for the current keyboard press.

; Shell misc. variables. These are important, but the names need to be changed later to something less generic.
commandInQueue		db 0x00 		; Boolean flag to tell the parser whether or not a command is waiting to be processed.
									; Only set on a LF from the keyboard.
cursorOffset 		dw 0x0000
videoMemIndex		dw 0x0000
inputBuffer			times 32 dq 0x0	; Reserve a 256-byte space for the user's input. Handled in SCREEN.asm
inputIndex			dw 0x0000		; Number from 0-127 as an index of current user input position.

NULL_IDT:		; USED FOR REBOOTING ONLY.
	dw 0x0000
	dd 0x00000000

; Shell strings. Move them later, as they're technically not global variables of major importance...
szOverlay				db "Orchid -> SHELL"
						times (80-32)-(0x0+($-szOverlay)) db 0x20
szShellDate				db "XXXX XXX XX, 20XX",
szShellTimeZone			db ", UTC"
szShellTime				db "[xx:xx:xx]"
						db 0
szIRQCall				db "Interrupt Called:", 0
iTermLine				db 0



%include "misc/MACROS.asm"

%include "libraries/MEMOPS.asm"		; Heap setup and memory operations.
%include "libraries/ACPI/ACPI.asm"	; ACPI init functions and power management system.
%include "IDT.asm"					; Interrupt Descriptor Table and ISRs.
%include "shell/PARSER.asm"			; Parser in the case of SHELL_MODE.
%include "shell/SCREEN.asm"			; SHELL_MODE basic screen wrapper functions.
%include "PCI.asm"					; PCI Bus setup and implementation.
%include "misc/INIT.asm"			; Initialization functions, mainly for setting global variables and putting together devices.

%include "libraries/drivers/DRIVERS.asm"	; SYSTEM DRIVERS (mouse, HDD, USB, and all other PCI devices not used in SHELL_MODE)
;%include "LIBRARIES.asm"					; SYSTEM LIBRARIES. Placeholder for its later implementation.

; UTILITY HAS A BITS 16 IN IT, BE CAREFUL TO PLACE IT ACCORDINGLY.
%include "misc/UTILITY.asm"		; Miscellaneous utility functions used across the system & kernel, such as numeric conversions or ASCII outputs.

[BITS 32]
kernel_main:
	cld
	clc
	cli
	call _initPICandIDT		; "INIT.asm" - Load the Interrupt Descriptor Table.
	call _initGetSystemInfo ; "INIT.asm" - Get information about the system: RAM, CPU, CMOS time/date, running disk. Sets up globals as well.
	call MEMOPS_initHeap	; "MEMOPS.asm" - Initialize the Heap at 0x100000 to 0x1100000 (16 MiB wide). Flat memory model.
	call PIT_initialize		; "PIT.asm" - Initialize the Programmable Interval Timer.

	; Before interacting with the shell: check BOOT_ERROR_FLAGS for bit 1 to see whether shell or gui mode.
	; This is GUI_MODE space.
	mov DWORD eax, [BOOT_ERROR_FLAGS]
	and eax, 0x00000001
	cmp eax, 1
	je modeGUI		; If GUI_MODE is flagged, go there.

	; This is SHELL_MODE space.
	call _kernelWelcomeDisplay
	mov byte [currentMode], SHELL_MODE	;SHELL MODE

	; SHELL_MODE debugging/snippet code typically goes below, before idling.



	; Hang and wait for some ISRs.
	sti
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MAIN KERNEL IDLE LOOP. SHELL MODE ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 .repHalt:
	call _parserCheckQueue				; Checking if there's a queued command.
	cmp byte [currentMode], USER_MODE	; was the mode changed?
	je .usrMode

	push edx
	mov dl, [SYSTEM_TIME_UPDATE]		; check timer update flags.
	and dl, 0x01						; check only bit 1
	cmp dl, 1
	pop edx

	jne .noTimerUpdate
	call _updateTimeDisplay
 .noTimerUpdate:
	hlt									; Halt and wait for any processor interruption.
	jmp kernel_main.repHalt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 .usrMode:
	call _initUserSpace		; "USR.asm" - Handle the initialization of userspace from the command file that called it.
	hlt						; This section will do nothing right now except hang the system.



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  MAIN KERNEL GUI MODE FUNCTION  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
modeGUI:
	mov byte [currentMode], GUI_MODE

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
