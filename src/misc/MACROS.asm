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


; Generic operational macros.
; -- Not necessary to define the 1-param funcs, but would prefer
;     not to suppress any of NASM's warnings.
%macro push 1
	push %1
%endmacro
%macro push 2
	push %1
	push %2
%endmacro
%macro push 3
	push %1
	push %2
	push %3
%endmacro
%macro pop 1
	pop %1
%endmacro
%macro pop 2
	pop %1
	pop %2
%endmacro
%macro pop 3
	pop %1
	pop %2
	pop %3
%endmacro
%define push(a) push a
%define push(a,b) push a,b
%define push(a,b,c) push a,b,c
%define pop(a) pop a
%define pop(a,b) pop a,b
%define pop(a,b,c) pop a,b,c
