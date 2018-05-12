; MEMOPS.asm
; -- Contains memory operations for the kernel, such as kmalloc, kfree, memcpy, etc.
; ---- Also contains system process control.
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

RUNNING_PROCESS_NEXT_GIVEN_ID	db 0x00				; Verbose name. Lists the next ID to be delegated.
; Next PID is always 1 initially because SYS is PID 0.
RUNNING_PROCESS_ENTRY_SIZE		equ 32				; 32 bytes per entry
RUNNING_PROCESS_ENTRY:
	.entry:		dd 0x00000000	; entry point in RAM of the process' data
	.size:		dd 0x00000000	; size of the process' allocation
	.name:		times 22 db 0x00; ASCII name representation of the process. For informational purposes only.
	.nameTerm:	db 0x00			; forced null-terminator of the string.
	.pid:		db 0x00			; process ID, used in all manipulations of the process instead of the name.

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



; INPUTS:
;	ARG1 = Size of allocation.
;	ARG2 = String base ptr of process name.
; OUTPUTS:
;	EAX = Starting address of allocated space. If 0, failure.
;	EBX = Process ID (BL).
; Call kmalloc to allocate heap space, but also register the process.
; -- !!! RUNNING_PROCESSES_TABLE is located @0x70000.
; ---- See top of this file (definitions) for the structure of a RUNNING_PROCESS_ENTRY.
szMEMOPS_PROCESS_REGISTRATION_ERROR db "Unable to register process with name: "
szMEMOPS_PROCESS_REGISTRATION_ERROR_STRING times 22 db 0x00
db 0x00 ; null-term.
MEMOPS_KMALLOC_REGISTER_PROCESS:
	push ebp
	mov ebp, esp
	push edx
	push esi

	xor edx, edx
	xor ebx, ebx
	mov edx, dword [ebp+8]	; EDX = arg1 = kmalloc size
	mov esi, dword [ebp+12] ; ESI = arg2 = base ptr of name str

	; Check the length of the passed string.
	push esi
	call strlen		; EAX = length of string, 0 on error/empty string.
	add esp, 4
	or eax, eax
	jz .error		; EAX = 0 = error!
	cmp eax, 22		; Is EAX gtr 22?
	ja .error		; If so, leave with error.
	mov ebx, eax	; EBX = strlen

	KMALLOC edx		; allocate required space and return the pointer to the allocated block. EAX = ptr
	jc .error		; On CF, error.
	or eax, eax		; On EAX = 0, error.
	jz .error

	push eax		; save process entry point
	; Create the process entry, enter it into memory.
	push ebx		; arg4 - strlen of description string
	push esi		; arg3 - base string ptr to copy
	push eax		; arg2 - base ptr to new process allocation
	push edx		; arg1 - sizeof process in RAM
	call MEMOPS_PROCESS_TABLE_CREATE_ENTRY
	add esp, 16

	xor ebx, ebx
	mov bl, al		; save returned PID to EBX
	pop eax			; return the entry point to EAX
	jmp .leaveCall

	; issued when there's an error registering the process.
 .error:
 	xor eax, eax	; EAX = 0 return value = error encountered.
	push edi
	push ecx
	push eax	; save 0

	; clean old process desc string from error buffer.
	mov edi, szMEMOPS_PROCESS_REGISTRATION_ERROR_STRING
	mov ecx, 22	; 22 chars to clear
	rep stosb	; clear the 22 characters

	push dword [ebp+12]	; process desc string base address
	call strlen			; get its length
	add esp, 4

	cmp eax, 22		; length > 22 chars?
	jbe .errorStrNoShorten	; if <= 22 chars, good to go, else bleed to shorten func
	mov eax, 22		; hard length cap of 22 chars
   .errorStrNoShorten:
    ; perform a memcpy operation, from desc string pointer -> process error, w/ length '[strlen]'
	MEMCPY [ebp+12],szMEMOPS_PROCESS_REGISTRATION_ERROR_STRING,eax

	pop eax	; restore 0
	pop ecx ; restore
	pop edi	; restore
	PrintString szMEMOPS_PROCESS_REGISTRATION_ERROR,0x04
	;bleed
 .leaveCall:
 	pop esi
	pop edx
 	pop ebp
	ret



; INPUTS:
;	ARG1 = Size of Process in RAM.
;	ARG2 = Base of new Process in RAM (header of Heap entry).
;	ARG3 = Base of name string (pre-checked length). Will only copy a max of 22 bytes anyway.
; 	ARG4 = String length.
; OUTPUTS:
;	EAX = Process ID.
; Create a process table entry and copy it into memory in the appropriate location.
MEMOPS_PROCESS_TABLE_CREATE_ENTRY:
	push ebp
	mov ebp, esp
	pushad

	xor eax, eax
	xor ecx, ecx
	xor edx, edx

	call MEMOPS_CLEAN_RUNNING_PROCESS_ENTRY_BUFFER	; ready the buffer for new information.

	; Prepare the RUNNING_PROCESS_ENTRY fields after they were cleaned.
	mov edi, RUNNING_PROCESS_ENTRY
	mov eax, dword [ebp+12]	;arg2 - base
	stosd
	mov eax, dword [ebp+8]	;arg1 - sizeof process
	stosd

	mov esi, dword [ebp+16]	;arg3 - str ptr
	mov ecx, dword [ebp+20]	;arg4 - strlen
	push edi	; save edi location

	rep movsb

	pop edi		; return to the front of the string...
	add edi, 23	; and add the sizeof the whole string field (+null-term)

	mov al, strict byte [RUNNING_PROCESS_NEXT_GIVEN_ID]	; get next PID
	stosb	; store it

	push eax	; save before increment
	inc al	; increment it
	cmp al, SYSTEM_MAX_RUNNING_PROCESSES	; AL (next PID delegation) > 128?
	ja .maxPIDs
	mov strict byte [RUNNING_PROCESS_NEXT_GIVEN_ID], al	; put it back in

	; Point EDI to the proper place to prepare the memcpy
	mov edi, RUNNING_PROCESSES_TABLE			; EDI = base of running process table.

	xor eax, eax
	xor ecx, ecx
	pop ecx		; restore saved pre-incremented PID into CL
	mov al, RUNNING_PROCESS_ENTRY_SIZE			; sizeof entry (32 bytes)
	;mov cl, byte [RUNNING_PROCESS_NEXT_GIVEN_ID]; x next delegated PID
	mul cl										; = table offset

	add edi, eax		; add on the offset, EDI now points to where the data goes
	jmp .enterIntoRAM

 .maxPIDs:	; called if the maximum process count is reached.
 	; find which processes have ended and are available in the RUNNING_PROCESSES_TABLE.
	; search for gaps. If none are found, notify the system.
	;call MEMOPS_PROCESS_MAX_PIDS	; EAX should = new PID. If EAX = 0xFF, no more available PIDs.
	jmp .maxPIDsExit

 .enterIntoRAM:
	MEMCPY RUNNING_PROCESS_ENTRY,edi,RUNNING_PROCESS_ENTRY_SIZE	; copy it into RAM.
 .incrementPID:
 	popad
	xor eax, eax
	mov al, byte [RUNNING_PROCESS_NEXT_GIVEN_ID]
	dec al	; AL has to equal the running PID that was actually assigned to the process.
	jmp .leaveCall

 .maxPIDsExit:	; EAX already set to PID here.
 	popad
 .leaveCall:
 	pop ebp
	ret



; INPUTS:
;	ARG1 = PID (byte)
; OUTPUTS:
;	EAX = Ptr to base of 32-byte table entry.
; Get the location of a process' table entry with the ID of the process.
MEMOPS_PROCESS_GET_TABLE_ENTRY_BY_PID:
	push ebp
	mov ebp, esp


 .leaveCall:
 	pop ebp
	ret



; A nice, descriptive function name. Clean out the buffer.
MEMOPS_CLEAN_RUNNING_PROCESS_ENTRY_BUFFER:
	push edi
	push ecx
	push eax
	xor eax, eax
	xor ecx, ecx
	mov edi, RUNNING_PROCESS_ENTRY

	mov cl, (RUNNING_PROCESS_ENTRY_SIZE/4)	; 32 bytes / DWORD operation (4) = 8
	rep stosd		; Zero it all out.

 .leaveCall:
 	pop eax
 	pop ecx
 	pop edi
 	ret



; INPUTS:
;	ARG1 = size of allocation in bytes (into EBX).
; OUTPUTS:
;	EAX = starting address of allocated space. 0 on error.
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

	mov ebx, dword [ebp + 16]		;arg1
	or ebx, ebx		; arg1 = 0?
	jz .error		; if so, don't alloc anything, set error state.
	add ebx, HEAP_HEADER_SIZE_RAM
	add ebx, HEAP_FOOTER_SIZE_RAM	; add on the baggage that comes with creating new spaces.
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
	jae .noSpaceLeft
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
	; Have to add the header's size to the returned base allocation handle/pointer,
	;  or else system processes that use this handle will overwrite a heap header.
	add eax, HEAP_HEADER_SIZE_RAM

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


; INPUTS:
;	ARG1 = Start point in RAM.
;	ARG2 = End point in RAM.
;	ARG3 = Base of string to find.
; OUTPUTS:
;	EAX = 0 if failure; pointer to base of string on success.
; Search for an exact string in between two given locations in memory.
; -- Strings follow until a null-termination (or a maximum of 256 bytes in this function to prevent infinite loops).
strscan:
	push ebp
	mov ebp, esp
	push edi
	push esi
	push ebx
	push ecx
	push edx

	; zero registers
	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx

	; get arguments moved in
	mov ebx, dword [ebp+8]	;EBX = arg1 = start
 .newStartingPoint:
	mov edx, dword [ebp+12]	;EDX = arg2 = end
	mov esi, dword [ebp+16]	;ESI = arg3 = base ptr of string.

	; check the end vs start point for a negative difference.
	sub edx, ebx	; EDX = end - start (length of search)
	js .leaveCall	; If the result is negative, exit with EAX = 0 to show error/nothing found.
	mov cl, strict byte [esi] 	; ECX = 0x000000[ASCII char code]

	MEMCMP BYTE_OPERATION,ebx,edx,ecx
	; if EAX != 0, it's a ptr to a matching ASCII character. Set EDI to it, inc esi, and compare.
	; If there's a mismatch, take the last ESI value, add 1 and start a new MEMCMP to prevent infinite searches
	; over the same spot.
	or eax, eax
	je .leaveCall	; failure.
	;else: bleed
 	mov edi, eax	; Matched ASCII char @EAX
	push eax		; save inital spot in case it's a match
 .keepSearching:
	inc edi			; check the next char up
	inc esi			; on each string
	mov al, strict byte [esi]
	mov ah, strict byte [edi]
	cmp al, ah
	;cmp al, strict byte [edi]
	jne .continueInitialScan
	or al, al	; was AL the null-terminator?
	jz .stringFound
	jmp .keepSearching	; everything is matching, keep going.

 .continueInitialScan:
 	mov ebx, edi	; start at previously-matched address+1 to prevent looping
	pop eax			; delete inital-point save
	xor eax, eax	; EAX = 0 in case of error.
	jmp .newStartingPoint

 .stringFound:
 	pop eax		; restore saved point
	;bleed to end
 .leaveCall:
 	pop edx
 	pop ecx
	pop ebx
	pop esi
	pop edi
 	pop ebp
	ret


; INPUTS:
;	ARG1 = base ptr to string.
; OUTPUTS:
;	EAX = Length. 0 on error/null.
; Return the length of a string (not including the null terminator).
; -- HARD STRLEN LIMIT OF 65535.
strlen:
	push ebp
	mov ebp, esp
	push esi
	push ecx

	xor ecx, ecx
	xor eax, eax
	mov esi, dword [ebp+8]	; ESI = arg1 = base ptr
 .checkLength:
 	lodsb
	or al, al	; AL = 0 (null-term)?
	jz .done
	inc ecx		; increment counter.
	cmp ecx, 0x00010000		; 65535 byte string maximum.
	jae .error
	jmp .checkLength

 .error:	; called if the passed string is extremely long and exceeds hard strlen limit.
 	xor eax, eax	; Set error condition
	jmp .leaveCall	; leave
 .done:
 	mov eax, ecx	; put counter into EAX.
	;bleed
 .leaveCall:
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
