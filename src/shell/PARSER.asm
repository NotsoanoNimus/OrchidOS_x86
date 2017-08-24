
;CMD parser, polls results and calls appropriate commands.
; Parses input buffer. Is called from the keyboard IR
%include "shell/CMDDIR.asm"

; Arg1 = Command name in CAPS. Arg2 = DWORD of cmp operation (or direct string if >3 chars).
%macro CheckCMD 2
	cmp edx, %2
	jne _parseCommand.Not%1
	call _command%1
	jmp _parseCommand.returnCMD
  .Not%1:
%endmacro

szPARSERNoCMD 	db "Invalid command! Type HELP for commands.", 0
szPARSERSynErr1	db "Parser detected a syntax error in the passed arguments.", 0
szPARSERSynErr2 db "-- Check the orchid documentation for more information about the parser!", 0
PARSER_ARG1_LENGTH db 0x00
PARSER_ARG2_LENGTH db 0x00
PARSER_ARG3_LENGTH db 0x00
PARSER_ARG1 times 64 db 0x00
PARSER_ARG2 times 64 db 0x00
PARSER_ARG3 times 64 db 0x00

iPARSERsaveEIP	dd 0x0	; used so that the popad by dump doesn't pop the return EIP.


_parserCheckQueue:
	pushad
	pushad		; doubled so that the DUMP command can have access to them without actually changing them.
	mov bl, [COMMAND_QUEUE]
	or bl, bl
	jz _parserCheckQueue.noCommand

	;This section will run every time ENTER is hit, so the buffer is always cleared after every entry.
	call _parseCommand
	mov byte [COMMAND_QUEUE], 0
	call _parserClearInput
 .noCommand:
	popad
	popad
	ret


_parseCommand:
	;FIRST READING, finds length of buffer
	mov esi, INPUT_BUFFER	;get base addr of input
	xor ecx, ecx			;length counter
	xor edx, edx			;prevents a second reading on cmds 4 chars or smaller
 .repeatFirstRead:
	lodsb
	cmp al, 0x20	; look for space
	je _parseCommand.parseArguments
	cmp al, 0x00	; or find the null terminator
	je _parseCommand.endFirstRead
	inc ecx
	shl edx, 8		; Get the most recent character and push it up to the higher parts of the register.
					; --This can be done up to 4 times before this instruction becomes useless for this reading.
					; KEEP IN MIND: This is reading chars left-to-right, NOT little-endian, due to the shifting.
	mov dl, al
	jmp _parseCommand.repeatFirstRead

	; The .return label is only for exiting commands to use. Otherwise, the default return is to give an error msg.
.endFirstRead:		; ECX is now = to the buffer length. Use this to narrow down the command tests.
	cmp ecx, 0
	je _parseCommand.returnCMD		; Check if the user even wrote anything. If not, exit with no output.
	cmp ecx, 2		; 2-letter cmd
	jg _parseCommand.not2
	jmp _parseCommand.returnWMSG
 .not2:
	cmp ecx, 3
	jg _parseCommand.not3
	CheckCMD CLS,0x00636C73		;"cls"
	CheckCMD SYS,0x00737973 	;"sys"
	CheckCMD USR,0x00757372		;"usr"
	jmp _parseCommand.returnWMSG
 .not3:
	cmp ecx, 4
	jg _parseCommand.not4
	CheckCMD HELP,0x68656C70	;"help"
	;CheckCMD DUMP,0x64756D70	;"dump" -- This one has to be different because of the pushad/popad.
	cmp edx, 0x64756D70
	jne _parseCommand.NotDUMP
	pop dword [iPARSERsaveEIP]	; save the EIP return pointer pushed due to the CALL opcode.
	popad						; restore everything.
	call _commandDUMP
	pushad						; correcting stack pop offset here.
	push dword [iPARSERsaveEIP]	; restore the ret ptr.
	jmp _parseCommand.returnCMD
  .NotDUMP:
	CheckCMD MEMD,0x6D656D64	;"memd"
	CheckCMD CONN,0x636F6E6E	;"conn"
	jmp _parseCommand.returnWMSG
 .not4:
	cmp ecx, 5
	jg _parseCommand.not5
	CheckCMD START,0x74617274  ;"tart"
	CheckCMD COLOR,0x6F6C6F72  ;"olor"
	jmp _parseCommand.returnWMSG
 .not5:
	cmp ecx, 6
	jg _parseCommand.not6
	;CheckCMD (some 6-letter CMD),0x00000000
	jmp _parseCommand.returnWMSG
 .not6:				; at this point, the cmds left to check aren't many.
	jmp _parseCommand.returnWMSG

 .returnWMSG:
	mov esi, szPARSERNoCMD
	mov bl, 0x04
	call _screenWrite
 .returnCMD:
	ret

 .parseArguments:
 	or ecx, ecx
	jz .endFirstRead
 	call PARSER_parseArguments		; Check if there were arguments after the command.
 	jc .syntaxError
	jmp .endFirstRead				; on success, process which command is being called.
 .syntaxError:
 	mov bl, 0x0C
	mov esi, szPARSERSynErr1
	call _screenWrite
	mov esi, szPARSERSynErr2
	call _screenWrite
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Clean all 256 bytes of input (set to 0x00).
; Also clean the parser's argument buffers.
_parserClearInput:
	pushad
	mov edi, INPUT_BUFFER
	xor eax, eax
	mov ecx, 100h
	rep stosb
	mov edi, PARSER_ARG1
	mov ecx, 64*3
	rep stosb
	mov byte [PARSER_ARG1_LENGTH], 0x00
	mov byte [PARSER_ARG2_LENGTH], 0x00
	mov byte [PARSER_ARG3_LENGTH], 0x00
	popad
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; At start:
;	ESI = First char of arg1
; CF is set if there is an error, mainly a missing closing quote or parenthesis.
; -- Parse arguments into their appropriate spaces.
PARSER_parseArguments:
	pushad
	mov edi, PARSER_ARG1	;Parsing the first argument first (obv).
	xor edx, edx			; EDX = current arg#
	xor ebx, ebx			; EBX = index into current arg (non-DQ)
	xor eax, eax

 .nextArgument:
 	push edi	; save starting EDI (base of each arg's buffer).
 	;inc edx		; starts at 1
	xor ebx, ebx	; reset arg index
	lodsb	;check first character for double-quote or sloppy input.
	cmp al, 0x22	;'"'
	je .dQuotes
	cmp al, 0x20	;was there a second space between args? If so, we're not having any of that sloppy input...
	jne .storeArg
	jmp .error
 .storeArg:
 	cmp al, 0x20		; SPACE means next arg. Guaranteed not to be the first parsed character by failsafe above.
	je .prepNext
	cmp al, 0x00		; Null terminator = end of input.
	je .cleanExit		;  When found, cleanly exit (no CF).
	inc ebx
	cmp ebx, 65			; exceeding buffer size?? Is this arg about to bleed into its neighbor?
	je .error			;  if so, exit with error status. User entered an argument that's too long.
	inc byte [PARSER_ARG1_LENGTH+edx]	;increase strlen
	stosb
 .nextChar:
 	lodsb
	jmp .storeArg
 .prepNext:
 	pop edi
	add edi, 64		; go to next arg base.
	inc edx		; starts at 0.
 	cmp edx, 3
	jne .nextArgument
	jmp .testFourthArg


 .dQuotes:		; come here when argN[0] = a double-quote.
  	xor ecx, ecx
   .storeDQ:
	lodsb
	or al, al	; if the end is reached before terminating quote, set error status.
	je .error
	cmp al, 0x22
	je .doneDQ
	inc ecx
	cmp ecx, 65	; does string exceed 64 bytes?
	je .error
	stosb
	jmp .storeDQ
   .doneDQ:
    lodsb
	cmp al, 0x20	; make sure character following closing quote is a space separator.
	jne .error
	cmp al, 0x00
	je .cleanExit
	jmp .prepNext

 .testFourthArg:	; a quick test to ensure the user didn't append crap to the end of the third arg.
 	lodsb
	or al, al
	jnz .error4th		; these need special labels, since EDI has already been popped...
	jmp .cleanExit4th
 .cleanExit:
 	pop edi
   .cleanExit4th:
	clc
	jmp .leaveCall
 .error:
 	pop edi
   .error4th:
 	stc
 .leaveCall:
	popad
	ret
