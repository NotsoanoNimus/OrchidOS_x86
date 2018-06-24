; SYS.asm
; --- Display system information and Orchid info.

COMMAND_SYS_CACHED db FALSE


COMMAND_SYS:
	pushad
	; no need to calculate the values every single call.
	cmp byte [COMMAND_SYS_CACHED], TRUE
	je .doNotCalc
	call COMMAND_SYS_CACHE_VALUES
 .doNotCalc:
	PrintString szSysInfo1,0x09
	PrintString szSysInfo2,0x0D
	PrintString szSysInfo3,0x0E
	PrintString szSysInfo3a
	PrintString szSysInfo8,0x0A
	PrintString szSysInfo9
	popad
	ret


%strcat szSysInfo1cat "SYSTEM INFO: Orchid v",ORCHID_VERSION
szSysInfo1			db szSysInfo1cat
szSysInfo1Ext		db ", 32-bit x86 --> Date of Last Build: "
szSysDateofLB		db __DATE__, 0
szSysInfo2 			db "CPU - Vendor ID: '"
szSysInfoVendor 	db "xxxxxxxxxxxx'", 0
szSysInfo3			db "MEMORY - Total RAM: "
szSysInfoTotalRAM	db "         MiB ---> Free RAM: "
szSysInfoFreeRAM	db "         MiB", 0
szSysInfo3a			db "   ----> Reserved RAM: "
szSysReservedRAM	db "         KiB", 0
szSysInfo8 			db "Started and managed by Zachary Puhl at github.com/ZacharyPuhl/OrchidOS_x86.", 0
szSysInfo9 			db "Licensed under the GNU GPL v3.0. OrchidOS is an open-source project.", 0


; TODO: FIX THE CONVERSION FUNCTION THAT OUTPUTS DECIMAL ASCII
COMMAND_SYS_CACHE_VALUES:
	; Get vendor string.
	mov esi, CPU_INFO
	mov edi, szSysInfoVendor
	movsd
	movsd
	movsd

	xor edx, edx			; clear edx
	mov eax, dword [iMemoryTotal]
	mov ebx, 0x400			; decimal 1024 = 1 KiB
	div ebx					; get rounded (floor) MiB in EAX, ignore EDX remainder value.
	ZERO edx
	div ebx		; get result in MiB
	mov esi, szSysInfoTotalRAM+8	; end of buffer
	mov ecx, 4
 .convertTotalRAM:
	call UTILITY_BYTE_convertHexToDec
	shr eax, 8
	loop .convertTotalRAM

	xor edx, edx
	mov eax, dword [iMemoryFree]
	mov ebx, 0x400	; = 1024
	div ebx
	ZERO edx
	div ebx		; Get the FREE memory in MiB
	mov esi, szSysInfoFreeRAM+8
	mov ecx, 4
 .convertFreeRAM:
	call UTILITY_BYTE_convertHexToDec
	shr eax, 8
	loop .convertFreeRAM

	xor edx, edx
	mov eax, dword [iMemoryReserved]
	mov ebx, 0x400
	div ebx
	mov esi, szSysReservedRAM+8
	mov ecx, 4
 .convertReservedRAM:
	call UTILITY_BYTE_convertHexToDec
	shr eax, 8
	loop .convertReservedRAM

 .leaveCall:
 	mov byte [COMMAND_SYS_CACHED], TRUE
 	ret
