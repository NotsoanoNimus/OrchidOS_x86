; ACPI_definitions.asm
; -- Definitions for the ACPI library, to control power management.

ACPI_RSDP       equ 0x00000E00      ; ACPI Root System Description Pointer table base ptr.
ACPI_RSDT       equ 0x00000E04      ; ACPI Root System Description Table base ptr.
ACPI_TABLES     equ 0x00000E08      ; ACPI DWORD OtherSDTPtrs array copy, from RSDT. Array terminated by 0x00000000.

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

; -- RSDT is the main SDT, but there are many others. --
; ACPI SDT Header Formats (structure referenced henceforth as ACPISDTHeader):
;   BYTE Signature (x4)
;  DWORD Length of Table
;   BYTE Revision
;   BYTE Checksum
;   BYTE OEMID (x6)
;   BYTE OEMTableID (x8)
;  DWORD OEMRevision
;  DWORD CreatorID
;  DWORD CreatorRevision

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
ACPI_SIGNATURE_HPET     equ "HPET"  ; --> High Precision Event Timer. Usually only on 64-bit machines...


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
