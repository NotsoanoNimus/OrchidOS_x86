; TIMER.asm
; --- Time/Date functions and IRQ0 handlers.

SLEEP_TICKS_COUNTER				dd 0	; Used for the global sleep function
PIT_RELOAD_VALUE				dw 0

SYSTEM_TICKS					dd 0	; 35Hz oscillator.

SYSTEM_HOURS					db 0
SYSTEM_MINUTES					db 0
SYSTEM_SECONDS					db 0

SYSTEM_WEEKDAY					db 0
SYSTEM_DAY						db 0
SYSTEM_MONTH					db 0
SYSTEM_YEAR						db 0

szSYSTime						db "[00:00:00]", 0
szSYSDate						db " XXX XXX XX, 20XX", 0		; Starting space is for THUR

ISR_timerHandler:	;called every 28.57143 ms (every 7 calls is 200ms)
	; handle sleep counter if needed
	mov eax, [SLEEP_TICKS_COUNTER]
	or eax, eax
	jz .noSleep		; no value in the ticks counter?
	dec eax
	mov dword [SLEEP_TICKS_COUNTER], eax

 .noSleep:
	; handle system timer
	mov eax, [SYSTEM_TICKS]
	inc eax
	mov dword [SYSTEM_TICKS], eax


	cmp eax, 35
	jl .noUpdate
	call TIMER_updateSystemTime

	;nothing else is done here, so interrupt can exit quickly.

 .noUpdate:
	xor dl, dl				; IRQ#0
	call PIC_sendEOI		; acknowledge the interrupt to PIC
	ret


;;;;;;;; GLOBALLY-USED FUNCTION ;;;;;;;;
_SLEEP:		; ARGS: EAX = Duration to sleep in chunks of 200ms.
	pushad
	mov ebx, 0x00000007		;multiplied by 7 because 200ms worth of time is 7 IRQ ticks
	mul ebx
	mov dword [SLEEP_TICKS_COUNTER], eax
 .continueNap:
	cli
	mov eax, [SLEEP_TICKS_COUNTER]
	or eax, eax
	jz .naptimeOver
	sti
	nop
	nop
	nop
	nop
	nop
	jmp .continueNap
 .naptimeOver:
	popad
	ret


TIMER_updateSystemTime:
	; add on to seconds, then check for updates to minutes & hrs
	mov al, [SYSTEM_SECONDS]
	add al, 1
	cmp al, 60
	jl .noRollSeconds

	; seconds >= 60, roll over a minute, then check roll for hours
	mov byte [SYSTEM_SECONDS], 0
	mov word [szSYSTime+7], "00"
	mov bl, [SYSTEM_MINUTES]
	add bl, 1
	cmp bl, 60
	jl .noRollMinutes

	; next hour
	mov byte [SYSTEM_MINUTES], 0
	mov word [szSYSTime+4], "00"
	or byte [SYSTEM_TIME_UPDATE], 0x80	;tell the OS to read the RTC and correct drift.
	mov dl, [SYSTEM_HOURS]
	add dl, 1
	cmp dl, 24
	jge .newDay
	mov [SYSTEM_HOURS], dl
	jmp .exitTimerUpdate

 .noRollSeconds:
	mov [SYSTEM_SECONDS], al
	jmp .exitTimerUpdate

 .noRollMinutes:
	mov [SYSTEM_MINUTES], bl
	jmp .exitTimerUpdate

 .newDay:
	mov byte [SYSTEM_SECONDS], 0
	mov byte [SYSTEM_MINUTES], 0
	mov byte [SYSTEM_HOURS], 0
	;call TIMER_nextDay
	; bleed into exit function, no need to JMP

 .exitTimerUpdate:
	mov byte [SYSTEM_TICKS], 0	;reset the ms counter
	;call _updateTimeDisplay
	or byte [SYSTEM_TIME_UPDATE], 1		; tell the OS that the time has updated.
	ret


_updateTimeDisplay:
	; convert current system_ms time into readble format and update the display if a second has passed.
	pushad
	mov cl, [SYSTEM_TIME_UPDATE]
	and cl, 0x80		; highest bit set?
	cmp cl, 0x80		; if so, correct the timer's drift.
	jne .noDrift
	call SYSTEM_getTimeAndDate		; supposed to do this hourly.
 .noDrift:
	mov byte [SYSTEM_TIME_UPDATE], 0	; reset update flag

	; Check which mode we're in.
	mov dl, [currentMode]
	cmp dl, 00000001b			; are we in shell mode?
	jne .notShellMode			; this update is useless if we're in a different mode.

	xor eax, eax

	mov esi, szSYSTime+9
	mov al, [SYSTEM_SECONDS]
	call UTILITY_BYTE_convertHEXtoASCII_lessThan100

	mov esi, szSYSTime+6
	mov al, [SYSTEM_MINUTES]
	call UTILITY_BYTE_convertHEXtoASCII_lessThan100

	mov esi, szSYSTime+3
	mov al, [SYSTEM_HOURS]
	call UTILITY_BYTE_convertHEXtoASCII_lessThan100

	mov ah, 0x3F
	mov esi, szSYSTime
	mov edi, SYSTIME_VIDEO_LOCATION
	call _updateTimeDisplay.loopPrint

	; Get DATE fields.
	mov esi, szSYSDate
	mov al, [SYSTEM_WEEKDAY]	; Sunday = 1, Saturday = 7
	cmp al, 1
	je .daySUN
	cmp al, 2
	je .dayMON
	cmp al, 3
	je .dayTUE
	cmp al, 4
	je .dayWED
	cmp al, 5
	je .dayTHUR
	cmp al, 6
	je .dayFRI
	cmp al, 7
	je .daySAT
	; No day found in index...
	mov DWORD [esi], " ???"
	jmp .gotWeekday
 .daySUN:
	mov DWORD [esi], " Sun"
	jmp .gotWeekday
 .dayMON:
	mov DWORD [esi], " Mon"
	jmp .gotWeekday
 .dayTUE:
	mov DWORD [esi], " Tue"
	jmp .gotWeekday
 .dayWED:
	mov DWORD [esi], " Wed"
	jmp .gotWeekday
 .dayTHUR:
	mov DWORD [esi], "Thur"
	jmp .gotWeekday
 .dayFRI:
	mov DWORD [esi], " Fri"
	jmp .gotWeekday
 .daySAT:
	mov DWORD [esi], " Sat"
	; bleed

 .gotWeekday:		; Success, now onto MONTH.
	mov esi, szSYSDate+5
	mov al, [SYSTEM_MONTH]
	cmp al, 1
	je .monthJAN
	cmp al, 2
	je .monthFEB
	cmp al, 3
	je .monthMAR
	cmp al, 4
	je .monthAPR
	cmp al, 5
	je .monthMAY
	cmp al, 6
	je .monthJUN
	cmp al, 7
	je .monthJUL
	cmp al, 8
	je .monthAUG
	cmp al, 9
	je .monthSEP
	cmp al, 10
	je .monthOCT
	cmp al, 11
	je .monthNOV
	cmp al, 12
	je .monthDEC
	; No month found in index...
	mov DWORD [esi], "??? "
	jmp .gotMonth
 .monthJAN:
	mov DWORD [esi], "Jan "
	jmp .gotMonth
 .monthFEB:
	mov DWORD [esi], "Feb "
	jmp .gotMonth
 .monthMAR:
	mov DWORD [esi], "Mar "
	jmp .gotMonth
 .monthAPR:
	mov DWORD [esi], "Apr "
	jmp .gotMonth
 .monthMAY:
	mov DWORD [esi], "May "
	jmp .gotMonth
 .monthJUN:
	mov DWORD [esi], "Jun "
	jmp .gotMonth
 .monthJUL:
	mov DWORD [esi], "Jul "
	jmp .gotMonth
 .monthAUG:
	mov DWORD [esi], "Aug "
	jmp .gotMonth
 .monthSEP:
	mov DWORD [esi], "Sep "
	jmp .gotMonth
 .monthOCT:
	mov DWORD [esi], "Oct "
	jmp .gotMonth
 .monthNOV:
	mov DWORD [esi], "Nov "
	jmp .gotMonth
 .monthDEC:
	mov DWORD [esi], "Dec "
	jmp .gotMonth

 .gotMonth:			; Success, now onto DAY.
	mov esi, szSYSDate+11	;end of buffer for day var
	mov al, [SYSTEM_DAY]
	;call UTILITY_BYTE_convertHEXtoASCII_lessThan100
	call UTILITY_BYTE_convertBCDtoASCII_lessThan100

	mov esi, szSYSDate+17
	mov al, [SYSTEM_YEAR]	; YEAR is AUTOMATICALLY A BCD NUMBER (since it can't go higher than 99)
	call UTILITY_BYTE_convertBCDtoASCII_lessThan100

	mov ah, 0x3F
	mov esi, szSYSDate
	mov edi, SYSDATE_VIDEO_LOCATION
	call _updateTimeDisplay.loopPrint
	jmp .leaveCall

 .loopPrint:
	lodsb
	or al, al
	jz .stopPrinting
	stosw
	jmp .loopPrint
  .stopPrinting:
	ret

 .notShellMode:
 .leaveCall:
	popad
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;CMOS AREA;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CMOS_ACCESS_bideTime:		; THIS IS EATING TIME. Kill later if startup too long.
	push ecx
	mov ecx, 0x500
 .bideTime:
	nop
	loop .bideTime
	pop ecx
	ret

CMOS_TIME_checkInput:
	push ecx
	cmp ebx, 1
	je .BCDMode
	; handle binary mode here. Nothing to be done, store it.
	jmp .leaveCall
 .BCDMode:
	; handle BCD mode here.
	xor ecx, ecx

	push eax
	mov cl, al
	and cl, 0xF0
	shr cl, 1

	and al, 0xF0
	shr al, 3

	add cl, al		; CL = [(BCD & 0xF0) >> 1] + [(BCD & 0xF0) >> 3]
	pop eax			; restore original BCD to AL

	and al, 0x0F	; (BCD & 0x0F)
	add al, cl		; {[(BCD & 0xF0) >> 1] + [(BCD & 0xF0) >> 3]} + (BCD & 0x0F)
 .leaveCall:
	pop ecx
	ret

CMOS_TIME_hourConvert:
	cmp edx, 1
	je .mode24
	; handle 12-hr mode.
	push eax
	and eax, 0x80	; EAX = x000 0000b (checking if PM bit is set)
	cmp eax, 0x80	; check it.
	pop eax
	je .timePM

	; AM hours, we're good. Just check for the midnight hour, fix if needed, and leave.
	cmp al, 12		; looking for literal 12 first. Then check for BCD 12.
	jne .not12Hex
	xor al, al		; Switch from 12 (midnight) to 00 for 24-hr display.
	jmp .leaveCall
  .not12Hex:		; means it may be 12 BCD. Check.
	cmp al, 00010011b	; hex=0x12, BCD='12'=0x0C
	jne .not12BCD		; not 12 in BCD? leave without modifying
	xor al, al			; if it is, zero it out. bleed into jmp to leaveCall
  .not12BCD:
	jmp .leaveCall

  .timePM:			; easy to take care of: just mask off the high bit.
	and al, 0x7F	; AL & 0111 1111. Doesn't matter if BCD or not.
	jmp .leaveCall	; In the high nibble for BCD, only the low two bits are ever used for time.

 .mode24:	;if it's 24-hr mode, it requires no change to its value.
 .leaveCall:
	ret


;szCMOSRAMError		db "CMOS RAM: No power detected!", 0
SYSTEM_getTimeAndDate:		; use the CMOS to get the real time/date.
	; Check CMOS RAM power status.
	mov al, (0x80|0x0D)
	out 0x70, al
	call CMOS_ACCESS_bideTime
	in al, 0x71

	and al, 0x80			; bit 7 = CMOS RAM status. bits 0-6 = reserved (0).
	cmp al, 0x80
	je .CMOSPowered
	;handle no cmos power here. Warn user.
	;mov esi, szCMOSRAMError
	;mov bl, 0x0B
	;call _screenWrite
	;ret

	; CMOS = good, continue fetchin T&D.
 .CMOSPowered:
	xor edx, edx			; EDX = 12(00b) or 24(01b)
	xor ebx, ebx			; EBX = BINARY(00b) or BCD(01b)
	mov al, (0x80|0x0B)		; CMOS: NMI & get System Status B register
	out 0x70, al
	call CMOS_ACCESS_bideTime
	in al, 0x71

	; CHECK CMOS TIME SETTINGS
	push eax
	and al, 00000010b		; only checking BIT1
	cmp al, 00000010b		; Check bit 1 (0 = 12hr, 1 = 24hr)
	jne .format12hr			; not set? keep edx 0 (12-hr mode)
	mov edx, 1				; otherwise, flag 24-hr mode
 .format12hr:
	pop eax

	push eax
	and al, 00000100b		; only checking BIT2
	cmp al, 00000100b		; Check bit 2 (BINARY IF SET)
	je .binaryMode			; set? keep ebx 0 (binary mode)
	mov ebx, 1				; otherwise, flag BCD mode
 .binaryMode:
	pop eax


	mov al, (0x80|0x00)		; CMOS: NMI & get SECONDS
	out 0x70, al			; NMI & access CMOS register 0x00
	call CMOS_ACCESS_bideTime
	in al, 0x71				; Read seconds.
	call CMOS_TIME_checkInput
	mov byte [SYSTEM_SECONDS], al

	mov al, (0x80|0x02)		; CMOS: NMI & get MINUTES
	out 0x70, al
	call CMOS_ACCESS_bideTime
	in al, 0x71				; Read minutes.
	call CMOS_TIME_checkInput
	mov byte [SYSTEM_MINUTES], al

	mov al, (0x80|0x04)		; CMOS: NMI & get HOURS
	out 0x70, al
	call CMOS_ACCESS_bideTime
	in al, 0x71				; Read hours.
	call CMOS_TIME_hourConvert	; call the special hourConvert function. Moves AL to proper format.
	call CMOS_TIME_checkInput
	mov byte [SYSTEM_HOURS], al

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	mov al, (0x80|0x06)		; CMOS: NMI & get day of the week.
	out 0x70, al
	call CMOS_ACCESS_bideTime
	in al, 0x71				; Read weekday.
	mov byte [SYSTEM_WEEKDAY], al

	mov al, (0x80|0x07)		; CMOS: NMI & day of Month
	out 0x70, al
	call CMOS_ACCESS_bideTime
	in al, 0x71				; Read day.
	mov byte [SYSTEM_DAY], al

	mov al, (0x80|0x08)		; CMOS: NMI & get MONTH
	out 0x70, al
	call CMOS_ACCESS_bideTime
	in al, 0x71				; Read month.
	mov byte [SYSTEM_MONTH], al

	mov al, (0x80|0x09)		; CMOS: NMI & get YEAR (2-digit, <99)
	out 0x70, al
	call CMOS_ACCESS_bideTime
	in al, 0x71				; Read year.
	mov byte [SYSTEM_YEAR], al

	ret


SYSTEM_setTimeAndDate:		; set the T&D on the CMOS/RTC system.

	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Convert a hex input to a decimal ASCII representation.
; INPUTS: EAX = hex to convert, ESI = Decimal output (starting at end of buffer).
UTILITY_WORD_convertDECtoASCII:
	pushad

	popad
	ret


_convertHexToDec:
	pushad
	mov ebx, 10
	xor edx, edx
	or eax, eax		; protection against DIVBY0
	jz .end
 .convert:
	xor edx, edx
	div ebx
	add dl, '0'
	cmp dl, '9'
	jbe .store
	add dl, 'A'-'0'-10
 .store:
	dec esi
	mov byte [esi], dl
	and eax, eax
	jnz .convert
 .end:
	popad
	ret


UTILITY_BYTE_convertBCDtoASCII_lessThan100: ; INPUTS --> AL = BCD byte, ESI = END OF OUTPUT BUFFER (WORD)
	push eax
	xor ah, ah
	mov ah, al

	and al, 0x0F
	and ah, 0xF0
	shr ah, 4

	add al, '0'
	add ah, '0'

	dec esi
	mov byte [esi], al
	mov byte [esi-1], ah
	pop eax
	ret

UTILITY_BYTE_convertHEXtoASCII_lessThan100:	; INPUTS --> AL = byte to convert. ESI = END OF BUFFER (WORD)
	;OUTPUTS --> AX = ASCII byte outputs.
	push ecx
	push ebx
	push edx

	xor ah, ah
	cmp al, 100
	jge .leaveCall

	mov bl, 10
	div bl		;al = quotient, ah = remainder/10

	and al, 0x0F	; ensure low nibble
	shl al, 4		; shift it to high nibble place
	and ah, 0x0F	; ensure lower nibble

	or al, ah		; easy conversion.
	jmp .endFunc

 .endFunc:
	mov ah, al
	and al, 0x0F	; low BCD nibble
	and ah, 0xF0	; high BCD nibble
	shr ah, 4		; trim

	add al, '0'
	add ah, '0'		; convert both to ASCII

	; FUTURE REFERENCE:
	; --- don't check mode. If this func is called, an ASCII output is wanted. So always just point the buffer and call.
	;check mode before outputting ASCII (maybe change later)
	;mov cl, [currentMode]
	;cmp cl, SHELL_MODE
	;jne .leaveCall

	dec esi
	mov byte [esi], al
	mov byte [esi-1], ah
	; bleed into leaveCall
 .leaveCall:
	pop edx
	pop ebx
	pop ecx
	ret


UTILITY_BYTE_convertBCDtoASCII: ; INPUTS = AX as BCD of byte (max 256d) // OUTPUTS = EAX as string output.
	push ecx
	push edx
	xor ecx, ecx
	xor edx, edx

	mov dl, al
	mov dh, al
	mov cl, ah

	and dl, 0x0F
	and cl, 0x0F
	and dh, 0xF0
	shr dh, 4

	add dl, '0'
	add dh, '0'
	add cl, '0'
	mov ch, '0'		; force highest byte to be '0' (no value >256d)

	; EAX = ch->cl->dh->dl
	xor eax, eax
	mov al, ch
	shl eax, 8

	mov al, cl
	shl eax, 8

	mov al, dh
	shl eax, 8

	mov al, dl
	shl eax, 8

	pop edx
	pop ecx
	ret
	
