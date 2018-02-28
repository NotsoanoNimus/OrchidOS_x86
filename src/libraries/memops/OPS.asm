; MEMOPS.asm
; --- Contains memory operations for the kernel, such as kmalloc, kfree, memcpy, etc.
; ----- HEAP SETUP IS GOING TO BE DONE HERE.
;
;
; MEM_INFO = 0x500, signature 0x1234xxxx, 24-byte entries.
;	ENTRY FORMAT (bytes):
;	 * 0-7:   Starting address.
;	 * 8-15:  Offset.
;	 * 16-19: Type of memory (01 = free, 02+ = reserved)
;	 * 20-23: Always 0x00000001.

HEAP_STATUS_BLOCKS_STACK_BOTTOM	equ 0x00070000		;Secondary stack for pointers to available memory blocks.
HEAP_STATUS_BLOCKS_NEXT			 dd 0x00000000		; Contains saved stack pointer.

HEAP_BLOCK_CLEAN				equ 0x00			; Block is free.
HEAP_BLOCK_DIRTY				equ 0x01			; Block is being accessed.

; HEAP_INFO information (pointers).
HEAP_PID_COUNT					equ 0x0006FFFC		;Ptr to dword at 0x6FFF8: counts how many processes running. Will be used to thread/multitask w/ IRQ0.
HEAP_CURRENT_SIZE				equ 0x0006FFF8		;Ptr to dword at 0x6FFF0: keeps track of the current heap size.
HEAP_END						equ 0x0006FFF4		; Contains a pointer to the end of the heap. This variable changes as the heap size changes.
HEAP_MAX_SIZE					equ 0x0006FFF0		;Pointer to heap max size. Scalable within the program.

HEAP_START						equ 0x00100000		; Heap starting point. Static variable.
HEAP_INIT_SIZE					equ 0x01000000		; 16 MiB.
;HEAP_MAX_SIZE					equ 0x80000000		; 2GiB Heap Max. UNSURE ABOUT THIS.

HEAP_HEADER_MAGIC				equ 0xBEABEA57		; "MAGIC" (header)
HEAP_FOOTER_MAGIC				equ 0xDEADBEEF		; "MAGIC" (footer)
HEAP_HEADER_SIZE				equ 12				; Headers are 9-byte objects. Round them to 12, so it's DWORD-aligned.
HEAP_FOOTER_SIZE				equ 8				; Footers do not have a hole identifier.

; HEAP SIGNATURES:
;	Header...
;		Magic		DWORD	'0xBEABEA57' --signature
;		Size		DWORD	-- Length of the allocated block.
;		Dirty		BYTE	'0x00'=Not accessed/clean. 0x01 = Dirty.
;	Footer...
;		Magic		DWORD	'0xDEADBEEF' --signature
;		Header Ptr	DWORD	-- Physical address of section header.
szHeapInitFailed		db "Heap initialization failure. Cause unknown.", 0
MEMOPS_initHeap:
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
	pop edi
	push edi
	mov eax, edi					; save header address
	mov dword [edi], HEAP_HEADER_MAGIC
	add edi, 4
	mov dword [edi], HEAP_INIT_SIZE
	add edi, 4
	mov byte [edi], HEAP_BLOCK_CLEAN

	pop edi
	add edi, HEAP_INIT_SIZE			; Step forward to 0x0110000	(16MiB heap)
	sub edi, HEAP_FOOTER_SIZE		; prepare to write the footer. Should be put EDI at 0x010FFFF8

	mov dword [edi], HEAP_FOOTER_MAGIC
	add edi, 4
	mov dword [edi], eax
	add edi, 4

	mov dword [HEAP_END], edi					; HEAP_END should now contain 0x01100000.
	mov dword [HEAP_PID_COUNT], 0x00000001		; Only one process running to start, which is SYS_KERNEL.
	mov dword [HEAP_CURRENT_SIZE], 0x01000000	; 16MiB initialization.

	mov dword edx, [iMemoryFree]				; Get total free memory.
	sub edx, 0x00100000							; Subtract the kernel space.
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


; INPUTS:
;	EBX = size of allocation in bytes.
; OUTPUTS:
;	EAX = starting address of allocated space.
;	CF on error.
; -- Allocate memory to be used by an application. Return the starting address of the HEAP_HEADER_MAGIC signature.
;		Follows a complex algorithm to accomplish its task. Reads headers and footers and determines the proper mem placement based on size.
;		ALLOCATION SPACE NEEDED WILL BE = ARG1+HEADER_SIZE+FOOTER_SIZE, OTHERWISE THIS WILL LEAK HORRIBLY.
;	Blocks are allocated on 256-byte boundaries.
kmalloc:
	clc
	push edi
	push ebx
	push ebp
	mov ebp, esp

	mov ebx, [ebp + 16]		;arg1
	add ebx, HEAP_HEADER_SIZE
	add ebx, HEAP_FOOTER_SIZE	; add on the baggage that comes with creating new spaces.
	add ebx, 0x100				; align the space to a minimum of 256 bytes.
	and ebx, 0xFFFFFF00

	; Check the total memory size and see if it's even possible to store this.
	;push

	mov edi, HEAP_START
 .searchHeap:				; search for the first MAGIC identifier.
	cmp dword [edi], HEAP_HEADER_MAGIC
	je .headerFound
	add edi, 256			; this area should technically never run, as HEAP_START should always have a header and subseq calcs should be accurate.
	cmp dword edi, [HEAP_END]	;Did the heap run out of space?
	jge .noSpaceLeft
	jmp .searchHeap		; it's a very slow alloc method, so here's to hoping it never runs!

 .headerFound:
	cmp byte [edi+8], HEAP_BLOCK_DIRTY		; is this block occupied?
	je .nextBlock
	cmp dword [edi+4], ebx
	jge .spaceFound		; if the size indicator in the header is bigger than the allocation size + header&footer, we're going to place here.
	jmp .nextBlock

 ; search the next header section for a large enough space.
 .nextBlock:
	add edi, [edi+4]	;set EDI to the next header.
	cmp dword [edi], HEAP_HEADER_MAGIC
	jne .searchHeap		; If the magic header wasn't found, we're going to need to search manually.
	jmp .headerFound	; If it was found, we can do our checks again.

 .spaceFound:
	; It found a space, cool! Now arrange some H&Fs.
	; At the start of this function, EDI is pointing to the header of the free section.
	; Need to edit the header, create a new hole after the allocated footer, ...
	;  then finally change the original space's footer to point back at the new hole header that was made.
	xor eax, eax
	mov dword eax, edi			; EAX = address of allocated memory.

	push edx
	push ecx
	mov edx, edi				; save header address.
	mov dword ecx, [edi+4]		; save header's original block size.
	push ecx					; save the original block size before getting the delta.
	sub ecx, ebx				; Get the size of the leftover hole.

	push edi

	mov dword [edi+4], ebx		; overwrite the old space's size with the new size.
	mov byte [edi+8], HEAP_BLOCK_DIRTY	;This block's taken now.
	add edi, ebx
	sub edi, HEAP_FOOTER_SIZE
	mov dword [edi], HEAP_FOOTER_MAGIC
	mov dword [edi+4], edx		; write header address to the footer.

	add edi, 8					; position EDI to write the new header for the leftover hole.
	mov dword [edi], HEAP_HEADER_MAGIC
	mov dword [edi+4], ecx		; size of the hole.
	mov byte [edi+8], HEAP_BLOCK_CLEAN

	mov edx, edi				; EDX = new hole's header address

	pop edi						; Go back to header of newly-filled section.
	pop ecx						; Get back the original width of the whole free block.
	add edi, ecx				; position EDI to the original block's footer
	sub edi, HEAP_FOOTER_SIZE	; `-- with this calculation.

	mov dword [edi], HEAP_FOOTER_MAGIC
	mov dword [edi+4], edx

	pop ecx
	pop edx

	jmp .leaveCall


 .noSpaceLeft:
	; Test the heap_end for the heap_max value.
	mov dword edi, [HEAP_END]
	add edi, ebx
	cmp dword edi, [HEAP_MAX_SIZE]
	ja .error

	; Expand the heap to fit the new header and program.
	add dword [HEAP_CURRENT_SIZE], ebx
	mov dword edi, [HEAP_END]
	xor eax, eax
	mov dword eax, edi	; EAX = returned address of new header start.

	push edx
	xor edx, edx
	mov edx, edi		; EDX = HEAP_END, or new header start addy
	mov dword [edi], HEAP_HEADER_MAGIC
	mov dword [edi+4], ebx
	mov dword [edi+8], HEAP_BLOCK_DIRTY

	add edi, ebx
	sub edi, HEAP_FOOTER_SIZE
	mov dword [edi], HEAP_FOOTER_MAGIC
	mov dword [edi+4], edx
	pop edx

	add edi, 8
	mov dword [HEAP_END], edi
	jmp .leaveCall

 .error:
	xor eax, eax		; EAX returning zero means allocation wasn't possible.
	stc
 .leaveCall:
	pop ebp
	pop ebx
	pop edi
	ret


; INPUTS:
;	EBX = starting address of block to free. Basically the block header address is what is going here.
; OUTPUTS:
;	CF on error.
; -- Frees memory used by an application or data. Also skims the headers of the heap to check for holes to merge.
kfree:
	clc
	push edi
	push eax
	push ebx
	push ecx
	push ebp
	mov ebp, esp
	;mov ebp, HEAP_STATUS_BLOCKS_NEXT		; Pointer to the next free block.

	mov dword ebx, [ebp + 24]
	mov edi, ebx

	cmp dword [edi], HEAP_HEADER_MAGIC
	jne .error
	mov dword ecx, [edi+4]				; Get length of block.
	mov byte [edi+8], HEAP_BLOCK_CLEAN	; Mark the block as clean.
	sub ecx, HEAP_HEADER_SIZE
	sub ecx, HEAP_FOOTER_SIZE
	add edi, HEAP_HEADER_SIZE			; Put EDI at the start of the actual data.

	; Editing the footer isn't necessary.
	xor eax, eax
	rep stosb							; Zero the whole section, except for header and footer.

	jmp .leaveCall

 .error:
	stc
 .leaveCall:
	pop ebp
	pop ecx
	pop ebx
	pop eax
	pop edi
	call HEAP_INTERNAL_combineAdjacentMemory
	ret



; INPUTS:
;	ARG1 = Source physical address.
;	ARG2 = Destination physical address.
;	ARG3 = Size of copy.
kmemcpy:
	push ebp
	mov ebp, esp
	push esi
	push edi
	push ecx

	mov esi, dword [ebp+8]	; arg1 = source addr
	mov edi, dword [ebp+12]	; arg2 = destination addr
	mov ecx, dword [ebp+16]	; arg3 = size
	rep movsb

 .leaveCall:
 	pop ecx
 	pop edi
	pop esi
 	pop ebp
	ret



; INPUTS:
; 	ARG1 = Comparison size: 0x01 = Byte // 0x02 = Word // 0x03 = Dword
;	ARG2 = Ptr to start addr in physical memory.
; 	ARG3 = Length to check.
;	ARG4 = Value to check for.
; OUTPUTS: EAX = ptr to matching value. 0x00000000 if no match found.
; -- Compares
kmemcmp:
	push ebp
	mov ebp, esp
	push esi
	push ecx
	push ebx

	xor eax, eax	; EAX = 0, only will change if a match is found.
	xor ebx, ebx
	xor ecx, ecx
	mov dword ebx, [ebp+8]	;arg1 - Size
	mov dword esi, [ebp+12]	;arg2 - Start addr
	mov dword ecx, [ebp+16]	;arg3 - Length
	mov dword edx, [ebp+20]	;arg4 - Cmp value.

	cmp dword ebx, DWORD_OPERATION	;dword?
	je .dwordSearch
	and edx, 0x0000FFFF				; cut off DWORD portion of arg4.
	cmp dword ebx, WORD_OPERATION	;word?
	je .wordSearch
	and edx, 0x000000FF				; cut off WORD potion of arg4.
	cmp dword ebx, BYTE_OPERATION	;byte?
	je .byteSearch
	; if this point is reached, the argument contains an invalid value. Error-exit.
 .errorExit:
	jmp .leaveCall

 .byteSearch:
	cmp strict byte [esi], dl
	je .matchFound
	inc esi
 	loop .byteSearch
	jmp .errorExit

 .wordSearch:
	cmp strict word [esi], dx
	je .matchFound
	inc esi
	loop .wordSearch
	jmp .errorExit

 .dwordSearch:
	cmp strict dword [esi], edx
	je .matchFound
	inc esi
	loop .dwordSearch
	jmp .errorExit

 .matchFound:
	mov eax, esi
 .leaveCall:
 	pop ebx
	pop ecx
	pop esi
	pop ebp
	ret


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
	push ecx
	push eax
	push edi
	xor eax, eax
	mov ecx, 0x00000014					; 20 iterations
	sub edi, HEAP_FOOTER_SIZE			; Position EDI at the beginning of the footer next to the header of the 2nd hole.
	rep stosb							; Clear to 0
	pop edi
	pop eax
	pop ecx

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
