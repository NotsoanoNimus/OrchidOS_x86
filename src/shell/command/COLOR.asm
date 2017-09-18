; COLOR.asm
; -- Change the user's text input color. Is slightly problematic when interacting with screen wrapper functions.

szCOLORSyntax       db "SYNTAX: Enter a two-digit, 8-bit hex# (ex: 4E). The digits cannot be the same.", 0
szCOLORSyntax2      db " ---> The default color is 0F. See the orchid documentation for more info.", 0

COMMAND_COLOR:
    cmp byte [PARSER_ARG1_LENGTH], 2
    jne .syntax
    cmp byte [PARSER_ARG2_LENGTH], 0
    jne .syntax
    cmp byte [PARSER_ARG3_LENGTH], 0
    jne .syntax

    mov esi, PARSER_ARG1
    mov bl, 02h
    call UTILITY_HEX_STRINGtoINT    ;AL = color
    jc .syntax

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
    PrintString szCOLORSyntax,0x0C
    PrintString szCOLORSyntax2
 .noChange:
 .leaveCall:
    ret
