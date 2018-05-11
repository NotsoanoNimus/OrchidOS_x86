; INIT.asm
; --- Contains some of initialization functions used by the kernel during load time.

INIT_PICandIDT:
	pushad
	mov bh, 0x20	; Master vector offset
	mov bl, 0x28	; Slave vector offset
	call PIC_remap

	; Unmask only the keyboard, cascade, and timer for now (bits !NOT! flagged are enabled IRQs)
	mov al, 0xF8		; mask = 1111 1000 // PIC1 IRQ #1 (0 being the clock), keyboard enabled. Clock enabled. CASCADE Enabled.
	out PIC1_DATA, al
	mov al, 0xFF
	out PIC2_DATA, al

	lidt [IDT_Desc]	; Finally load the IDT

	popad
	ret


szShellIntro			db "Welcome! Type 'help' for a list of orchid shell commands.", 0
INIT_kernelWelcomeDisplay:
	push ebx
	call GRAPHICS_introOverlay		; SPLASH screen
	call GRAPHICS_setShellOverlay	;set up initial header
	mov bx, 0x0001					;add intro message.
	call SCREEN_UpdateCursor
	PrintString szShellIntro,0x0A

	call SYSTEM_tellErrors

	mov word [SHELL_SHIFT_INDICATOR], 0x301F	; Default shift indicator.
	mov word [SHELL_CAPS_INDICATOR], 0x3019		; Default caps indicator.
	pop ebx
	ret


; Tell the user what errors are flagged from the startup procedure.
szVESAFailureMsg		db "*Due to an incompatibility with VGA hardware, orchid has started in shell mode.", 0
szACPIFailureMsg		db "*Could not start the Advanced Configuration and Power Interface (ACPI) manager.", 0
szACPINoShutdown		db "*ACPI: Shutdown variables could not be found! Only manual shutdown is possible!", 0
szSYSNoInfoError		db "*Orchid Could failed to load information about the system properly.", 0
szETHERNETNotFoundError db "*No compatible Ethernet device was found on this machine.", 0
szRunningFromEmulator	db "***Orchid is running on an emulator (QEMU/BOCHS).", 0
SYSTEM_tellErrors:
	pushad
	mov dword edx, [BOOT_ERROR_FLAGS]
	PrintString szVESAFailureMsg,0x0C		; this is always written in shell startup.
	CONSOLETellError 0x00000080,szACPIFailureMsg,.noACPIError
	CONSOLETellError 0x00000040,szACPINoShutdown,.noShutdownError
	CONSOLETellError 0x00000002,szSYSNoInfoError,.noSYSINFOError
	CONSOLETellError 0x00000100,szETHERNETNotFoundError,.noETHERNETError

	cmp byte [IS_ON_EMULATOR], TRUE
	jne .leaveCall
	PrintString szRunningFromEmulator,0x0E
 .leaveCall:
 	popad
	ret




iMemoryFree			dd 0x00000000
iMemoryReserved		dd 0x00000000
iMemoryTotal		dd 0x00000000
SYSTEM_getMEMInfo:
	mov edi, MEM_INFO
	xor ecx, ecx
	xor ebx, ebx
	; Read over the MEM_INFO area and get the count of tables.
 .getArraySize:
	mov ebx, [edi]	; Check the DWORD at the base of each 24-byte entry for the signature starting with 0x1234.
	and ebx, 0xFFFF0000
	cmp ebx, 0x12340000	;Is the signature present?
	je .arraySizeFound	; yes, leave
	add edi, 0x18		; no, next entry
	inc cl
	cmp cl, 40			; after 40 tries, if nothing is found, error.
	je .noMemInfoFound
	jmp .getArraySize

 .arraySizeFound:		; ECX = array size
	mov byte [MMAP_SIZE], cl
	mov edi, MEM_INFO	; reset the pointer register.
	xor ecx, ecx

  .continueMapping:
	; Map out MEM_INFO[MMAP_SIZE]
	mov eax, 0x00000018			; EAX = sizeof a MEM_INFO entry
	mul cx						; times current iteration
	add eax, MEM_INFO			; ... plus MEM_INFO base address.
	mov edi, eax
	mov eax, [edi+8]			; get dword indicating range of section.

	cmp byte [edi+0x10], 0x02	; Check MEM type
	jae .reservedMem			; Flagged as reserved, treat ACPI as reserved for now.
	; Otherwise, memory is marked as free.

	add dword [iMemoryFree], eax
	jo .freeMemoryOverflow
	jmp .checkEnd

 .reservedMem:
	add dword [iMemoryReserved], eax
	jo .reservedMemoryOverflow
	; bleed
 .checkEnd:
	inc cx
	cmp byte [MMAP_SIZE], cl
	je .mappingFinished
	jmp .continueMapping

 .freeMemoryOverflow:
	mov dword [iMemoryFree], 0xFFFFFFFF	;set to max value if overflow.
	jmp .reservedMem
 .reservedMemoryOverflow:
	mov dword [iMemoryReserved], 0xFFFFFFFF
	jmp .checkEnd

 .noMemInfoFound:
	; unable to locate memory information. Do something here.
	or dword [BOOT_ERROR_FLAGS], 0x00000002		;Set Bit1
	jmp .leaveCall

 .mappingFinished:
	mov eax, [iMemoryFree]
	mov dword [iMemoryTotal], eax
	mov eax, [iMemoryReserved]
	add dword [iMemoryTotal], eax
	jno .leaveCall
	mov dword [iMemoryTotal], 0xFFFFFFFF

 .leaveCall:
	ret


SYSTEM_getCPUInfo:
	; Test if CPUID is supported... If bit 21 of EFLAGS can be modified, good to go. Otherwise, find CPU info otherwise.
	pushfd		; save state
	pushfd		; Store for manipulation
	xor DWORD [esp], 0x00200000		;Invert the ID bit stored in EFLAGS. (bit 21)
	popfd		; Set manipulated EFLAGS
	pushfd
	pop eax		; EAX = manipulated EFLAGS
	xor eax, [esp]	; check manipulated EFLAGS against original EFLAGS (see if bit stayed set). EAX = changed bits.
	popfd		; restore state
	and eax, 0x00200000		; EAX = 0 if bit can't be changed.
	or eax, eax
	jz .CPUIDNoSupport

	;Get vendor string. EBX = "4321", EDX = "8765", & ECX = "2109" (9, 10, 11, 12)
	; Vendor string is a 12-byte string given in the manner above. Store it into memory the way it is and deal with it later.
	mov edi, CPU_INFO	; Point edi to 0x700 (CPU_INFO section).
	mov eax, 0x0	; vendor-string param
	cpuid
	; Store accordingly.
	mov [edi], ebx
	mov [edi+4], edx
	mov [edi+8], ecx

	; Check processor features.
	mov eax, 0x1
	cpuid

	;rdtsc -- Not sure about using this feature yet; needs more study.

	jmp .leaveCall

 .CPUIDNoSupport:
	mov edi, CPU_INFO
	mov DWORD [edi], "NOID"
	mov DWORD [edi+4], "NOID"
	mov DWORD [edi+8], "NOID"

 .leaveCall:
	ret


; GET CPU INFO, TIME/DATE, AND MEMORY INFO HERE...
INIT_getSystemInfo:
	pushad

	push eax
	push ebx
	; May not be needed. Consider deleting.
	mov DWORD eax, [SCREEN_FRAMEBUFFER_ADDR]
	mov DWORD [SCREEN_FRAMEBUFFER], eax
	mov WORD ax, [SCREEN_OFFSCREEN_MEMORY]		; memory in KB
	mov WORD [SCREEN_LFB_SIZE_KB], ax

	; Get the screen's pixel count.
	xor eax, eax
	xor ebx, ebx
	mov WORD ax, [SCREEN_HEIGHT]
	mov WORD bx, [SCREEN_WIDTH]
	mul ebx
	mov DWORD [SCREEN_PIXEL_COUNT], eax

	; Get BYTES_PER_PIXEL.
	xor eax, eax
	mov byte al, [SCREEN_BPP]
	shr al, 3		;divide by 2^3 (8)
	mov byte [BYTES_PER_PIXEL], al
	pop ebx
	pop eax

	; Clear space for the graphics off-screen buffer, based on screen size (BBSize = BytesPP * PixelCt).

	call SYSTEM_getTimeAndDate	; TIMER.asm - CMOS section.
	call SYSTEM_getCPUInfo		; do CPUID and get info.
	call SYSTEM_getMEMInfo		; get memory information on the system.
	call PCI_getDevicesInfo		; Get information about attached PCI devices to 0x71000. (DONE, INTERPRETER WILL IGNORE DUPLICATES)

 .leaveCall:
	popad
	ret


; Register the kernel/sys process. This area of the heap holds volatile/random data for system use. Somewhat small.
szSYSTEM_KERNEL_PROCESS_DESC db "System Kernel", 0
INIT_REGISTER_SYSTEM_KERNEL:
	push dword szSYSTEM_KERNEL_PROCESS_DESC
	push dword KERNEL_PROCESS_VOLATILE_DATA_SIZE
	call MEMOPS_KMALLOC_REGISTER_PROCESS
	add esp, 8
	or eax, eax	; error?
	jnz .leaveCall
	; bleed into error condition if 0
	; error condition hangs the system.
	cli
 .error:
 	hlt
	jmp .error
 .leaveCall:
	ret


INIT_START_SYSTEM_DRIVERS:
	call INIT_REGISTER_SYSTEM_KERNEL	; Register the system/kernel process.
	call ACPI_initialize		; Initialize ACPI controller.
	;call KEYBOARD_initialize	; Initialize the keyboard to the proper scan code set.
	call VFS_initialize			; Initialize the VFS in RAM.
	call USB_initializeDriver	; Initialize the USB devices found on the PCI bus.
		call PCI_INTERNAL_cleanMatchedBuffers	; required before handling other device inits. Indented for visibility.

	call ETHERNET_initialize	; Initialize the ethernet controller and set up appropriate memory spaces/configurations.

 .leaveCall:
 	ret


INIT_START_SYSTEM_PROCESSES:
	call CRYPTO_REGISTER_PROCESS	; Start the 'crypto' process.

	; Sleep for a moment so user can digest info.
	SLEEP_noINT 10	;10*200ms = 2sec
 .leaveCall:
 	ret
