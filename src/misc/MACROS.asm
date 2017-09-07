; MACROS.asm
; -- Miscellaneous function macros.

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



%macro CheckErrorFlags 2
    push dword edx
    mov dword edx, [BOOT_ERROR_FLAGS]
    and edx, %1
    cmp dword edx, %1
	pop dword edx
	je %2
%endmacro
