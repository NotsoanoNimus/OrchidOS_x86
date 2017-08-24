; COLOR.asm
; -- Change the user's text input color.

szCOLORSyntax       db "SYNTAX: Enter a two-digit, 8-bit hex# (ex: 4E). The digits cannot be the same.", 0
szCOLORSyntax2      db " ---> The default color is 0F. See the orchid documentation for more info.", 0

_commandCOLOR:
    cmp byte [PARSER_ARG1_LENGTH], 2
    jne .syntax
    cmp byte [PARSER_ARG2_LENGTH], 0
    jne .syntax
    cmp byte [PARSER_ARG3_LENGTH], 0
    jne .syntax

    mov esi, PARSER_ARG1
    mov bl, 02h
    call UTILITY_HEX_STRINGtoINT    ;AL = color

    ; is the new color 0x00?
    or al, al
    jz .noChange

    ; is the new color two digits that are the same?
    push eax
    mov bl, al
    and bl, 0x0F    ; BL = low nibble
    shr al, 4       ; AL = high nibble
    and al, 0x0F       ; just in case.....
    cmp al, bl
    pop eax
    je .syntax

    mov byte [SHELL_MODE_TEXT_COLOR], al
    jmp .leaveCall

 .syntax:
    mov bl, 0x0C
    mov esi, szCOLORSyntax
    call _screenWrite
    mov esi, szCOLORSyntax2
    call _screenWrite
 .noChange:
 .leaveCall:
    ret
