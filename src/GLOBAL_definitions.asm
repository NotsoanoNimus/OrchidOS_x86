; GLOBAL_definitions.asm
; -- Definitions intended to be pervasive throughout the Orchid x86 system. Included directly in the KERNEL.asm file.


; Misc information.
%define ORCHID_VERSION "0.4.1"

KERNEL_OFFSET			equ 0x10000
KERNEL_SIZE_SECTORS		equ 0x0040			; Change this in every other file based on the growth of the kernel.

DEFAULT_COLOR			equ 0x0F		; Default color to use for all graphical/screen ops
SYSTIME_VIDEO_LOCATION	equ 0x000B808C
SYSDATE_VIDEO_LOCATION	equ 0x000B8060

SHELL_SHIFT_INDICATOR	equ 0x000B8058
SHELL_CAPS_INDICATOR	equ 0x000B8056
SHELL_MODE_TEXT_COLOR	 db 0x0F		; Default 0x0F attrib. Used by keyboard input. Changed by COLOR command.

SYSTEM_TIME_UPDATE		 db FALSE		; used by the shell's main loop to update the time.
SYSTEM_BSOD_FUNCTION	equ 0x1300		; PA to jmp on crash. This is approx & is ok if < start of BSOD func.
SYSTEM_BSOD_ERROR_CODE	equ 0x13F8		; DWORD ASCII rep at PA 0x11F8 (end of ST2 loader) for displaying BSOD death code.

; Internal system state information.
BOOT_ERROR_FLAGS		equ 0x0FFC		; Error flags for startup. DWORD of bit-flags. Right underneath the ST2L.
; Bit 0: GUI Mode (1), SHELL Mode (0)
; Bit 1: Unable to load system memory information (1), All clear (0).
; Bit 6: Unable to load system shutdown variables.
; Bit 7: Unable to load ACPI information for power management.
; Bit 8: Unable to initialize or find a compatible Ethernet device.

; More internal system state info.
BOOT_MODE				equ 00000000b
SHELL_MODE				equ 00000001b
GUI_MODE				equ 00000010b
USER_MODE				equ 00000100b
SYSTEM_CURRENT_MODE		db BOOT_MODE	;flags for OS' current mode (set to BOOT MODE - 00b by default)
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
MMAP_SIZE				db 0			; How many entries are there in the system memory map created by the Bootloader?
MEM_INFO				equ 0x500		; Storage starting location for memory map.

; Some heap info.
HEAP_INFO				equ 0x6FFF0		; 16 bytes of heap info. Of main interest to the kernel is the PID count field. See MEMOPS for format.
RUNNING_PROCESSES_TABLE equ 0x70000		; Base ptr to an array of running processes. Max size of 1000h (4KiB). See memops for more.
SYSTEM_MAX_RUNNING_PROCESSES equ 128	; A maximum of 128 PIDs can be assigned at any given time.
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
SHELL_INPUT_BUFFER		equ 0x00001400		; 256-byte (100h) buffer for user input.
SHELL_SHADOW_BUFFER		equ 0x00001500		; 256-byte shadow buffer that holds the previous command.
SHELL_COMMAND_IN_QUEUE	db FALSE 			; Tell parser if cmd waiting. Triggered by LF from keyboard.
SHELL_CURSOR_OFFSET		dw 0x0000
SHELL_VIDEO_INDEX		dw 0x0000
SHELL_INPUT_INDEX		dw 0x0000		; Number from 0-127 as an index of current user input position.
SHELL_SHADOW_INDEX		dw 0x0000

NULL_IDT:		; USED FOR REBOOTING ONLY.
	dw 0x0000
	dd 0x00000000
