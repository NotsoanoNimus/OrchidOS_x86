; MACROS.asm
; -- Miscellaneous function macros.

%define TRUE 0x01
%define FALSE 0x00
; Functions which need a size specifier will take these values.
%define BYTE_OPERATION     00h
%define WORD_OPERATION     01h
%define DWORD_OPERATION    02h

; Function macros to make calling a function look 100% more intuitive!
; -- 'func' is a simple alias that expands into a macro, which further expands into a push,call,pop routine.
; -- The alias to the macro automatically enters the args in backwards so they can be easily pushed onto
; ---- the stack from a single, dynamic macro.
; -- I decided to make func lower-case since many of my function defs in the source are capitalized.
; Now function calls can actually look like: function(arg1,arg2,...,argN)
; -- ALSO: Note that the argument will always be DWORD-aligned. This is important for automation.
%define func(a) call a
%define func(a,z) Function a,z
%define func(a,z,y) Function a,y,z
%define func(a,z,y,x) Function a,x,y,z
%define func(a,z,y,x,w) Function a,w,x,y,z
%define func(a,z,y,x,w,v) Function a,v,w,x,y,z

; Define some easy-to-remember accessors for DWORD-pushed arguments!
%define ARG1 dword [ebp+8]
%define ARG2 dword [ebp+12]
%define ARG3 dword [ebp+16]
%define ARG4 dword [ebp+20]

; The Function macro's arg count is always %0-1, which is what is used for situations
; -- that involve the arguments only, such as the push instruction or resetting the Stack Pointer.
%macro Function 2-*
	%rep (%0-1)
		push dword %2
		%rotate 1
	%endrep
	%rotate 1
	call %1
	add esp, (4*(%0-1))
%endmacro


; These two macros are always used in tandem to define an argument-receptive function's beginning & end.
%macro FunctionSetup 0
	push ebp
	mov ebp, esp
%endmacro
%macro FunctionLeave 0
	pop ebp
	ret
%endmacro


; MultiPush & MultiPop are for those pesky 5-line state-saving executions that
; -- get in the way of reading the source.
; I could have used these further in the Function macro, but I'd prefer not to mix them at this time.
; I'd like to thank the NASM macros documentation for these two:
%macro MultiPush 1-*
	%rep %0
		push dword %1
		%rotate 1
	%endrep
%endmacro
%macro MultiPop 1-*
	%rep %0
		pop dword %1
		%rotate 1
	%endrep
%endmacro


; For those pesky multi-line XOR operations that annoy me to no end...
;  Now they'll all drop into one line.
%macro ZERO 1-*
	%rep %0
		xor %1, %1
		%rotate 1
	%endrep
%endmacro



; IF STATEMENT MACROS FOR LEGIBILITY
; s = Signed // u = Unsigned
;IFs ARG1,LSS|LEQ|EQL|NEQ|GEQ|GTR,ARG2,{instruction1},{instruction2},...
;IFu ARG1,LSS|LEQ|EQL|NEQ|GEQ|GTR,ARG2,{instruction1},{instruction2},...
%macro IFs 4-*
	cmp %1, %3
	%ifidni %2,LSS
		jge %%YES
	%elifidni %2,LEQ
		jg %%YES
	%elifidni %2,EQL
		jne %%YES
	%elifidni %2,NEQ
		je %%YES
	%elifidni %2,GEQ
		jl %%YES
	%elifidni %2,GTR
		jle %%YES
	%else
		jmp %%YES
	%endif
	%rep (%0-3)
		%4
		%rotate 1
	%endrep
	%%YES:
%endmacro
%macro IFu 4-*
	cmp %1, %3
	%ifidni %2,LSS
		jae %%YES
	%elifidni %2,LEQ
		ja %%YES
	%elifidni %2,EQL
		jne %%YES
	%elifidni %2,NEQ
		je %%YES
	%elifidni %2,GEQ
		jb %%YES
	%elifidni %2,GTR
		jbe %%YES
	%else
		jmp %%YES
	%endif
	%rep (%0-3)
		%4
		%rotate 1
	%endrep
	%%YES:
%endmacro



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
	;push ebx
	;EBX SHOULD NOT BE SAVED/RESTORED BECAUSE THE INTENT IS TO ONLY CALL THIS FUNCTION ONCE PER OUTPUT OF CERTAIN COLOR.
	mov bl, %2
	mov esi, %1
	call SCREEN_Write
	;pop ebx
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
; TODO: Go back into the source and reassign these to 'func' from above.
%macro KMALLOC 1
	;push ebx
	;xor ebx, ebx
	;mov ebx, %1
	;push dword ebx
	push dword %1
	call kmalloc
	add esp, 4
	;pop ebx
%endmacro
%macro KFREE 1
	;push ebx
	;xor ebx, ebx
	;mov ebx, %1
	;push dword ebx
	push dword %1
	call kfree
	add esp, 4
	;pop ebx
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

%macro STRSCAN 3
	push dword %3
	push dword %2
	push dword %1
	call strscan
	add esp, 12
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


; VIDEO/GUI MODE MACROS
%define VIDEO_RGB(x,y,z) (0x00FFFFFF&(x<<16|y<<8|z))
%define VIDEO_COORDS(x,y) (0xFFFFFFFF&(y<<16|x))
%define VIDEO_CHAR(x) (0x000000FF&x)
