; SYS.asm
; --- Display system information and Orchid info.

_commandSYS:
	pushad

	mov esi, CPU_INFO
	mov edi, szSysInfoVendor
	movsd
	movsd
	movsd

	xor edx, edx			; clear edx
	mov eax, [iMemoryTotal]
	mov ebx, 0x400			; 1 KiB
	div ebx					; get rounded (floor) MiB in EAX, ignore EDX remainder value.
	mov esi, szSysInfoTotalRAM+8	; end of buffer
	mov ecx, 4
 .convertTotalRAM:
	call _convertHexToDec
	shr eax, 8
	loop .convertTotalRAM

	xor edx, edx
	mov eax, [iMemoryFree]
	mov ebx, 0x400
	div ebx
	mov esi, szSysInfoFreeRAM+8
	mov ecx, 4
 .convertFreeRAM:
	call _convertHexToDec
	shr eax, 8
	loop .convertFreeRAM

	mov bl, 0x09
	mov esi, szSysInfo1
	call _screenWrite
	mov bl, 0x0D
	mov esi, szSysInfo2
	call _screenWrite
	mov bl, 0x0E
	mov esi, szSysInfo3
	call _screenWrite
	mov bl, 0x0A
	mov esi, szSysInfo8
	call _screenWrite
	mov esi, szSysInfo9
	call _screenWrite

	popad
	ret


szSysInfo1			db "SYSTEM INFORMATION:  Orchid v0.3, 32-bit x86 -- DLB(dd.mm.yyyy): 24.08.2017", 0
szSysInfo2 			db "CPU - Vendor ID: '"
szSysInfoVendor 	db "xxxxxxxxxxxx'", 0
szSysInfo3			db "MEMORY - Total RAM: "
szSysInfoTotalRAM	db "         KiB ---> Free RAM: "
szSysInfoFreeRAM	db "         KiB", 0
szSysInfo8 			db "Started and managed by Zachary Puhl at github.com/ZacharyPuhl/OrchidOS_x86.", 0
szSysInfo9 			db "Licensed under the GNU GPL v3.0. OrchidOS is an open-source project.", 0
