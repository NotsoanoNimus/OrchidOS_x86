; PROCESS.asm
; -- Process setup and manipulation functions.

%include "libraries/memops/process/PROCESS_definitions.asm"



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
	FunctionSetup
	MultiPush edx,esi
	ZERO edx,ebx

	mov edx, dword [ebp+8]	; EDX = arg1 = kmalloc size
	mov esi, dword [ebp+12] ; ESI = arg2 = base ptr of name str

	; Check the length of the passed string.
	func(strlen,esi); EAX = length of string, 0 on error/empty string.
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
    ;  arg1 - sizeof process in RAM
    ;  arg2 - base ptr to new process allocation
    ;  arg3 - base string ptr to copy
    ;  arg4 - strlen of description string
    func(MEMOPS_PROCESS_TABLE_CREATE_ENTRY,edx,eax,esi,ebx)

	xor ebx, ebx
	mov bl, al		; save returned PID to EBX
	pop eax			; return the entry point to EAX
	jmp .leaveCall

	; issued when there's an error registering the process.
 .error:
 	xor eax, eax	; EAX = 0 return value = error encountered.
    MultiPush edi,ecx,eax

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
    MultiPop eax,ecx,edi
	PrintString szMEMOPS_PROCESS_REGISTRATION_ERROR,0x04
	;bleed
 .leaveCall:
 	MultiPop esi,edx
	FunctionLeave



; INPUTS:
;	ARG1 = Size of Process in RAM.
;	ARG2 = Base of new Process in RAM (header of Heap entry).
;	ARG3 = Base of name string (pre-checked length). Will only copy a max of 22 bytes anyway.
; 	ARG4 = String length.
; OUTPUTS:
;	EAX = Process ID.
; Create a process table entry and copy it into memory in the appropriate location.
MEMOPS_PROCESS_TABLE_CREATE_ENTRY:
	FunctionSetup
	pushad
	ZERO eax,ecx,edx

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

	ZERO eax,ecx
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
 	FunctionLeave



; INPUTS:
;	ARG1 = PID (byte)
; OUTPUTS:
;	EAX = Ptr to base of 32-byte table entry.
; Get the location of a process' table entry with the ID of the process.
MEMOPS_PROCESS_GET_TABLE_ENTRY_BY_PID:
	FunctionSetup
 .leaveCall:
 	FunctionLeave



; A nice, descriptive function name. Clean out the buffer.
MEMOPS_CLEAN_RUNNING_PROCESS_ENTRY_BUFFER:
	MultiPush edi,ecx,eax
	ZERO eax,ecx
	mov edi, RUNNING_PROCESS_ENTRY
	mov cl, (RUNNING_PROCESS_ENTRY_SIZE/4)	; 32 bytes / DWORD operation (4) = 8
	rep stosd		; Zero it all out.
 .leaveCall:
 	MultiPop eax,ecx,edi
 	ret
