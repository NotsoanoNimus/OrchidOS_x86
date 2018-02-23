; BOOT.asm
; -- For now, this project assumes that this boot-sector is placed in an MBR of a disk, not a VBR.
; ---- TODO: Get sector/cluster information about the disk and fill in the BPB dynamically (need a disk driver to write it to the sector).
[ORG 0x7C00]
[BITS 16]

jmp short _globalBootStart		; "EB xx 90"
nop

; BIOS Parameter Block.
; --- TODO: Initialize these values in the boot sector, use them later when a FS driver is implemented to back-format the media.
bpbOEM			db "ORCHID  "		; must be exactly 8 chars (bytes).
bpbBytesPerSect dw 0x0200			; block size = 512
bpbSectPerClust db 0x20				; 32 sectors per cluster (16 KiB clusters are typical for a 1GB drive)
bpbReservedSect dw KERNEL_SIZE_SECTORS+3		; For now, 67 sectors are used by the kernel, ST2, and BL. CHANGES AS KERNEL GROWS.
bpbFATs			db 0x02				; There will be two FATs.
bpbRootDirs		dw 0x0200			; Total # of file name entries that can be stored in the root dir. 512 for now = a cluster.
bpbTotalSectors dw 0x0000			; not using this one. The USB stick is >32MB long (bs=512b).
bpbMediaType	db 0xF8				; Fixed disk
bpbSectPerFAT	dw 0x0400			; 1024 sectors per FAT
bpbSectPerTrack dw 0x0020			; 32 sectors/track (??)
bpbHeadsOrSides dw 0x0001			; Number of heads/sides on storage media.
bpbHiddenSects	dd 0x00000000		; No hidden sectors.
bpbActualSects	dd 0x00040000		; 128MB FAT system by default... TEMPORARY UNTIL ORCHID BECOMES FS-CAPABLE AND SELF-AWARE.
; Extended BPB for FAT16
bpbDriveNumber	db 0x80				; Drive number can be filled in later. For now, set it as HDD.
bpbReserved		db 0x00
bpbExtendedBS	db 0x29				; Legacy Windows crap
bpbSerialNumber dd 0x44435230		; "0RCD"
bpbVolumeLabel	db "OrchidOS   "	; 11 bytes, usually not used anymore.
bpbReserved1	db "FAT16  "		; 8-byte section. Microsoft just says "Not used by Windows Server 2003".


_globalBootStart:
; Set up the segments to offset 0x0000
xor ax, ax
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax

cli
mov ss, ax
mov ax, 0x7C00
mov sp, ax		; Stack grows downward from 0x7C00.
sti

mov [bDrive], dl			; Capture the drive number.
mov dword [BOOT_ERROR_FLAGS], 0x00000000	; Set bootloader error flags all off.

call A20_setup				; fast-enable the A20. Not necessary for target systems, but kept JIC.
call _bootLoadKernel		; load stage-two loader into memory and //(tentative) fill BPBTableBase section//.


;Call the stage 2 bootloader.
_globalBootProtMode:
cli						; Keep interruptions away until IDT is loaded by the kernel soon.
lgdt [gdt_descriptor]	; Load up the GDT!

mov dl, [bDrive]
jmp STAGE_TWO_OFFSET



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;; FUNCTIONS ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Load stage 2 bootloader at physical address 0x1000
_bootLoadKernel:
	clc
	push si
	mov ah, 0x42
	mov dl, [bDrive]
	mov si, DiskAddrPkt

	int 0x13		; Read the disk into memory at phys addr 0x1000
	jc .errorRead

	pop si
	ret

 .errorRead:		; Problem? Try again with legacy int 13h.
	pop si
	clc
    xor bx, bx      ; ES:BX = 0x0000:0x1000 = PA 0x1000
	mov bx, 0x1000
	mov ah, 0x02	; AH = 02h = READ DISK FUNCTION.
	mov al, 0x02	; 2 sectors to be read (ST2 = 1024 bytes = 2 sectors)
	mov dh, 0		; Head number.
	mov dl, [bDrive]
	mov cl, 0x02	; Sector number (bits 0-5). (STARTS FROM 1 NOT 0)

	int 0x13
	jc .fatalError
	ret

 .fatalError:
	mov si, szDiskReadError
	call _Bootloopstr
	jmp $


; Print a string in Real Mode.
_Bootloopstr:
	lodsb
	or al, al
	jz _Bootbreakstr
	mov ah, 0x0E
	xor bx, bx
	mov bl, 0x07
	int 0x10
	jmp _Bootloopstr
_Bootbreakstr:
	ret


; Ensure A20 is enabled using fast-enable. Virtually ALL computers after 2001 support this method.
A20_setup:
	push ax
	mov al, 00000010b	; AL = 2 = EnableA20 bit.
	out 0x92, al
	pop ax
 .a20_activated:
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;; DATA ;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GDT. This can be moved to ST2 if the MBR needs space.
ALIGN 16
GDT:
 .null_S:					;8-byte padding, NULL_DESCRIPTOR
	dd 0x0
	dd 0x0
 .data_S: equ $ - GDT		;8-byte entry, DATA_SELECTOR (flat)
	dw 0xFFFF				;Limit 0-15
	dw 0x0000				;Base 0-15
	db 0x00					;Base 16-23
	db 10010010b			;ACCESS BYTE --> Pr, Ring 0, NoEx, Dir ^, isRW, notAc
	db 11001111b			;FLAGS (7-4: 4KiB, 32-bit); LIMIT(16-19=0-3)
	db 0x00					;Base 24-31
 .code_S: equ $ - GDT		;8-byte entry, CODE_SELECTOR (32-bit)
	dw 0xFFFF				;Limit 0-15
	dw 0x0000				;Base 0-15
	db 0x00					;Base 16-23
	db 10011010b			;ACCESS BYTE --> Pr, Ring 0, isEx, Dir ^, isRW, notAc
	db 11001111b 			;FLAGS(7-4: 4KiB, 32-bit); LIMIT(16-19=0-3)
	db 0x00					;Base 24-31
 .userData_S: equ $ - GDT	;8-byte entry, USER_DATA_SELECTOR (32-bit)
	dw 0xFFFF
	dw 0x0000
	db 0x00
	db 11110010b			;ACCESS BYTE --> Pr, Ring 3, NoEx, Dir ^, isRW, notAc
	db 11001111b
	db 0x00
 .userCode_S: equ $ - GDT	;8-byte entry, USER_CODE_SELECTOR (32-bit)
	dw 0xFFFF
	dw 0x0000
	db 0x00
	db 11111010b			;ACCESS BYTE --> Pr, Ring 3, isEx, Dir ^, isRW, notAc
	db 11001111b
	db 0x00
 .RMData_S: equ $ - GDT	;8-byte entry, REAL_MODE_DATA_SELECTOR (16-bit)
 	dw 0xFFFF				;Limit 0-15
	dw 0x0000				;Base 0-15
	db 0x00					;Base 16-23
	db 10010010b			;ACCESS BYTE --> Pr, Ring 0, NoEx, Dir ^, isRW, notAc
	db 00001111b			;FLAGS (7-4: 1B Gran, 16-bit); LIMIT(16-19=0-3)
	db 0x00					;Base 24-31
 .RMCode_S: equ $ - GDT	;8-byte entry, REAL_MODE_CODE_SELECTOR (16-bit)
	dw 0xFFFF				;Limit 0-15
   	dw 0x0000				;Base 0-15
   	db 0x00					;Base 16-23
   	db 10011010b			;ACCESS BYTE --> Pr, Ring 0, isEx, Dir ^, isRW, notAc
   	db 00001111b			;FLAGS (7-4: 1B Gran, 16-bit); LIMIT(16-19=0-3)
   	db 0x00					;Base 24-31
gdt_descriptor:				; DESCRIPTOR = WORD(size-1), followed by DWORD(offset -> address of table)
	dw $ - GDT - 1			;16-bit size
	dd GDT					;32-bit start address

ALIGN 16
DiskAddrPkt:
	db 0x10				; Packet size (16 bytes)
	db 0x00				; Reserved (0)
	dw 0x0002			; Blocks to transfer
	dw 0x1000			; Put at addr 0x1000
	dw 0x0000			; segment 0x0
	dd 0x00000001		; Sector 1 (right after MBR)
	dd 0x00000000

STAGE_TWO_OFFSET	 	equ 0x1000		; PA for ST2.
KERNEL_SIZE_SECTORS		equ 0x0040		; Used in BPB.
BOOT_ERROR_FLAGS		equ 0x0FFC		; Error flags for startup. DWORD of bit-flags. Right underneath the ST2L.
szDiskReadError 		db "Disk read error", 0
bDrive 					db 0

; Reserve space for disk partition information.
times 0x1B4-($-$$) db 0x90	;nop
UID db "ORCHID 0.3"		; Unique ID for disk (unused mostly, just put it there).
PT1 times 16 db 0		; Partition entry 1
PT2 times 16 db 0		; ...
PT3 times 16 db 0		; ...
PT4 times 16 db 0		; ...
dw 0xAA55				; -- MBR Boot signature
