; ACPI.asm
; -- Advanced Configuration Power Interface: mostly setup functions.

%include "libraries/drivers/ACPI/setup/ACPI_SETUP_definitions.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MAIN INIT FUNCTION. This function gathers all important ACPI driver setup variables from the ACPI memory,
;  and will eventually select a default/preferred power policy for the system.
ACPI_initialize:    ; Called from INIT.asm.
    pushad
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    xor esi, esi
    xor edi, edi

    call ACPI_findRSDT      ; find the root table.
    CheckErrorFlags 0x00000080,.leaveCall
    call ACPI_parseRSDT     ; get the other system tables from the root.
    CheckErrorFlags 0x00000080,.leaveCall
    call ACPI_iterateOtherSDTs  ; iterate through the other system tables from the root, searches for primary ones for now.
    CheckErrorFlags 0x00000080,.leaveCall
    ; At this point, we have the base addr of the FADT, DSDT, & MADT (if it exists).
    ;  Now TO-DO: gain control over ACPI registers,
    ;  -- set preferred power management profile, based on value in ACPI_FADT_PREF_POWER_MGMT_PROF.

    call ACPI_populateFieldsViaFADT     ; Very important function that gets a lot of system ACPI information.
    CheckErrorFlags 0x00000080,.leaveCall

    call ACPI_getShutdownHandlers       ; Another crucial piece to search for. Need to get \_S5_ information.
    CheckErrorFlags 0x00000040,.leaveCall

    ;call ACPI_enable    ; Enable the ACPI by writing ACPI_ENABLE_COMMAND to ACPI_MGMT_CMD_PORT.
    ; no need to enable ACPI yet, until a full driver is written to control power policing. Coming soon!
    call ACPI_setPowerProfile  ; activate the preferred power profile, based on ACPI_PREF_POWER_PROFILE.

 .leaveCall:
    popad
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INFORMATION/INIT FUNCTIONS.

ACPI_findRSDT:
    pushad
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
    cmp byte [ACPI_VERSION], 0x00
    je .noError       ; no support for versions >ACPI 1.0
    or dword [BOOT_ERROR_FLAGS], 0x00000080
   .noError:
    jmp .leaveCall

 .leaveCall:
    popad
    ret

; -- Perform a checksum on the ACPI RSDP table (the v1 section only) to make sure it's valid.
; ---- If this fails, ACPI management will NOT initialize on the system.
ACPI_RSDP_checksum:
    pushad
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
    popad
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ACPI_parseRSDT:
    pushad
    ; For now, we're going to support only ACPI_VERSION = 00 (version 1), so just assume
    ;  the OS is working with an ACPI RSDT, not an XtnSDT, which is usually in 64-bit space.

    ; ==> BUG: This checksum is currently flawed and needs review.
    ;call ACPI_RSDT_checkSum
    ;cmp eax, 1
    ;jne .continueParsing
    ;or dword [BOOT_ERROR_FLAGS], 0x00000080     ;set bit 7
    ;jmp .leaveCall
    mov esi, [ACPI_RSDT]
    cmp dword [esi+0x0A], "BOCH"
    jne .continueParsing
    mov byte [IS_ON_EMULATOR], TRUE
 .continueParsing:
    mov esi, [ACPI_RSDT]
    xor ecx, ecx
    mov cl, strict byte [esi+4]     ; get RSDT table length
    sub cl, SIZEOF_ACPISDTHeader    ; subtract the size of the default header. Now CL = array size.
    add esi, SIZEOF_ACPISDTHeader   ; move esi up to the first entry of the SDTPtrArray
    mov edi, ACPI_TABLES            ; get ready to copy the pointer array.
  .getNextEntry:
    cmp cl, 0
    jle .leaveCall
    movsd
    sub cl, 4
    jmp .getNextEntry

 .leaveCall:
    popad
    ret


ACPI_RSDT_checkSum:
    pushad
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
    popad
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Find the important tables. If more are to be added, it should be fairly simple to implement and get types.
ACPI_iterateOtherSDTs:
    pushad
    mov dword esi, ACPI_TABLES    ;load first table pointer
    xor ebx, ebx
 .iterate:
    cmp dword [esi], 0x00000000     ;end of ACPI_TABLES?
    je .leaveCall
    mov ebx, dword [esi]
    cmp dword [ebx], ACPI_SIGNATURE_FADT    ;load table's signature, and cmp it to the FADT.
    je .FADT
    cmp dword [ebx], ACPI_SIGNATURE_MADT    ;MADT?
    je .MADT
    ;cmp dword [esi], ACPI_SIGNATURE_SSDT   ;SSDT?
    ;je .SSDT
  .nextIteration:
    add esi, 4      ; next base ptr
    jmp .iterate

 .FADT:
    push esi
    push ebx
    mov dword [ACPI_FADT], ebx
    mov esi, ebx
    add esi, ACPI_FADT_DSDT_PTR
    mov ebx, dword [esi]
    cmp dword [ebx], ACPI_SIGNATURE_DSDT
    je .DSDTGood
    or dword [BOOT_ERROR_FLAGS], 0x00000080
    jmp .leaveCall
  .DSDTGood:
    mov dword [ACPI_DSDT], ebx
    pop ebx
    pop esi
    jmp .nextIteration
 .MADT:
    mov dword [ACPI_MADT], ebx
    jmp .nextIteration
 .leaveCall:
    popad
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Populate important fields from the FADT.
ACPI_populateFieldsViaFADT:
    pushad
    xor ebx, ebx        ; double-sure
    mov esi, dword [ACPI_FADT]  ; Get FADT base address.

    mov ebx, dword [esi+ACPI_FADT_SMI_CMD_PORT]
    mov dword [ACPI_MGMT_CMD_PORT], ebx
    mov bl, strict byte [esi+ACPI_FADT_ACPI_ENABLE]
    mov byte [ACPI_ENABLE_COMMAND], bl
    mov bl, strict byte [esi+ACPI_FADT_ACPI_DISABLE]
    mov byte [ACPI_DISABLE_COMMAND], bl
    mov bl, strict byte [esi+ACPI_FADT_PREF_POWER_MGMT_PROF]
    mov byte [ACPI_PREF_POWER_PROFILE], bl
    mov bx, strict word [esi+ACPI_FADT_SCI_INT]
    mov word [ACPI_SCI_INTERRUPT], bx
    mov ebx, dword [esi+ACPI_FADT_PM1_A_CONTROLBLOCK]
    mov dword [ACPI_PM1a_CNT], ebx
 .leaveCall:
    popad
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; (EN/DIS)ABLE the ACPI.

; Enable ACPI through the management register. ACPI_SCI_ENABLE will be set to tell OS that hardware's now configured for ACPI.
; Note: SCI INT can only fire once the OS enables on of the GPE/PM1 bits.
; ACPI_ENABLE is only needed ONE TIME, and is not necessary when coming out of S3, S2, or S1.
ACPI_enable:
    pushad
    mov al, byte [ACPI_ENABLE_COMMAND]
    mov edx, dword [ACPI_MGMT_CMD_PORT]
    out dx, al
    ; make sure it's on, and enable bits explained above.
    mov byte [IS_ACPI_ENABLED], TRUE
 .leaveCall:
    popad
    ret

; In order to disable ACPI, orchid must unload all ACPI drivers, disable all ACPI events, finish using ACPI registers,
;  send ACPI_DISABLE_COMMAND to ACPI_MGMT_CMD_PORT, and then let the BIOS take over and pass control to legacy mode.
ACPI_disable:
    pushad

 .leaveCall:
    popad
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Find the system's preferred power profile based on the FADT's value.
;  In order to add a preferred 'profile', the profiles must be defined in the first place,
;   inclusive of everything the policy must manage.
ACPI_setPowerProfile:
    pushad

 .leaveCall:
    popad
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Setup the required variables for a system shutdown.
ACPI_getShutdownHandlers:
    pushad
    mov esi, [ACPI_DSDT]            ; Start in DSDT.
    mov ecx, dword [esi+ACPI_HEADER_LENGTH]
    add esi, SIZEOF_ACPISDTHeader   ;Skip generic header.
 .searchForS5:
    cmp dword [esi], "_S5_"
    je .foundS5
    inc esi
    loop .searchForS5

 .errorGettingHandlers:
    or dword [BOOT_ERROR_FLAGS], 0x00000040     ; code reached end of loop without jmping, meaning failure.
    jmp .leaveCall

 .foundS5:  ;when jumping to this label, ESI = the base of _S5_.
    ; if !(([esi-1] == AML_NAMEOP || ([esi-1] == '\\' && [esi-2] == AML_NAMEOP)) && [esi+4] == AML_PACKAGE) {goto error}
    cmp byte [esi-1], AML_NAMEOP
    je .moreSurety
    cmp byte [esi-1], '\'           ; most AML DSDTs have the definitions laid out as: '\_S5_'
    jne .errorGettingHandlers
    cmp byte [esi-2], AML_NAMEOP    ; according to ACPI spec for 1.0, the NameOp always precedes the string name of the package.
    jne .errorGettingHandlers
 .moreSurety:   ; look for AML_PACKAGE after the string.
    cmp byte [esi+4], AML_PACKAGE
    jne .errorGettingHandlers

    add esi, 5  ; Go to PACKAGE_SIZE.
    ; calculate package size. Sometimes it can have bits 6&7 set to encode additional package info (up to 2 extra spaces).
    ; To eliminate this skewing, we'll see if those are set, and if they are, skip over them.
    xor eax, eax
    mov al, strict byte [esi]   ;get pkg size
    and al, 11000000b           ; & 0x0C
    shr al, 6                   ; >>6
    add al, 2       ; now, if bits 6&7 were set to mean 2 extra spaces before the S5 definitions, it is taken care of.
    add esi, eax    ; ESI now points to the first parts of the package (SLP_TYPa).
    xor ecx, ecx
 .iterateS5toFindSLP_TYPab:    ; just a label for clarity.
    cmp byte [esi], AML_BYTE_PREFIX     ;JIC the AML is defining the value as a BYTE --> 0x0A,0x[SLP_TYPa/b]
    jne .skipBytePrefixA
    inc esi
   .skipBytePrefixA:
    mov cl, strict byte [esi]   ; FOR LATER REFERENCE: see section 7.5.2 of ACPI1.0 spec.
    shl cx, 10
    mov word [ACPI_S5_SLP_TYPa], cx

    ; now get SLP_TYPb...
    inc esi
    cmp byte [esi], AML_BYTE_PREFIX
    jne .skipBytePrefixB
    inc esi
   .skipBytePrefixB:
    mov cl, strict byte [esi]
    xor ch, ch
    shl cx, 10
    mov word [ACPI_S5_SLP_TYPb], cx

 .leaveCall:
    popad
    ret
