; MACROS.asm
; -- Miscellaneous function macros.

%define TRUE 0x01
%define FALSE 0x00
; Functions which need a size specifier will take these values.
%define BYTE_OPERATION     00h
%define WORD_OPERATION     01h
%define DWORD_OPERATION    02h

; PARSER-specific macros to check commands. {L4 means <=4 // G4 means >4}
; Arg1 = Command name in CAPS. Arg2 = command string.
%macro CheckL4CMD 2
	cmp dword [PARSER_COMMAND_NO_ARGS], %2
	jne .Not%1
	call COMMAND_%1
	jmp .returnCMD
  .Not%1:
%endmacro
%macro CheckG4CMD 3
	cmp dword [PARSER_COMMAND_NO_ARGS], %2
	jne .Not%1
	cmp dword [PARSER_COMMAND_NO_ARGS+4], %3
	jne .Not%1
	call COMMAND_%1
	jmp .returnCMD
  .Not%1:
 %endmacro


; PRINT functions (2 args = stringPtr,color // 1 arg = stringPtr)
%macro PrintString 2
	push esi
	mov bl, %2
	mov esi, %1
	call SCREEN_Write
	pop esi
%endmacro
%macro PrintString 1
	push esi
	mov esi, %1
	call SCREEN_Write
	pop esi
%endmacro

; CONSOLE ERROR MESSAGES. Used in "INIT.asm->SYSTEM_tellErrors" only.
; -- Args -> %1 = Message Ptr // %2 = BOOT_ERROR_FLAGS value to check // %3 = Label name.
%macro CONSOLETellError 3
	push dword edx
	and edx, %1
	cmp edx, %1
	jne %3
	PrintString %2
  %3:
	pop dword edx
%endmacro

; Compare BOOT_ERROR_FLAGS to %1, and jump to %2 if they're equal.
%macro CheckErrorFlags 2
    push dword edx
    mov dword edx, [BOOT_ERROR_FLAGS]
    and edx, %1
    cmp dword edx, %1
	pop dword edx
	je %2
%endmacro


; MEMOPS macros.
%macro KMALLOC 1
	push ebx
	xor ebx, ebx
	mov ebx, %1
	push dword ebx
	call kmalloc
	add esp, 4
	pop ebx
%endmacro
%macro KFREE 1
	push ebx
	xor ebx, ebx
	mov ebx, %1
	push dword ebx
	call kfree
	add esp, 4
	pop ebx
%endmacro
%macro MEMCPY 3
	push dword %3
	push dword %2
	push dword %1
	call kmemcpy
	add esp, 12
%endmacro
%macro MEMCMP 4
	push dword %4
	push dword %3
	push dword %2
	push dword %1
	call kmemcmp
	add esp, 16
%endmacro

%macro SLEEP 1
	push eax
	mov eax, %1
	call GLOBAL_SLEEP
	pop eax
%endmacro
%macro SLEEP_noINT 1
	push eax
	mov eax, %1
	sti
	call GLOBAL_SLEEP
	cli
	pop eax
%endmacro
