; MEMOPS.asm
; -- Contains memory operations for the kernel, such as kmalloc, kfree, memcpy, etc.
; ---- Also contains system process control.


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
	FunctionSetup
	MultiPush edi,ebx
	clc

	mov ebx, dword [ebp+8]		;arg1
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
	MultiPop ebx,edi
	FunctionLeave


; INPUTS:
;	EBX = starting address of block to free. Basically the block header address is what is going here.
; OUTPUTS:
;	CF on error.
; -- Frees memory used by an application or data. Also skims the headers of the heap to check for holes to merge.
kfree:
	FunctionSetup
	MultiPush edi,eax,ebx,ecx
	clc
	;mov ebp, HEAP_STATUS_BLOCKS_NEXT		; Pointer to the next free block.

	mov dword ebx, [ebp+8]
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
	MultiPop ecx,ebx,eax,edi
	call HEAP_INTERNAL_combineAdjacentMemory
	FunctionLeave



; INPUTS:
;	ARG1 = Source physical address.
;	ARG2 = Destination physical address.
;	ARG3 = Size of copy.
kmemcpy:
	FunctionSetup
	MultiPush esi,edi,ecx
	mov esi, dword [ebp+8]	; arg1 = source addr
	mov edi, dword [ebp+12]	; arg2 = destination addr
	mov ecx, dword [ebp+16]	; arg3 = size
	rep movsb
 .leaveCall:
	MultiPop ecx,edi,esi
 	FunctionLeave



; INPUTS:
; 	ARG1 = Comparison size: 0x01 = Byte // 0x02 = Word // 0x03 = Dword
;	ARG2 = Ptr to start addr in physical memory.
; 	ARG3 = Length to check.
;	ARG4 = Value to check for.
; OUTPUTS: EAX = ptr to matching value. 0x00000000 if no match found.
; -- Compares
kmemcmp:
	FunctionSetup
	MultiPush esi,ecx,ebx
	ZERO eax,ebx,ecx
	; `--> EAX = 0, only will change if a match is found.
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
	MultiPop ebx,ecx,esi
	FunctionLeave


; INPUTS:
;	ARG1 = Start point in RAM.
;	ARG2 = End point in RAM.
;	ARG3 = Base of string to find.
; OUTPUTS:
;	EAX = 0 if failure; pointer to base of string on success.
; Search for an exact string in between two given locations in memory.
; -- Strings follow until a null-termination (or a maximum of 256 bytes in this function to prevent infinite loops).
strscan:
	FunctionSetup
	MultiPush edi,esi,ebx,ecx,edx
	ZERO eax,ebx,ecx,edx

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
 	MultiPop edx,ecx,ebx,esi,edi
	FunctionLeave


; INPUTS:
;	ARG1 = base ptr to string.
; OUTPUTS:
;	EAX = Length. 0 on error/null.
; Return the length of a string (not including the null terminator).
; -- HARD STRLEN LIMIT OF 65535.
strlen:
	FunctionSetup
	MultiPush esi,ecx
	ZERO ecx,eax
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
 	MultiPop ecx,esi
	FunctionLeave
