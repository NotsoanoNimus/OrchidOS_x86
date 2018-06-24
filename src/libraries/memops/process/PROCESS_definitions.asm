; PROCESS_definitions.asm
; -- Definitions for process-related functions.

RUNNING_PROCESS_NEXT_GIVEN_ID	db 0x00				; Verbose name. Lists the next ID to be delegated.
; Next PID is always 1 initially because SYS is PID 0.
RUNNING_PROCESS_ENTRY_SIZE		equ 32				; 32 bytes per entry
RUNNING_PROCESS_ENTRY:
	.entry:		dd 0x00000000	; entry point in RAM of the process' data
	.size:		dd 0x00000000	; size of the process' allocation
	.name:		times 22 db 0x00; ASCII name representation of the process. For informational purposes only.
	.nameTerm:	db 0x00			; forced null-terminator of the string.
	.pid:		db 0x00			; process ID, used in all manipulations of the process instead of the name.
