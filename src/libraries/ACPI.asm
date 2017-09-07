; ACPI.asm
; -- Advanced Configuration Power Interface: setup functions and driver interaction functions.

ACPI_RSDT       equ 0x00000E04      ; ACPI Root System Description Table base ptr.
ACPI_RSDP       equ 0x00000E00      ; ACPI Root System Description Pointer table base ptr.

ACPI_VERSION     db 0x00            ; BYTE-sized snippet containing verision #

; Root System Description Pointer Table v1.0:
;  BYTE Signature (x8) --> "RSD PTR "
;  BYTE Checksum
;  BYTE OEMID (x6)
;  BYTE Revision
; DWORD RSDTaddress
;+RSDP v2.0+:
;  ((RSDP1.0 Structure))
;  DWORD Length
;  QWORD EXTaddress
;   BYTE EXTchecksum
;   BYTE reserved (x3)


ACPI_initialize:
    pushad
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    xor esi, esi
    xor edi, edi

    call ACPI_findRSDT
    CheckErrorFlags 0x00000080,.leaveCall
    call ACPI_parseRSDT
    CheckErrorFlags 0x00000080,.leaveCall

 .leaveCall:
    popad
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INFORMATION/INIT FUNCTIONS.

ACPI_findRSDT:
    ; Start looking in the EBDA (Xtn BIOS Data Area), pointed to by a segment ptr at BDA addr 0x40E.
    movzx esi, strict word [0x40E]
    shl esi, 4  ;x16 (because it's a segment ptr), this will typically return 0x9FC00, the EBDA.
    ; If the ACPI_RSDP table is in the EBDA, it's only going to be within the first 1KiB of it.
    ; -- The ACPI_RSDP table is always 16-byte-aligned.
    xor ecx, ecx    ;making double-sure
 .searchEBDA:
    cmp dword [esi], "RSD "
    je .sigFirstFound
  .noSecond:
    add esi, 16
    add ecx, 16
    cmp ecx, 1024       ; 1KiB traversed.
    jae .finishEBDA
    jmp .searchEBDA
  .sigFirstFound:
    cmp dword [esi+4], "PTR "
    je .foundRSDPTable
    jmp .noSecond

 .finishEBDA:
    mov esi, 0x000E0000        ; Now check E0000h to FFFFFh.
    xor ecx, ecx
  .testExtMem:
    cmp dword [esi], "RSD "
    je .xtSigFirstFound
  .xtNoSecond:
    add esi, 16
    add ecx, 16
    cmp ecx, 0x20000
    jae .noRSDPFound
    jmp .testExtMem
  .xtSigFirstFound:
    cmp dword [esi+4], "PTR "
    je .foundRSDPTable
    jmp .xtNoSecond

 ; Could not find an RSDP table...
 .noRSDPFound:
    or dword [BOOT_ERROR_FLAGS], 0x00000080     ;set bit 7
    jmp .leaveCall

 ; Found the RSDP
 .foundRSDPTable:
    call ACPI_RSDP_checksum
    cmp eax, 1
    je .noRSDPFound     ; if this jmp occurs, it was due to a faulty/unreliable checksum.
    mov eax, dword [esi+16]     ; Pointer to RSDT is 16 bytes offset into the table.
    mov dword [ACPI_RSDT], eax  ; store the address.
    mov dword [ACPI_RSDP], esi  ; store the base ptr of the RSDP table.
    mov al, byte [esi+15]       ; get VERSION info
    mov byte [ACPI_VERSION], al
    jmp .leaveCall

 .leaveCall:
    ret


; -- Perform a checksum on the ACPI RSDP table (the v1 section only) to make sure it's valid.
; ---- If this fails, ACPI management will NOT initialize on the system.
ACPI_RSDP_checksum:
    push esi
    xor eax, eax        ; double-sure
    xor edx, edx        ; ^^
    xor ecx, ecx
 .sumAll:
    add al, strict byte [esi]
    inc esi
    inc ecx
    cmp cl, 20          ; there are 20 bytes in the table.
    jae .checkSum
    jmp .sumAll
 .checkSum:
    cmp byte al, 0x00   ; if AL = 00h, checksum passed.
    jne .failed
    xor eax, eax
    jmp .leaveCall

 .failed:
    mov eax, 0x00000001
 .leaveCall:
    pop esi
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ACPI_parseRSDT:
    ; For now, we're going to support only ACPI_VERSION = 00 (version 1), so just assume
    ;  the OS is working with an ACPI RSDT, not an XtnSDT, which is usually in 64-bit space.
    call ACPI_RSDT_checkSum
    cmp eax, 1
    jne .continueParsing
    or dword [BOOT_ERROR_FLAGS], 0x00000080     ;set bit 7
    jmp .leaveCall

 .continueParsing:


 .leaveCall:
    ret


ACPI_RSDT_checkSum:
    mov esi, [ACPI_RSDT]
    xor ecx, ecx
    mov cl, strict byte [ACPI_RSDT+4]  ;Table length
    xor eax, eax
 .sumAll:
    add al, strict byte [esi]
    inc esi
    dec cl
    or cl, cl
    jz .checkSum
    jmp .sumAll
 .checkSum:
    cmp byte al, 0x00
    jne .failed
    xor eax, eax
    jmp .leaveCall

 .failed:
    mov eax, 0x00000001
 .leaveCall:
    ret
