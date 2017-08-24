; BOOT_ST2.asm
; --- Second-stage loader for the orchid kernel.
; --- Performs real-mode operations that the MBR has no space for.
[ORG 0x1000]
[BITS 16]
cli
jmp short BOOT_preLoader
nop

; Print a string in Real Mode.
_realModePrint:
 .continuePrinting:
	lodsb
	or al, al
	jz .leaveCall
	mov ah, 0x0E
	xor bx, bx
	mov bl, 0x07
	int 0x10
	jmp .continuePrinting
 .leaveCall:
	ret

; Load kernel into memory at phys addr 0x10000.
_bootLoadKernelMain:
	push si
	mov ah, 0x42
	mov dl, [bootDrive]
	mov si, KernelDiskAddrPkt

	int 0x13		; Read the disk into memory at phys addr 0x10000
    pop si
    jc .errorRead

	ret

 .errorRead:
    clc
    mov ax, 0x1000
    push es
    mov es, ax
    xor bx, bx                      ; ES:BX = 0x1000:0x0000 = PA 0x10000
    mov ah, 0x02	                ; AH = 02h = READ DISK FUNCTION.
	mov al, KERNEL_SIZE_SECTORS    	; Kernel Size in Sectors. IF THE KERNEL EXCEEDS 1FE SECTORS, THIS WON'T WORK.
	mov dh, 0		                ; Head number.
	mov dl, [bootDrive]
	mov cl, 0x04                   	; Sector number (bits 0-5). (STARTS FROM 1 NOT 0)

    int 0x13
    ;pop es
    jc .fatalError
    pop es
    ret

 .fatalError:
    pop es
	mov si, szKernelReadError
	call _realModePrint
	jmp $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BOOT_preLoader:
	mov byte [bootDrive], dl
	call _bootLoadKernelMain
BOOT_memInfo:
    ; Get memory size.
	pushad
	mov di, MEM_INFO_START		; Buffer starts at 0x500.
	xor bp, bp					; BP will serve as our array index. Tells us how many there are.
	xor ebx, ebx				; EBX = 0
	mov eax, 0x0000E820			; AX = 0xE820
	mov edx, 0x534D4150			; "SMAP"
	mov ecx, 0x00000018			; 24 bytes.
	mov [es:di + 20], DWORD 0x1	; Force a value of 1 in the ACPI space.
	clc
	int 0x15					; Get memory info.
	jc .memCheckError
	mov edx, 0x534D4150			; Fix possibly-trashed register.
	cmp eax, edx				; EAX still the same?
	jne .memCheckError			; Nope, there was an error.
	test ebx, ebx				; EBX = 0? If so, list is only one entry long (not correct, error)
	je .memCheckError
	jmp short .intoMainLoop
 .memCheckLoop:
	mov eax, 0x0000E820			; Restore trashed register.
	mov [es:di + 20], DWORD 0x1	; Force 1 for ACPI.
	mov ecx, 0x00000018			; ECX = 24
	int 0x15
	jc short .endMemTest		; Test is over, CF = no more to read.
	mov edx, 0x534D4150			; save possibly-trashed register.
 .intoMainLoop:
	jcxz .skipEntry				; If CX=0, nothing was read. Test for end of list.
	cmp cl, 20					; 20 or 24-byte entry?
	jle .notExtended			; only 20 bytes read, fill gap
	test BYTE [es:di + 20], 1	; check for valid ACPI value.
	je short .skipEntry
 .notExtended:
	mov ecx, [es:di + 8]		; Get lower 32-bit of mem region length
	or ecx, [es:di + 12] 		; Test the lower dword with the higher one.
	jz .skipEntry				; -- Testing for 0x00000000-00000000.
	inc bp						; increment array size counter, meaning we have a valid value.
	add di, 24					; Successful entry, move to the next one in line.
 .skipEntry:
	test ebx, ebx				; EBX = 0?
	jne .memCheckLoop			; If not zero, return to next check. If it is, bleed into the end of the test.
 .endMemTest:
	;add di, 24					; next place
	mov WORD [es:di], bp		; Store the array size.
	add di, 2
	mov WORD [es:di], 0x1234	; 0x1234xxxx signature, showing the end of the memory table. xxxx = sizeof MEM_INFO.

	clc
	popad
	jmp near BOOT_videoInfo

 .memCheckError:
	mov esi, szMemErr
	call _realModePrint
	jmp $


BOOT_videoInfo:
	mov edi, VGA_INFORMATION	; Clear 1 KiB buffer, from 0x800 to 0xC00 (ST2_ENTRY)
	push edi
	xor eax, eax
	mov ecx, 0x100				; 0x100 * DWORD = 0x400 all zeroed out.
 .cleanBuffer:
	stosd
	loop .cleanBuffer
	pop edi

	mov dword [VGA_INFORMATION], "VBE2"	; "VBE2"
	mov ax, 0x4F00						; Get SuperVGA Mode Information.
	int 0x10
	cmp ax, 0x004F						; does it work?
	jne .errorVESA
	cmp dword [VGA_INFORMATION], "VESA"	; "VESA"
	jne .errorVESA						; if neq "VESA", then VESA isn't supported. Console mode.

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; VESA table format (0x22/34d bytes)
	; * 4 bytes: "VESA". If it's not VESA, then VESA extensions are not supported
	; * 2 bytes: version. High byte - major version; Low byte - minor.
	; * 4 bytes: OEM info --> SEGMENT(high word):OFFSET(low word)
	; * 4 bytes: Capabilities.
	; * 4 bytes: Video Modes --> Pointer to SEGMENT:OFFSET of supported modes.
	; * 2 bytes: Video Memory --> Amount of video memory in 64KB blocks.
	; * 2 bytes: Software Revision.
	; * 4 bytes: Vendor. SEGMENT:OFFSET address to card vendor string.
	; * 4 bytes: Product Name. SEGMENT:OFFSET address to card model name.
	; * 4 bytes: Product Revision. SEGMENT:OFFSET address to product revision.
	; * 222 bytes: reserved for future expansion.
	; * 256 bytes: OEM BIOSes store their strings here.

	; Video Modes = an array of 16-bit WORDs that say which modes are supported. Terminated by 0xFFFF.
	; PROCESS: (1) Check for support in VMA.
    ; -------- (2) Get info about preferred video mode (stored near 0x800).
	; -------- (3) Activate video mode.
    ; -------- (4) GUI programs and graphics drivers are based on a SCALE, not depending on a certain resolution.
	; Try for Mode 0x0118, since it is supported by most, if not all, computers this will be run on.
	; TEMP-FIX: Fall-back to VESA will be starting in Shell mode, telling user that the video mode
    ; ... used by Orchid is not supported on current hardware.

	; Search the VESA_MODES_ARRAY for the mode. CX = index into array.
	push es
	push dx
	mov word es, [VGA_INFORMATION+0x10]		;SEGMENT
	mov word di, [VGA_INFORMATION+0x0E]		;OFFSET
 .repeatSearch1:
	xor dx, dx
	mov word dx, [es:di]
	add di, 2			; checking every WORD value.
	cmp dx, VESA_DESIRED_MODE	; DESIRED MODE: 0x118
	je .endSearch1		; if eq, jump out.
	cmp dx, 0xFFFF
	jne .repeatSearch1
	pop dx
	pop es
	jmp .errorVESA		; jmp to error if the end is found before our desired mode.
 .endSearch1:
	pop dx
	pop es

	; Found mode! Let's get some info and load it up!
	mov di, VESA_CURRENT_MODE_INFO		; 256-byte buffer.
	push di
	xor ax, ax
	mov cx, 0x80						; 128 WORDs to clean
    rep stosw

	; Get info about VESA_DESIRED_MODE and put it at VESA_CURRENT_MODE_INFO
	pop di
	mov ax, 0x4F01
	mov cx, VESA_DESIRED_MODE
	int 0x10
	; Check for success.
	cmp ax, 0x004F
	jne .errorVESA
	; Guarantee Linear Framebuffer support.
	mov word ax, [VESA_CURRENT_MODE_INFO]
	and ax, 0x0080	;0000 0000 1000 0000 --> testing bit 7 (LFB)
	or ax, ax
	jz .errorVESA

	; SET THE MODE!! Resolution 1024x768, assume 24BPP for now (add Alpha channel later).
	mov ax, 0x4F02
	mov bx, 0x4000+VESA_DESIRED_MODE	; bits 0-13 = mode // bit 14 = LFB (enabled) // bit 15 = ignore.
	int 0x10
	cmp ax, 0x004F
	jne .errorVESA

	; SUCCESS!!!!! Flag our kernel, tell it we're in GUI mode.
	mov DWORD [BOOT_ERROR_FLAGS], 0x00000001

	; Comment out to access SHELL_MODE directly.
	; |
	; |
	; V
	;jmp BOOT_protectedMode

 .errorVESA:
	; Something went wrong initiating the GUI video mode. Go to shell mode.
	mov DWORD [BOOT_ERROR_FLAGS], 0x00000000
	xor ax, ax				; al = 00h & ah = 00h
	mov al, 03h				; Mode 03h, 80*25
	int 0x10				; set mode
	jmp BOOT_protectedMode


BOOT_protectedMode:
smsw ax
or ax, 0x1
lmsw ax

jmp CODE_SELECTOR:_bootInitializeSegments

[BITS 32]
_bootInitializeSegments:
	mov eax, DATA_SELECTOR	; flushing segments
	mov ds, ax				; this completes gdt process
	mov es, ax				; and gets us fully into prot mode
	mov fs, ax
	mov gs, ax

	mov ss, ax
	mov ebp, 0x90000		; Stack is located at 0x90000, grows downward. Limit this to 0x10000 bytes (64 KiB, plenty) later.
	mov esp, ebp
	; Jump out of stage-2 loader.
	jmp KERNEL_OFFSET
	hlt    ; should never reach here.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;; DATA ;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 16]
VGA_INFORMATION			equ 0x800
VESA_CURRENT_MODE_INFO 	equ 0xC00
VESA_DESIRED_MODE		equ 0x0118

SCREEN_PITCH			equ VESA_CURRENT_MODE_INFO+0x10		;how many bytes per line.
SCREEN_WIDTH			equ VESA_CURRENT_MODE_INFO+0x12
SCREEN_HEIGHT			equ VESA_CURRENT_MODE_INFO+0x14
SCREEN_BPP				equ VESA_CURRENT_MODE_INFO+0x17
SCREEN_FRAMEBUFFER_ADDR	equ VESA_CURRENT_MODE_INFO+0x28
SCREEN_OFFSCREEN_MEMORY equ VESA_CURRENT_MODE_INFO+0x30

BOOT_ERROR_FLAGS		equ 0x0FFC		; Error flags for startup. DWORD of bit-flags. Right underneath the ST2L.

SYSTEM_BSOD_ERROR_CODE  equ 0x11F8      ; See Kernel definitions section for more info.

NULL_SELECTOR	 		equ 0
DATA_SELECTOR			equ 8			; (1 shl 3) Flat data selector (ring 0)
CODE_SELECTOR			equ 16			; (2 shl 3) 32-bit code selector (ring 0)
;USER_CODE_SELECTOR		equ 24			; (3 shl 3) Usermode code selector (ring 3)
;USER_DATA_SELECTOR 	equ 32			; (4 shl 3) Usermode data selector (ring 3)

KERNEL_OFFSET			equ 0x10000
KERNEL_SEGMENT_OFFSET	equ 0x1000
KERNEL_SIZE_SECTORS		equ 0x0040

MEM_INFO_START			equ 0x500
; Each table of MEM_INFO contains 24 bytes.
; 00h -- QWORD -- Base address.
; 08h -- QWORD -- Length in bytes.
; 10h -- DWORD -- Type of address range.
; 14h -- DWORD -- ACPI field.

bootDrive				db 0

szKernelReadError		db "Could not load Kernel!", 0x0A, 0x0D, 0
szReadVESAFailure		db "Could not get VESA information!", 0x0A, 0x0D, 0
szMemErr				db "Could not get RAM information!", 0x0A, 0x0D, 0

ALIGN 16
KernelDiskAddrPkt:
	db 0x10				; Packet size (16 bytes)
	db 0				; Reserved (0)
	dw KERNEL_SIZE_SECTORS		; Blocks to transfer (sector sizeof kernel)
	dw 0x0000			; OFFSET
	dw KERNEL_SEGMENT_OFFSET	; SEGMENT
	dd 0x00000003		; start at sector 3 (change depending on ST2 loader size)
	dd 0x00000000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




times 238 db 0      ; This padding ensures SYSTEM_BSOD_enterRealMode resides at the end of the ST2 loader.




; System fatal crash function. SYSTEM_BSOD_ERROR holds error code passed from SYSTEM_BSOD call in UTILITY.asm.
; -- Error codes can be found in the orchid documentation.
SYSTEM_BSOD_enterRealMode:
	mov sp, 0x8000
	mov bp, sp
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	lidt [REALMODE_IVT]       ; Reload the original BIOS IVT.
	sti                       ; Enable its interrupts.

    ; Set video mode 03h.
	xor ah, ah
 	mov al, 0x03
	int 0x10

    ; clear the screen.
    mov ah, 0x1F
    mov al, 0x20
    mov cx, 0x07D0
    mov bx, 0xb800
    mov es, bx
    xor di, di      ; ES:DI = 0xb800:0x0000 = PA 0xb8000
    rep stosw

    mov si, szBSODCode
    mov dword eax, [SYSTEM_BSOD_ERROR_CODE]
    mov dword [si], eax
    add si, 4
    mov dword eax, [SYSTEM_BSOD_ERROR_CODE+4]
    mov dword [si], eax
    mov si, szBSODCrash1
    mov di, 0x0142
    call SYSTEM_BSOD_screenOut
    mov si, szBSODCrash2
    mov di, 0x0326
    call SYSTEM_BSOD_screenOut
    mov si, szBSODCrash3
    mov di, 0x0A2E
    call SYSTEM_BSOD_screenOut
	cli
    hlt

SYSTEM_BSOD_screenOut:  ; just a basic real-mode string-printing function.
    mov ah, 0x1F
 .contPrint:
    lodsb
    or al, al
    jz .leaveCall
    stosw
    jmp .contPrint
 .leaveCall:
    ret

szBSODCrash1        db "Oh no!", 0
szBSODCrash2        db "Orchid has encountered a fatal error: 0x"
szBSODCode          db "00000000", 0
szBSODCrash3        db "--- Please restart your system ---", 0
REALMODE_IVT:
	dw 0x03FF		;256 entries @ 4b each = 1KiB
	dd 0x00000000	; RealMode IVT is at 0x0000
SYSTEM_BSOD_ERROR:  ; Pointer is referenced in Kernel as SYSTEM_BSOD_ERROR_CODE. This holds an ASCII rep of the err code.
    dd 0x00000000
    dd 0x00000000


times 1024-($-$$) db 0		; Ensure only 2 sectors.
