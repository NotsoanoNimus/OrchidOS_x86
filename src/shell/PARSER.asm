; PARSER.asm
; -- Command parser: polls results and calls appropriate commands.


; KNOWN ISSUES:
; * ON COMMANDS >4 CHARS, THE INPUT CAN BE SKEWED SO THAT ONLY THE 'LAST 4 CHARS' & 'LENGTH'
;    OF THE COMMAND MATCH THE PARAMETERS.
;   Solutions: Implement a stricter command parser.
; * UNKNOWN COMMANDS WITH >4 WORDS WILL GENERATE A "PARSER SYNTAX ERROR" INSTEAD OF
;    THE APPROPRIATE "UNKNOWN COMMAND" ERROR.


%include "shell/CMDDIR.asm"

szPARSERNoCMD 			db "Invalid command! Type HELP for commands.", 0
szPARSERSynErr1			db "Parser detected a syntax error in the passed arguments.", 0
szPARSERSynErr2 		db "-- Check the orchid documentation for more information about the parser!", 0
PARSER_ARG1_LENGTH 		db 0x00
PARSER_ARG2_LENGTH 		db 0x00
PARSER_ARG3_LENGTH 		db 0x00
PARSER_ARG1 times 64	db 0x00
PARSER_ARG2 times 64	db 0x00
PARSER_ARG3 times 64	db 0x00

PARSER_COMMAND_NO_ARGS	times 8 db 0x00		;8-byte buffer to hold ONLY the first command.
						db 0x00

iPARSERsaveEIP	dd 0x0	; used so that the popad by dump doesn't pop the return EIP.


PARSER_CheckQueue:
	pushad
	pushad		; doubled so that the DUMP command can have access to them without actually changing them.
	cmp byte [SHELL_COMMAND_IN_QUEUE], TRUE
	jne .noCommand

	;This section will run every time ENTER is hit, so the buffer is always cleared after every entry.
	call PARSER_parseCommand
	mov byte [SHELL_COMMAND_IN_QUEUE], FALSE
	call PARSER_ClearInput
 .noCommand:
	popad
	popad
	ret


PARSER_parseCommand:
	;FIRST READING, finds length of buffer
	mov esi, SHELL_INPUT_BUFFER	;get base addr of input
	mov edi, PARSER_COMMAND_NO_ARGS
	xor ecx, ecx			;length counter
	xor edx, edx			;prevents a second reading on cmds 4 chars or smaller
 .repeatFirstRead:
	lodsb
	cmp al, 0x20	; look for space
	je .parseArguments

	cmp al, 0x00	; or find the null terminator
	je .endFirstRead
	;shl edx, 8		; Get the most recent character and push it up to the higher parts of the register.
					; --This can be done up to 4 times before this instruction becomes useless for this reading.
					; KEEP IN MIND: This is reading chars left-to-right, NOT little-endian, due to the shifting.
	;mov dl, al
	cmp ecx, 8
	jae .returnWMSG		; if any string in the SHELL_INPUT_BUFFER exceeds 8 chars before a space,
						; automatically assume invalid input.

	; Set EDI = current byte in buffer and move it in.
	; This variable (PARSER_COMMAND_NO_ARGS) allows a direct string comparison, with no more confusing hex cmps.
	push edi
	add edi, ecx
	mov byte [edi], al
	pop edi
	inc ecx
	jmp .repeatFirstRead

	; The .return label is only for exiting commands to use. Otherwise, the default return is to give an error msg.
.endFirstRead:		; ECX is now = to the buffer length. Use this to narrow down the command tests.

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Before anything, make sure reboot & shutdown aren't being called.
	cmp dword [PARSER_COMMAND_NO_ARGS], "rebo"
	jne .clearRebootFlag
	cmp dword [PARSER_COMMAND_NO_ARGS+2], "boot"
	jne .clearRebootFlag
	jmp .skipClearRebootFlag
  .clearRebootFlag:
	mov byte [bREBOOTPending], FALSE
  .skipClearRebootFlag:
	cmp dword [PARSER_COMMAND_NO_ARGS], "shut"
	jne .clearShutdownFlag
	cmp dword [PARSER_COMMAND_NO_ARGS+4], "down"
	jne .clearShutdownFlag
	jmp .skipClearShutdownFlag
  .clearShutdownFlag:
	mov byte [bSHUTDOWNPending], FALSE
  .skipClearShutdownFlag:
  	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	cmp ecx, 0						; Check if the user even wrote anything.
	je .returnCMD					; If not, exit with no output.
	cmp ecx, 2		; 2-letter cmd
	jg .not2
	; 2-letter cmds go here.
	jmp .returnWMSG
 .not2:
	cmp ecx, 3
	jg .not3
	;CheckCMD CLS,0x00636C73		;"cls"
	;CheckCMD SYS,0x00737973 	;"sys"
	;CheckCMD USR,0x00757372		;"usr"
	CheckL4CMD CLS,"cls"
	CheckL4CMD SYS,"sys"
	CheckL4CMD USR,"usr"
	CheckL4CMD USB,"usb"
	jmp .returnWMSG
 .not3:
	cmp ecx, 4
	jg .not4
	;CheckCMD DUMP,0x64756D70	;"dump" -- This one has to be different because of the pushad/popad.
	cmp dword [PARSER_COMMAND_NO_ARGS], "dump"
	jne .NotDUMP
	pop dword [iPARSERsaveEIP]	; save the EIP return pointer pushed due to the CALL opcode.
	popad						; restore everything.
	call COMMAND_DUMP
	pushad						; correcting stack pop offset here.
	push dword [iPARSERsaveEIP]	; restore the ret ptr.
	jmp .returnCMD
  .NotDUMP:
	CheckL4CMD MEMD,"memd"
	CheckL4CMD CONN,"conn"
	CheckL4CMD HELP,"help"
	jmp .returnWMSG
 .not4:
	cmp ecx, 5
	jg .not5
	CheckG4CMD COLOR,"colo","r"
	jmp .returnWMSG
 .not5:
	cmp ecx, 6
	jg .not6
	CheckG4CMD REBOOT,"rebo","ot"
	jmp .returnWMSG
 .not6:
 	cmp ecx, 7
	jg .not7
	jmp .returnWMSG
 .not7:
 	cmp ecx, 8
	jg .not8
	CheckG4CMD SHUTDOWN,"shut","down"
	jmp .returnWMSG
 .not8:
 	; 8 chars WILL be the longest allowable command, so just bleed into the error message.
	; Due to the error-catching in the first section of this function, this should never be reach anyway.
 .returnWMSG:
 	PrintString szPARSERNoCMD,0x04
 .returnCMD:
	ret

 .parseArguments:
 	; Check if the user didn't just enter a leading space.
 	cmp byte [PARSER_COMMAND_NO_ARGS], 0x00
	je .returnWMSG
	; There is a command, parse its arguments.
 	or ecx, ecx
	jz .endFirstRead
 	call PARSER_parseArguments		; Check if there were arguments after the command.
 	jc .syntaxError
	jmp .endFirstRead				; on success, process which command is being called.
 .syntaxError:
 	PrintString szPARSERSynErr1,0x0C
	PrintString szPARSERSynErr2
 	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Clean all 256 bytes of input (set to 0x00).
; Also clean the parser's argument buffers.
PARSER_ClearInput:
	pushad
	; Move the current buffer into the shadow before cleaning.
	; See "SCREEN.asm" -- not happening until better keyboard driver implementation.
	MEMCPY SHELL_INPUT_BUFFER,SHELL_SHADOW_BUFFER,0x100
	; Index can be saved here because the .return local call in PrintChar sets the INPUT_INDEX after this.
	MEMCPY SHELL_INPUT_INDEX,SHELL_SHADOW_INDEX,0x02
	mov edi, SHELL_INPUT_BUFFER
	xor eax, eax
	mov ecx, 100h
	rep stosb
	mov edi, PARSER_ARG1
	mov ecx, 64*3		; 64 bytes per PARSER_ARG x 3 of them.
	rep stosb
	mov byte [PARSER_ARG1_LENGTH], 0x00
	mov byte [PARSER_ARG2_LENGTH], 0x00
	mov byte [PARSER_ARG3_LENGTH], 0x00
	mov dword [PARSER_COMMAND_NO_ARGS], 0x00000000
	mov dword [PARSER_COMMAND_NO_ARGS+4], 0x00000000
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
	cmp al, 0x00
	je .cleanExit
	cmp al, 0x20	; make sure character following closing quote is a space separator.
	jne .error
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
