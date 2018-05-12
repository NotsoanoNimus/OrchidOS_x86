; DATA_OPS.asm
; -- Contains functions for manipulating memory in data, whether in RAM or in a preparatory state.

; INPUTS:
;   ARG1 = Starting physical location of the WORD(s) to change Endianness.
;   ARG2 = Number of iterations (WORD).
DATA_WORD_switch_endian:
    push ebp
    mov ebp, esp
    pushad

    mov edi, dword [ebp + 8]    ;arg1 - address
    mov ecx, dword [ebp + 12]   ;arg2 - count

    ; quick check for count = 0 (for whatever reason)
    or ecx, ecx
    jz .leaveCall

 .repeat:
    xor eax, eax
    mov ax, strict word [edi]   ; AX = Word from memory
    rol ax, 8       ; 180-degree rotation of the value
    stosw           ; put it back, EDI+2
    dec ecx         ; decrement counter
    or ecx, ecx     ; count = 0?
    jnz .repeat
    ;bleed
 .leaveCall:
    popad
    pop ebp
    ret


; Same arguments as above function, but for DWORD-sized endianness changes.
DATA_DWORD_switch_endian:
    push ebp
    mov ebp, esp
    pushad

    mov edi, dword [ebp + 8]    ;arg1 - address
    mov ecx, dword [ebp + 12]   ;arg2 - count

    ; quick check again for count = 0
    or ecx, ecx
    jz .leaveCall

 .repeat:
    xor eax, eax
    xor ebx, ebx
    mov eax, strict dword [edi] ; Extract the DWORD contents at EDI

    mov ebx, eax        ; Copy EAX into EBX
    shr eax, 16     ; AX = high WORD
    and ebx, 0x0000FFFF ; BX = low WORD
    rol ax, 8
    rol bx, 8       ; rotate both of them 180 degrees.
    shl ebx, 16     ; EBX = 0xXXXX0000
    or eax, ebx    ; Put it into EAX high WORD. Should now be successfully reversed.

    stosd           ; put it back in, EDI+4
    dec ecx         ; decrement counter
    or ecx, ecx     ; count = 0?
    jnz .repeat

 .leaveCall:
    popad
    pop ebp
    ret
