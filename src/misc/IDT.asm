
;%define SECTION_BASE 0x1000		;kernel offset
PIC1			equ 0x20	; IO base address for master PIC.
PIC2			equ 0xA0	; IO base address for slave PIC.
PIC1_COMMAND	equ PIC1
PIC1_DATA		equ PIC1+1
PIC2_COMMAND	equ PIC2
PIC2_DATA		equ PIC2+1
PIC_EOI			equ 0x20	; End-of_interrupt command code.


%macro ISR_OFFSETS 1
	ISRLOW%1 equ (KERNEL_OFFSET + isr%1 - $$) & 0xFFFF		; lower 16 bits of offset
	ISRHIGH%1 equ (KERNEL_OFFSET + isr%1 - $$) >> 16		; upper 16 bits of offset
%endmacro

%macro ISR_NOERRORCODE 1
	isr%1:
		cli
		pushad
		xor edx, edx
		mov edx, %1
		call isr_common
		popad
		sti
		iretd
%endmacro

%macro IDTENTRY 1
 .entry%1:
	dw ISRLOW%1			; Offset 0-15
	dw CODE_SELECTOR	; Selector (from GDT)
	db 0				; reserved
	db 10001110b		; Present, Ring 0, (0) Storage, 32-bit int gate
	dw ISRHIGH%1		; Offset 16-31
%endmacro

; HARDWARE IRQ CALLERS (just to condense some code).
%macro HARDWARE_IRQ 1
	cli
	pushad
	call %1
	popad
	sti
	iretd
%endmacro




; Main IDT table with all entries predefined.
IDT:
 IDTENTRY 0		; divide by zero
 IDTENTRY 1		; Debug Exception
 IDTENTRY 2		; NMI (non-maskable interrupt)
 IDTENTRY 3		; Breakpoint Exception
 IDTENTRY 4		; 'Into Detected Overflow'
 IDTENTRY 5		; Out of bounds
 IDTENTRY 6		; Invalid Opcode
 IDTENTRY 7		; No coprocessor exception
 IDTENTRY 8		; Double-fault (pushes error code)
 IDTENTRY 9		; Coprocessor Segment Overrun
 IDTENTRY 10	; Bad TSS  (pushes error code)
 IDTENTRY 11	; Segment Not Present (not flagged) (pushes error code)
 IDTENTRY 12	; Stack Fault (pushes error code)
 IDTENTRY 13	; General Protection Fault (pushes error code)
 IDTENTRY 14	; Page Fault (pushes error code)
 IDTENTRY 15	; Unknown Interrupt Exception
 IDTENTRY 16	; Coprocessor fault
 IDTENTRY 17	; Alignment Check Exception
 IDTENTRY 18	; Machine Check Exception
 IDTENTRY 19	;;;;;;;;;;;;;;;;;;;;;;;;;
 IDTENTRY 20
 IDTENTRY 21
 IDTENTRY 22
 IDTENTRY 23
 IDTENTRY 24
 IDTENTRY 25	; RESERVED 19 - 31
 IDTENTRY 26
 IDTENTRY 27
 IDTENTRY 28
 IDTENTRY 29
 IDTENTRY 30
 IDTENTRY 31	;;;;;;;;;;;;;;;;;;;;;;;;;
 IDTENTRY 32	; Timer (PIT)
 IDTENTRY 33	; Keyboard Controller
 IDTENTRY 34	; CASCADE
 IDTENTRY 35	; COM2 (if enabled/available)
 IDTENTRY 36	; COM1 (if enabled/available)
 IDTENTRY 37	; LPT2 (if enabled)
 IDTENTRY 38	; Floppy Disk
 IDTENTRY 39	; LPT1 / Unreliable "Spurious" IRQ (usually)
 IDTENTRY 40	; CMOS real-time clock (if enabled)
 IDTENTRY 41	; Free for peripherals / Legacy SCSI / NIC <-- often used by ACPI to detect power events.
 IDTENTRY 42	; Used by the Ethernet Controller (Free for peripherals / SCSI / NIC)
 IDTENTRY 43	; Free for peripherals / SCSI / NIC <-- Appears to be used by the Ethernet Controller...
 IDTENTRY 44	; PS/2 Mouse Controller (not going to be supported by orchid)
 IDTENTRY 45	; FPU / Coprocessor / Inter-processor
 IDTENTRY 46	; Primary ATA Hard Disk
 IDTENTRY 47	; Secondary ATA Hard Disk / IRQ15 Spurious
; From here, there are no reserved interrupts. Create my own, including syscall.
 IDTENTRY 48
 IDTENTRY 49
 IDTENTRY 50
IDT_Desc:
	dw $ - IDT - 1		; IDT size
	dd IDT				; IDT Offset/Base


; Set up ISRs
;ISR_NOERRORCODE 0
; `--> divide by zero. This ISR will be a simple crash,
;       until a process handler is implemented that will terminate the faulted process.
isr0:
	cli
	push dword 0x00000000
	jmp SYSTEM_BSOD
ISR_NOERRORCODE 1
;ISR_NOERRORCODE 2		; non-maskable interrupt. Mostly indicated a hardware issue. irrecoverable crash for now.
isr2:
	cli
	push dword 0x00000002
	jmp SYSTEM_BSOD
ISR_NOERRORCODE 3
ISR_NOERRORCODE 4
ISR_NOERRORCODE 5
;ISR_NOERRORCODE 6		; invalid opcode discovered, crash for now. Learn how to deal later.
isr6:
	cli
	push dword 0x00000006
	jmp SYSTEM_BSOD
ISR_NOERRORCODE 7
;ISR_NOERRORCODE 8		; irrecoverable software failure. For now it crashes the system.
isr8:
	cli
	push dword 0x00000008
	jmp SYSTEM_BSOD
ISR_NOERRORCODE 9
ISR_NOERRORCODE 10
ISR_NOERRORCODE 11
ISR_NOERRORCODE 12
;ISR_NOERRORCODE 13		; GPF.
isr13:
	cli
	pushad
	call ISR_generalProtectionFault
	popad
	add esp, 4
	sti
	iretd
ISR_NOERRORCODE 14
ISR_NOERRORCODE 15
ISR_NOERRORCODE 16
ISR_NOERRORCODE 17
ISR_NOERRORCODE 18
ISR_NOERRORCODE 19
ISR_NOERRORCODE 20

; -- RESERVED --
ISR_NOERRORCODE 21
ISR_NOERRORCODE 22
ISR_NOERRORCODE 23
ISR_NOERRORCODE 24
ISR_NOERRORCODE 25
ISR_NOERRORCODE 26
ISR_NOERRORCODE 27
ISR_NOERRORCODE 28
ISR_NOERRORCODE 29
; --------------

ISR_NOERRORCODE 30
ISR_NOERRORCODE 31

isr32:	;TIMER IRQ0
	HARDWARE_IRQ ISR_timerHandler
isr33:	; KEYBOARD IRQ1
	HARDWARE_IRQ ISR_keyboardHandler
ISR_NOERRORCODE 34
ISR_NOERRORCODE 35
ISR_NOERRORCODE 36
ISR_NOERRORCODE 37
isr38:	; LPT1 / Spurious IRQ7
	HARDWARE_IRQ ISR_LPTSpurHandler
ISR_NOERRORCODE 39
ISR_NOERRORCODE 40
ISR_NOERRORCODE 41
;ISR_NOERRORCODE 42
isr42:
isr43:
	HARDWARE_IRQ ISR_PHYSICAL_NIC
;ISR_NOERRORCODE 43
ISR_NOERRORCODE 44		; Mouse controller.
ISR_NOERRORCODE 45
ISR_NOERRORCODE 46
isr47:	;SecATA / Spurious IRQ15
	HARDWARE_IRQ ISR_SecondaryATA
ISR_NOERRORCODE 48
ISR_NOERRORCODE 49
ISR_NOERRORCODE 50

; Offset Locations for IDT
ISR_OFFSETS 0
ISR_OFFSETS 1
ISR_OFFSETS 2
ISR_OFFSETS 3
ISR_OFFSETS 4
ISR_OFFSETS 5
ISR_OFFSETS 6
ISR_OFFSETS 7
ISR_OFFSETS 8
ISR_OFFSETS 9
ISR_OFFSETS 10
ISR_OFFSETS 11
ISR_OFFSETS 12
ISR_OFFSETS 13
ISR_OFFSETS 14
ISR_OFFSETS 15
ISR_OFFSETS 16
ISR_OFFSETS 17
ISR_OFFSETS 18
ISR_OFFSETS 19
ISR_OFFSETS 20
ISR_OFFSETS 21
ISR_OFFSETS 22
ISR_OFFSETS 23
ISR_OFFSETS 24
ISR_OFFSETS 25
ISR_OFFSETS 26
ISR_OFFSETS 27
ISR_OFFSETS 28
ISR_OFFSETS 29
ISR_OFFSETS 30
ISR_OFFSETS 31				; end of built-in software interrupts
ISR_OFFSETS 32				; PIC HARDWARE INTTERUPTS START HERE (0x20)
ISR_OFFSETS 33				; PIC keyboard IRQ (remapped)
ISR_OFFSETS 34
ISR_OFFSETS 35
ISR_OFFSETS 36
ISR_OFFSETS 37
ISR_OFFSETS 38
ISR_OFFSETS 39
ISR_OFFSETS 40
ISR_OFFSETS 41
ISR_OFFSETS 42
ISR_OFFSETS 43
ISR_OFFSETS 44
ISR_OFFSETS 45
ISR_OFFSETS 46
ISR_OFFSETS 47
ISR_OFFSETS 48
ISR_OFFSETS 49
ISR_OFFSETS 50


; Misc data
PICmaster_Mask		dw 0
PICslave_Mask		dw 0


PIC_getISR:	;set AH = Slave, AL = Master (In-Service Registers)
	mov al, 0x0A	;read ISR command
	out PIC1_COMMAND, al
	out PIC2_COMMAND, al

	in al, PIC2_COMMAND		; get slave ISR
	shl ax, 8
	in al, PIC1_COMMAND		; get master ISR

	ret


PIC_getIRR:	;set AH = Slave, AL = Master (Interrupt Request Registers)
	mov al, 0x0B	;read IRR command
	out PIC1_COMMAND, al
	out PIC2_COMMAND, al

	in al, PIC2_COMMAND
	shl ax, 8
	in al, PIC1_COMMAND

	ret


PIC_sendEOI:	; send end-of-interrupt command to PIC(s)
	; ARGS -> dl: irq #
	pushad
	mov al, 0x20
	cmp dl, 8
	jl PIC_sendEOI.skipSlave
	out PIC2_COMMAND, al
 .skipSlave:
	out PIC1_COMMAND, al
	popad
	ret


; INPUTS:
; 	ARG1 = low BYTE IRQ#
; OUTPUTS: none
; -- Masks the specified bit for the IRQ number passed to this function.
PIC_DISABLE_IRQ:
	FunctionSetup
	MultiPush eax,ebx,ecx,edx
	ZERO eax,ebx,ecx,edx

	mov cl, 0x01	; set CL = 1 for later shift. Doing it here so it won't have to be done in 2 sep places
	mov eax, dword [ebp+8]	; EAX (AL) = IRQ# to stop/mask
	and eax, 0x000000FF
	cmp eax, 8	; IRQ# >= 8?
	jae .PIC2	; if so, subtract 8 and interact with the slave PIC
	; bleed if < 8
 .PIC1:
    mov bl, al	; BL temp = IRQ#
   	in al, PIC1_DATA	; read master mask
   	call .computeMask
   	out PIC1_DATA, al
   	jmp .leaveCall
 .PIC2:
   	sub al, 8	; AL -= 8
   	mov bl, al	; BL temp = IRQ#
   	in al, PIC2_DATA	; read slave mask
   	call .computeMask
   	out PIC2_DATA, al
   	jmp .leaveCall

 .computeMask:
   	mov dl, al		; DL = CURRENT_MASK
	call COMMAND_DUMP
   	mov cl, bl		; CL = Adjusted IRQ# (mod 8)
   	mov bl, 0x01	; BL = 1
   	shl bl, cl	; (1 << IRQ#)
   	or dl, bl	; (PIC1_MASK_CURRENT | (1<<IRQ#))
	call COMMAND_DUMP
   	mov al, dl	; AL = DL = new mask
   	ret

 .leaveCall:
 	MultiPop edx,ecx,ebx,eax
 	FunctionLeave



; INPUTS:
;	ARG1 = low BYTE IRQ#
; OUTPUTS: none
; -- Clear the specified IRQ# mask (enables the interrupt)
PIC_ENABLE_IRQ:
	FunctionSetup
	MultiPush eax,ebx,ecx,edx
	ZERO eax,ebx,ecx,edx

	mov eax, dword [ebp+8]	; EAX (AL) = IRQ# to stop/mask
	and eax, 0x000000FF
	cmp eax, 8	; IRQ# >= 8?
	jae .PIC2	; if so, subtract 8 and interact with the slave PIC
	; bleed if < 8
 .PIC1:
 	mov bl, al	; BL temp = IRQ#
	in al, PIC1_DATA	; read master mask
	call .computeMask
	out PIC1_DATA, al
	jmp .leaveCall
 .PIC2:
	sub al, 8
	mov bl, al	; BL temp = IRQ#
	in al, PIC2_DATA	; read slave mask
	call .computeMask
	out PIC2_DATA, al
	jmp .leaveCall

 .computeMask:
	mov dl, al		; DL = CURRENT_MASK
	mov cl, bl		; CL = Adjusted IRQ# (mod 8)
	mov bl, 0x01	; BL = 1
	shl bl, cl	; (1 << IRQ#)
	not bl		; Invert CL
	and dl, bl	; (PIC1_MASK_CURRENT & ~(1<<IRQ#))
	mov al, dl	; AL = DL = new mask
	ret

 .leaveCall:
 	MultiPop edx,ecx,ebx,eax
 	FunctionLeave




PIC_remap:		; bh = offsetMaster, bl = offsetSlave
	; Save masks
	in al, PIC1_DATA
	mov byte [PICmaster_Mask], al
	in al, PIC2_DATA
	mov byte [PICslave_Mask], al

	; Initialization command 0x11
	mov al, 0x11
	out PIC1_COMMAND, al
	out PIC2_COMMAND, al

	; Update vector offsets
	mov al, bh
	out PIC1_DATA, al
	mov al, bl
	out PIC2_DATA, al

	; Tell PIC how it's wired between master/slave
	mov al, 00000100b		; Cascase wired up to IRQ2 (1 << 2)
	out PIC1_DATA, al
	mov al, 00000010b		; Cascade Identity for Slave (IRQ 2)
	out PIC2_DATA, al

	; Additional environment information.
	mov al, 1
	out PIC1_DATA, al
	out PIC2_DATA, al

	; Restore masks
	mov byte al, [PICmaster_Mask]
	out PIC1_DATA, al
	mov byte al, [PICslave_Mask]
	out PIC2_DATA, al

	ret


; This was originally ripped from someone else's idea. It has since been deprecated and now just stands as a Placeholder.
isr_common:
	;mov ax, ds				; ax = current data segment selector
	;push eax				; saved onto the stack (4 bytes)

	;mov ax, DATA_SELECTOR	; activate the ring 0 (kernel) data selector
	;mov ds, ax				; this handles calls with highest permission
	;mov es, ax
	;mov fs, ax
	;mov gs, ax

	call isr_handler		;

	;pop eax					; restore original selector to all data segments
	;mov ds, ax
	;mov es, ax
	;mov fs, ax
	;mov gs, ax

	;add esp, 8				; clean up extra stack variables from IRQ routines (pushed error codes and ISR numbers)
	mov al,20h
	out 20h,al  ;; acknowledge the interrupt to the PIC
	;call PIC_sendEOI
	ret


; These two variables are completely uselses and need to be axed, but that can't
;  be done until the IRQ handlers are completed...
szIRQCall				db "Interrupt Called:", 0
iTermLine				db 0
; Deprecated as well, no longer using this but it will still show
; ... on debug/Divby0 errors until they get their own dedicated ISR hooks.
isr_handler:
	pushad
	push edx
	mov esi, szIRQCall		; "IRQ caught message"
	movzx ax, [iTermLine]
	mov cx, 0x00A0
	mul cx
	and eax, 0x0000FFFF
	add eax, 0x000B8000
	mov edi, eax
 .repeat:
	lodsb
	or al, al
	jz .done
	mov ah, 0x0F
	stosw
	jmp .repeat
	;mov dx, 0x0707
	;mov bl, 0x0F
	;call _screenWrite
	;mov eax, [esp + 40]		; reach back into the stack and pull out the IRQ#
	;call _screenPrintDecimal
 .done:
	mov al, [iTermLine]
	inc al
	mov byte [iTermLine], al
	ZERO eax,ebx

	;mov eax, [esp+4]
	pop edx
	mov eax, edx

	mov bl, 0x30	;ASCII '0'
	add ebx, eax
	mov bh, 0x0A
	mov word [edi + 2], bx
	popad
	ret

szGPF db "General Protection Fault! [OFF]", 0
ISR_generalProtectionFault:
	mov bx, 0x3000
	call SCREEN_UpdateCursor
	PrintString szGPF
	cli
	jmp $

szSATAINT db "Secondary ATA...", 0
szSpurious db "Spurious", 0
szRealIRQ db "Real IRQ", 0
ISR_SecondaryATA:
	PrintString szSATAINT,0x02

	; Check for spurious IRQ
	call PIC_getISR		; AH = slave ISR, AL = master ISR
	cmp ah, 10000000b	; Was the bit set?
	je .realIRQ
	mov dl, 0		; only send the master an EOI.
	call PIC_sendEOI
	mov esi, szSpurious
	jmp .leaveFunc
 .realIRQ:
	mov dl, 15		; if it was real, send the EOI to both the slave and the master.
	call PIC_sendEOI
	mov esi, szRealIRQ

 .leaveFunc:
	call SCREEN_Write
	ret


; Placeholder.
ISR_LPTSpurHandler:
	; Check for spurious IRQ
	call PIC_getISR		; AH = slave ISR, AL = master ISR
	cmp al, 10000000b	; Was the IRQ7 bit set?
	je .realIRQ			;yes, send EOI & leave.
	jmp .leaveFunc		;no, leave w/ no EOI.
 .realIRQ:
	mov dl, 7
	call PIC_sendEOI
 .leaveFunc:
	ret


ISR_PHYSICAL_NIC:
	call ETHERNET_IRQ_FIRED
	mov dl, 0x0B
	call PIC_sendEOI
 .leaveCall:
 	ret
