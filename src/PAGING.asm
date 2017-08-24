; PAGING.asm
; --- Set up paging here.
pageBasePtr		dd 0		;will be used when pages are expanded (maybe).

PAGE_PRESENT	equ 00000001b
PAGE_RW			equ 00000010b
PAGE_USERMODE	equ 00000100b

PAGE_TABLES_START			equ 0x00100000
PAGE_DIRECTORY_START		equ 0x0006F000
CR3_PAGE_DIR_BASE_PTR_LOC	equ 0x0006EFF8

; Page Table Entry format:
; --Bits--	  --Value--
;	31-12		Frame address. The high 20 bits of frame address in physical memory.
;	11-09		Available for Kernel use (custom OS use).
;	08-07		RESERVED.
;	06			Dirty. Page contains data.
;	05			Accessed. Page has been or is being accessed.
;	04-03		RESERVED.
;	02			User/Supervisor. Set page privilege level. 1=User
;	01			Read/Write. 1=Writable // 0=Read-only.
;  	00			Page Present.

; ALL PAGING MAPS/TABLES ARE DONE FROM 0x70000 to 0x80000 (64 KiB of space.)
; Paging setup:
; 0x9EFF8 = PDBP (Page Directory Base Pointer) --> CR3, contains the physical addr of page directory start.
; 0x9F000 = PDE (Page Directory - 4KiB large, 32-bit entries [1024 entries total])
; 			-- Each PDEntry is a 32-bit address of a Page Table Entry
; 0x100000 = PTE (Page Table 1 -- 4KiB large, each). See PTE format note above. 
_initPaging:
	pushad
	mov edi, CR3_PAGE_DIR_BASE_PTR_LOC		;PDBP
	push edi
	
	mov edi, PAGE_TABLES_START
	xor eax, eax
	mov ecx, 0x00040000				; Clear 0x100000 spaces to zero. (1 MiB (PDTs)) // NO: 1 KiB (PDEs), + a DWORD for PDBP)
	rep stosd
	mov edi, PAGE_DIRECTORY_START
	mov ecx, 0x00000400				; 4 KiB (0x400 * DWORD)
	rep stosd
	
	; Map directory to PTs. Each PT is at a 4KiB boundary. A whole PT maps about 0x4000 KiB (or 16MiB). Take this off of total mem available.
	mov edi, PAGE_DIRECTORY_START	; PD starting addr (first entry's linear address).
	mov eax, PAGE_TABLES_START		; PT starting addr (first entry's linear address).
	mov ecx, [iMemoryTotal]			; Total Memory in KiB.
	;sub ecx, 0x800				; MINUS: 2MiB for initial kernel/paging area.
	;mov ecx, 0x00400000				; 400,000 KiB = 4GiB
	;or eax, (PAGE_PRESENT|PAGE_RW)
 .mapDirectory:
	mov dword [edi], eax
	add eax, 0x1000					; each PTE is 4KiB.
	jo .doneMappingDir
	add edi, 4
	sub ecx, 0x1000				; Each PT entry is 4MiB of mapped memory.
	js .doneMappingDir
	cmp ecx, 1
	jl .doneMappingDir
	jmp .mapDirectory
 .doneMappingDir:
	
	; Map system tables.
	mov edi, PAGE_TABLES_START	; PageTable1 starting linear addr.
	mov ecx, [iMemoryTotal]		;Memory size in KiB
	xor eax, eax				; IDENTITY PAGING.
	or eax, (PAGE_PRESENT|PAGE_RW)
 .mapLoop:
	mov dword [edi], eax		; MAP
	add eax, 0x1000
	;jo .doneMappingPTs
	add edi, 4					; next 32 bits
	sub ecx, 0x4				;	4 KiB mapped per entry in the table
	js .doneMappingPTs
	cmp ecx, 1
	jl .doneMappingPTs
	jmp .mapLoop

 .doneMappingPTs:
	
	pop edi					; Restore the pointer to the PDBP
	mov dword [edi], PAGE_DIRECTORY_START	; Map PDBP to PAGE_DIRECTORY_START.
	mov edx, edi			; Transfer pointer to EDX
	mov cr3, edx			; Load Page Directory Ptr Table into CR3
	
	;mov eax, cr4			; Get CR4 register values.
	;or eax, 10100000b		; OR operation with 10100000b (enable bit 5&7, PAE&PGE)
	;mov cr4, eax			; Physical Address Extension enabled. Page Global Enable set.	
	
	; Disable this and three lines above on ACTUAL HARDWARE.
	mov eax, cr0			; Get CR0 values
	or eax, 0x80000000		; (1 shl 31) --> Activate paging
	mov cr0, eax			; Set flag.
	
	popad
	ret

