; MACROS.asm
; -- Miscellaneous function macros.

%define TRUE 0x01
%define FALSE 0x00
; Functions which need a size specifier will take these values.
%define BYTE_OPERATION     00h
%define WORD_OPERATION     01h
%define DWORD_OPERATION    02h

; PARSER-specific macro to check commands.
; Arg1 = Command name in CAPS. Arg2 = DWORD of cmp operation (or direct string if >3 chars).
%macro CheckCMD 2
	cmp edx, %2
	jne _parseCommand.Not%1
	call _command%1
	jmp _parseCommand.returnCMD
  .Not%1:
%endmacro


; PRINT functions (2 args = stringPtr,color // 1 arg = stringPtr)
%macro PrintString 2
	mov bl, %2
	mov esi, %1
	call _screenWrite
%endmacro
%macro PrintString 1
	mov esi, %1
	call _screenWrite
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
%macro MEMCPY 2
	push %2
	push %1
	call kmemcpy
%endmacro

%macro MEMCMP 4
	push dword %4
	push dword %3
	push dword %2
	push dword %1
	call MEMCMP_func
%endmacro
