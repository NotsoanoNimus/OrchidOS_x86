; ACPI_definitions.asm
; -- Definitions for the ACPI library, to control power management.

IS_ON_EMULATOR   db FALSE           ; 0 = not running from an emulator; 1 = yes. Used for things like shutdown.
; ^ is set in ACPI_parseRSDT.
IS_ACPI_ENABLED  db FALSE           ; 0 = no; 1 = yes. Used for quick reference.

ACPI_RSDP       equ 0x00000E00      ; ACPI Root System Description Pointer table base ptr.
ACPI_RSDT       equ 0x00000E04      ; ACPI Root System Description Table base ptr.
ACPI_FADT       equ 0x00000E08      ; ACPI Fixed ACPI Description Table base ptr.
ACPI_DSDT       equ 0x00000E0C      ; ACPI Differentiated System Description Table base ptr.
ACPI_MADT       equ 0x00000E10      ; ACPI Multi APIC Description Table base ptr.
ACPI_TABLES     equ 0x00000E20      ; ACPI DWORD OtherSDTPtrs array copy, from RSDT. Array terminated by 0x00000000.
ACPI_VERSION     db 0x00            ; BYTE-sized snippet containing verision #. Comes from RSDP Table.

ACPI_PM1a_CNT    dd 0x00000000
; ACPI1.0, 4.7.3.2.1: "PM1 control registers contain the fixed feature control bits. These bits can be split
;  between two registers: PM1a_CNT, or PM1b_CNT. Each register grouping can be at a different 32-bit aligned
;  address and is pointed to by the PM1a_CNT_BLK or PM1b_CNT_BLK. Accesses are controlled through words & bytes.

ACPI_MGMT_CMD_PORT      dd 0x00000000
ACPI_ENABLE_COMMAND     db 0x00
ACPI_DISABLE_COMMAND    db 0x00
ACPI_PREF_POWER_PROFILE db 0x00
ACPI_SCI_INTERRUPT      dw 0x0000

; A few variables for system shutdown.
; To properly shutdown with ACPI: out ACPI_FADT_PM1_A_CONTROLBLOCK (DWORD), (ACPI_SLP_TYPa | ACPI_SLP_EN) (WORD)
ACPI_S5_SLP_TYPa   dw 0x0000
ACPI_S5_SLP_TYPb   dw 0x0000

; Some misc definitions...
ACPI_SLP_EN     equ 1<<13

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

; The values here are OFFSETS into the ACPISDTHeader.
; -- RSDT is the main SDT, but there are many others. --
; ACPI SDT Header Formats (structure referenced henceforth as ACPISDTHeader):
ACPI_HEADER_SIGNATURE       equ 0   ;   BYTE Signature (x4)
ACPI_HEADER_LENGTH          equ 4   ;  DWORD Length of Table
ACPI_HEADER_REVISION        equ 8   ;   BYTE Revision
ACPI_HEADER_CHECKSUM        equ 9   ;   BYTE Checksum
ACPI_HEADER_OEMID           equ 10  ;   BYTE OEMID (x6)
ACPI_HEADER_OEMTABLEID      equ 16  ;   BYTE OEMTableID (x8)
ACPI_HEADER_OEMREVISION     equ 24  ;  DWORD OEMRevision
ACPI_HEADER_CREATORID       equ 28  ;  DWORD CreatorID
ACPI_HEADER_CREATORREVISION equ 32  ;  DWORD CreatorRevision

SIZEOF_ACPISDTHeader    equ 0x24    ; ACPISDTHeader structs are 36 bytes each.

; RSDT format:
;  STRUCT ACPISDTHeader
;   DWORD PtrToOtherSDT[(ACPISDTHeader->Length - sizeof(ACPISDTHeader)) / 4]
;           `---> An array of 32-bit addresses to other SDTs. Each SDT will have a unique signature field.

; Known ACPISDTHeader Signatures (supported):
ACPI_SIGNATURE_RSDT     equ "RSDT"  ; --> Root System Desc Table (the main SDT that has addresses to others)
ACPI_SIGNATURE_FADT     equ "FACP"  ; --> Fixed ACPI Desc Table (info abt fixed register blocks rel to power mgmt)
ACPI_SIGNATURE_MADT     equ "APIC"  ; --> Multi APIC Desc Table (describes how the APIC works)
ACPI_SIGNATURE_DSDT     equ "DSDT"  ; --> Differentiated SDT (see below for info).
; DSDT is a major SDT that describes the peripherals of a machine, holds PIC IRQ mappings, and manages power.
ACPI_SIGNATURE_SSDT     equ "SSDT"  ; --> Secondary SDT (enc. in AML; acts as supplement to DSDT)

; Known uncommon signatures (ones currently unsupported by orchid):
ACPI_SIGNATURE_BERT     equ "BERT"  ; --> Boot Error Record Table.
ACPI_SIGNATURE_CPEP     equ "CPEP"  ; --> Corrected Platform Error Polling Table.
ACPI_SIGNATURE_ECDT     equ "ECDT"  ; --> Embedded Controller Boot Resources Table.
ACPI_SIGNATURE_EINJ     equ "EINJ"  ; --> Error Injection Table.
ACPI_SIGNATURE_ERST     equ "ERST"  ; --> Error Record Serialization Table.
ACPI_SIGNATURE_FACS     equ "FACS"  ; --> Firmware ACPPI Control Structure.
ACPI_SIGNATURE_HEST     equ "HEST"  ; --> Hardware Error Source Table.
ACPI_SIGNATURE_MSCT     equ "MSCT"  ; --> Maximum System Characteristics Table.
ACPI_SIGNATURE_MPST     equ "MPST"  ; --> Memory Power State Table.
ACPI_SIGNATURE_OEMx     equ "OEMX"  ; --> OEM-specific info table. Any table beginning with OEM (4th char corr to 'X').
ACPI_SIGNATURE_PMTT     equ "PMTT"  ; --> Platform Memory Topology Table.
ACPI_SIGNATURE_PSDT     equ "PSDT"  ; --> Persistent System Description Table.
ACPI_SIGNATURE_RASF     equ "RASF"  ; --> ACPI RAS Feature Table.
ACPI_SIGNATURE_SBST     equ "SBST"  ; --> Smart Battery Specification Table.
ACPI_SIGNATURE_SLIT     equ "SLIT"  ; --> System Locality Information Table.
ACPI_SIGNATURE_SRAT     equ "SRAT"  ; --> System Resource Affinity Table.
; Third-party signatures will have zero support for the forseeable future, until AML parsing is 100% accurate.

; Known special devices:
ACPI_SIGNATURE_HPET     equ "HPET"  ; --> High Precision Event Timer. Staying with PIT.


; GenericAddrStruct.AddressSpace known possible values (that are not in a range).
ACPI_ADDR_SPACE_SYSMEM  equ 0x00        ; System Memory
ACPI_ADDR_SPACE_SYSIO   equ 0x01        ; System I/O
ACPI_ADDR_SPACE_PCICONF equ 0x02        ; PCI Configuration Space
ACPI_ADDR_SPACE_EMBCONT equ 0x03        ; Embedded Controller
ACPI_ADDR_SPACE_SMBUS   equ 0x04        ; SMBus
; 0x05 to 0x7E : Reserved
ACPI_ADDR_SPACE_FFHW    equ 0x7E        ; Functional, Fixed Hardware.
; 0x80 to 0xBF : Reserved
; 0xC0 to 0xFF : OEM-defined.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; FADT Definitions (each definition is an OFFSET into the FADT).
ACPI_FADT_FIRMWARE_CONTROL      equ SIZEOF_ACPISDTHeader    ;DWORD
ACPI_FADT_DSDT_PTR              equ SIZEOF_ACPISDTHeader+4  ;DWORD
ACPI_FADT_RESERVED_1            equ SIZEOF_ACPISDTHeader+8  ;BYTE
ACPI_FADT_PREF_POWER_MGMT_PROF  equ SIZEOF_ACPISDTHeader+9  ;BYTE - See section above about values for this field.
ACPI_FADT_SCI_INT               equ SIZEOF_ACPISDTHeader+10 ;WORD - Interrupt on the 8259 PIC for events like Power Button.
ACPI_FADT_SMI_CMD_PORT          equ SIZEOF_ACPISDTHeader+12 ;DWORD - I/O Port to get/release ownership over ACPI regs. 0 if already done for you.
ACPI_FADT_ACPI_ENABLE           equ SIZEOF_ACPISDTHeader+16 ;BYTE
ACPI_FADT_ACPI_DISABLE          equ SIZEOF_ACPISDTHeader+17 ;BYTE
ACPI_FADT_S4BIOS_REQ            equ SIZEOF_ACPISDTHeader+18 ;BYTE
ACPI_FADT_PSTATE_CONTROL        equ SIZEOF_ACPISDTHeader+19 ;BYTE
ACPI_FADT_PM1_A_EVENTBLOCK      equ SIZEOF_ACPISDTHeader+20 ;DWORD
ACPI_FADT_PM1_B_EVENTBLOCK      equ SIZEOF_ACPISDTHeader+24 ;DWORD
ACPI_FADT_PM1_A_CONTROLBLOCK    equ SIZEOF_ACPISDTHeader+28 ;DWORD
ACPI_FADT_PM1_B_CONTROLBLOCK    equ SIZEOF_ACPISDTHeader+32 ;DWORD
ACPI_FADT_PM2_CONTROLBLOCK      equ SIZEOF_ACPISDTHeader+36 ;DWORD
ACPI_FADT_PM_TIMERBLOCK         equ SIZEOF_ACPISDTHeader+40 ;DWORD
ACPI_FADT_GPE0BLOCK             equ SIZEOF_ACPISDTHeader+44 ;DWORD
ACPI_FADT_GPE1BLOCK             equ SIZEOF_ACPISDTHeader+48 ;DWORD
ACPI_FADT_PM1_EVENTLENGTH       equ SIZEOF_ACPISDTHeader+52 ;BYTE
ACPI_FADT_PM1_CONTROLLENGTH     equ SIZEOF_ACPISDTHeader+53 ;BYTE
ACPI_FADT_PM2_CONTROLLENGTH     equ SIZEOF_ACPISDTHeader+54 ;BYTE
ACPI_FADT_PM_TIMERLENGTH        equ SIZEOF_ACPISDTHeader+55 ;BYTE
ACPI_FADT_GPE0LENGTH            equ SIZEOF_ACPISDTHeader+56 ;BYTE
ACPI_FADT_GPE1LENGTH            equ SIZEOF_ACPISDTHeader+57 ;BYTE
ACPI_FADT_CSTATE_CONTROL        equ SIZEOF_ACPISDTHeader+58 ;BYTE
ACPI_FADT_WORST_C2_LATENCY      equ SIZEOF_ACPISDTHeader+59 ;WORD
ACPI_FADT_WORST_C3_LATENCY      equ SIZEOF_ACPISDTHeader+61 ;WORD
ACPI_FADT_FLUSH_SIZE            equ SIZEOF_ACPISDTHeader+63 ;WORD
ACPI_FADT_FLUSH_STRIDE          equ SIZEOF_ACPISDTHeader+65 ;WORD
ACPI_FADT_DUTY_OFFSET           equ SIZEOF_ACPISDTHeader+67 ;BYTE
ACPI_FADT_DUTY_WIDTH            equ SIZEOF_ACPISDTHeader+68 ;BYTE
ACPI_FADT_DAY_ALARM             equ SIZEOF_ACPISDTHeader+69 ;BYTE
ACPI_FADT_MONTH_ALARM           equ SIZEOF_ACPISDTHeader+70 ;BYTE
ACPI_FADT_CENTURY               equ SIZEOF_ACPISDTHeader+71 ;BYTE

ACPI_FADT_BOOT_ARCH_FLAGS       equ SIZEOF_ACPISDTHeader+72 ;WORD - Reserved in ACPI1.0, used in ACPI2.0+.
ACPI_FADT_RESERVED_2            equ SIZEOF_ACPISDTHeader+73 ;BYTE
ACPI_FADT_FLAGS                 equ SIZEOF_ACPISDTHeader+74 ;DWORD

ACPI_FADT_GAS_RESET_REGISTER    equ SIZEOF_ACPISDTHeader+78 ;12-byte GAS struct (see above).

ACPI_FADT_RESET_VALUE           equ SIZEOF_ACPISDTHeader+90 ;BYTE
ACPI_FADT_RESERVED_3            equ SIZEOF_ACPISDTHeader+91 ;BYTE+WORD --> char[3] --> Reserved.
; Anything beyond this point in the FADT is only available in ACPI2.0+, which is unsupported by Orchid.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Required AML opcode definitions.
AML_NAMEOP          equ 0x08

AML_BYTE_PREFIX     equ 0x0A
AML_WORD_PREFIX     equ 0x0B
AML_DWORD_PREFIX    equ 0x0C
AML_STRING_PREFIX   equ 0x0D
AML_QWORD_PREFIX    equ 0x0E

AML_PACKAGE         equ 0x12
