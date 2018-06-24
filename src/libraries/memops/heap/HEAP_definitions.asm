; HEAP_definitions.asm
; -- Definitions for Heap management and Heap operations.

;HEAP_INFO = 0x6FFF0

HEAP_STATUS_BLOCKS_STACK_BOTTOM	equ 0x00070000		;Secondary stack for pointers to available memory blocks.
HEAP_STATUS_BLOCKS_NEXT			 dd 0x00000000		; Contains saved stack pointer.

HEAP_BLOCK_CLEAN				equ 0x00			; Block is free.
HEAP_BLOCK_DIRTY				equ 0x01			; Block is being accessed.

; HEAP_INFO information (pointers).
HEAP_PID_COUNT					equ 0x0006FFFC		;Ptr to dword at 0x6FFF8: counts how many processes running. Will be used to thread/multitask w/ IRQ0.
HEAP_CURRENT_SIZE				equ 0x0006FFF8		;Ptr to dword at 0x6FFF0: keeps track of the current heap size.
HEAP_END						equ 0x0006FFF4		; Contains a pointer to the end of the heap. This variable changes as the heap size changes.
HEAP_MAX_SIZE					equ 0x0006FFF0		;Pointer to heap max size. Scalable within the program.

HEAP_START						equ 0x01100000		; Heap starting point. Static variable.
HEAP_INIT_SIZE					equ 0x01000000		; 16 MiB.
;HEAP_MAX_SIZE					equ 0x80000000		; 2GiB Heap Max. UNSURE ABOUT THIS.

HEAP_HEADER_MAGIC				equ 0xBEABEA57		; "MAGIC" (header)
HEAP_FOOTER_MAGIC				equ 0xDEADBEEF		; "MAGIC" (footer)
HEAP_HEADER_SIZE				equ 12				; Headers are 9-byte objects. Round them to 12, so it's DWORD-aligned.
HEAP_FOOTER_SIZE				equ 8				; Footers do not have a hole identifier.

HEAP_TAGGING_SIZE				equ 32				; '32' bytes worth of total Heap accounting bytes in a process' RAM.
HEAP_HEADER_SIZE_RAM			equ 0x10			; 16 bytes leaves room for Header...
HEAP_FOOTER_SIZE_RAM			equ 0x10			;  and the Footer to possibly expand in the future.
