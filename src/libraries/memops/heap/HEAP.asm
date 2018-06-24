; HEAP.asm
; -- Functions for Heap setup and management.
; ---- This file will NOT contain the general functions that utilize the Heap (kmalloc, kmemcmp, etc).

%include "libraries/memops/heap/HEAP_definitions.asm"

; HEAP SIGNATURES:
;	Header...
;		Magic		DWORD	'0xBEABEA57' --signature
;		Size		DWORD	-- Length of the allocated block.
;		Dirty		BYTE	'0x00'=Not accessed/clean. 0x01 = Dirty.
;	Footer...
;		Magic		DWORD	'0xDEADBEEF' --signature
;		Header Ptr	DWORD	-- Physical address of section header.
szHeapInitFailed		db "Heap initialization failure. Cause unknown.", 0
; TODO: ADD A HEAP_SHRINK & HEAP_GROW function to make it DYNAMIC.
HEAP_INITIALIZE:
	pushad
	; Heap starts at 0x00100000 with an initial space of 0x01000000 (16 MiB).
	;  The maximum space allowed is determined by the iTotalMemory and BACKBUFFER_START variables.
	;  Also, the heap cannot trample reserved areas of memory, so on every heap expansion, we can check to see if we're accessing reserved space.
	;		-- by using the MEMOPS_INTERNAL_checkValidMemory function.
	; It's divided into a system of headers/footers that are described above.
	;   Each available block is added to the heap stack sequentially, the most recent (the one that gets popped to use)
	;	being the next available hole in memory. Every time kfree is called, the heap is checked for holes to merge together.
	mov edi, HEAP_START
	push edi
	xor eax, eax
	mov ecx,(HEAP_INIT_SIZE/4)		; 0x400000 * DWORD = HEAP_INIT_SIZE (16 MiB)
	rep stosd

	; Draw up the inital header and footer.
	pop edi				; return to heap start
	push edi			; save state
	mov eax, edi					; save header address
	mov dword [edi], HEAP_HEADER_MAGIC
	add edi, 4
	mov dword [edi], HEAP_INIT_SIZE
	add edi, 4
	mov byte [edi], HEAP_BLOCK_CLEAN

	pop edi				; restore state
	add edi, HEAP_INIT_SIZE			; Step forward to 0x01100000 (16MiB heap)
	sub edi, HEAP_FOOTER_SIZE		; prepare to write the footer. Should be put EDI at 0x010FFFF8

	mov dword [edi], HEAP_FOOTER_MAGIC
	add edi, 4
	mov dword [edi], eax
	add edi, 4

	mov dword [HEAP_END], edi					; HEAP_END should now contain 0x01100000.
	mov dword [HEAP_PID_COUNT], 0x00000001		; Only one process running to start, which is SYS_KERNEL.
	mov dword [HEAP_CURRENT_SIZE], 0x01000000	; 16MiB initialization.

	mov dword edx, [iMemoryFree]				; Get total free memory.
	push edx
	and edx, 0x7FFFFFFF		; When bit 31 of EDX is set, it registers as a JS and outputs error. Hotfix for supporting >2G RAM.
	sub edx, 0x00100000							; Subtract the kernel space.
	pop edx
	js .heapInitFailure							; If there's no space for the heap, the system cannot run.
	mov dword [HEAP_MAX_SIZE], edx				; Max heap size is now based on available memory!!

	popad
	ret

 .heapInitFailure:
 	PrintString szHeapInitFailed,0x0C
	cli
 .repHalt:	; Put in a halt loop.
	hlt
	jmp .repHalt
	; Failure to instantiate the Heap should kill the system immediately but for some reason this isn't working...
	; -- Enters the blue screen but, oddly, has no status code displayed.
	; TODO: fix this.
	;cli
	;push dword 0x00000005
	;jmp SYSTEM_BSOD




; NO INPUTS OR OUTPUTS.
; -- Consists of a very basic algorithm to determine if adjacent headers/footers between blocks represent memory holes that need to be merged.
HEAP_INTERNAL_combineAdjacentMemory:
	pushad
	mov dword edi, HEAP_START		; Starting from the bottom of the heap.

 .getNextBlock:
	mov dword ebx, [edi+4]				; Size of memory block.
	cmp byte [edi+8], HEAP_BLOCK_DIRTY	; Block isn't a hole, move on.
	je .nextBlockAdd					; ^^^

	add edi, ebx						; Point to the next header.
	mov dword eax, [edi-4]				; EAX = header address of the 1st hole (coming from footer).
	cmp byte [edi+8], HEAP_BLOCK_DIRTY	; Is the adjacent block dirty?
	je .nextBlock						; ...if so, move on.

	; If the code reaches here, there are two adjacent holes. Combine them into one large hole.
	; Right here: EDI = adjacent header base ptr // EAX = left (1st) hole's base addr // EBX = distance between EAX and EDI
	mov dword ecx, [edi+4]				; ECX = size of the hole to the right.

	; Clean the footer and header that's separating the holes.
	MultiPush ecx,eax,edi
	xor eax, eax
	mov ecx, 0x00000014					; 20 iterations
	sub edi, HEAP_FOOTER_SIZE			; Position EDI at the beginning of the footer next to the header of the 2nd hole.
	rep stosb							; Clear to 0
	MultiPop edi,eax,ecx

	add edi, ecx						; Position EDI at the end of the 2nd hole
	mov dword [edi-4], eax 				; Set the header ptr in the footer to the 1st hole's header. This completes combining the hole.

	sub edi, ecx
	sub edi, ebx
	add ebx, ecx
	mov dword [edi+4], ebx				; set the new size at the 1st hole's header.

 .nextBlockAdd:
	add edi, ebx
 .nextBlock:		; this is called when EDI is already pointing to the adj block.
	cmp dword edi, [HEAP_END]
	jae .leaveCall
	jmp .getNextBlock

 .leaveCall:
	popad
	ret


; INPUTS:
;	1: EBX = start 32-bit address.
;	2: EDX = end 32-bit address.
; OUTPUTS:
;	CF status is set if an area of the scanned memory is a reserved section.
; -- Checks for reserved memory sections when the heap expands or is created, and if present will mark the space as allocated.
;		Gets information about the memory from the array at MEM_INFO (PA 0x500).
MEMOPS_INTERNAL_checkValidMemory:
	clc
	push ebp
	mov ebp, esp



	jmp .leaveCall

 .error:
	stc
	jmp .leaveCall

 .leaveCall:
	pop ebp
	ret


; Gets the start addr and lengths of reserved memory spaces and marks the space as taken.
MEMOPS_INTERNAL_setReservedSpaceHeapHeaders:
	clc

	ret
