; VFS_definitions.asm
; -- Includes important definitions for both VFS_SETUP and system VFS usage.

VFS_BUFFER_BASE     equ 0x00100000  ; VFS BUFFER starts at 0x00100000
VFS_BUFFER_SIZE     equ 0x01000000  ; 16 MiB long
VFS_BUFFER_END      equ 0x01100000  ; VFS buffer ends at Heap start.

VFS_TABLE_BASE          equ 0x00002000  ; VFS info table starts at 0x2000
VFS_TABLE_END           equ 0x00004000  ; VFS table ends at 0x4000
VFS_TABLE_SIZE          equ 0x00002000  ; VFS table has a max length of 0xFF entries (due to ID)
VFS_TABLE_ENTRY_LENGTH  equ 0x20    ; 32 bytes per entry
VFS_TABLE_CURRENT_ID    db 0x00     ; Current file ID. Stops at 0xFF.

; Structure of a VFS TABLE ENTRY.
; -- Entries are records that point to the Address/Entry Point of the file
; ---- in RAM, give its filename/'alias' that the user can reference, its system ID, and the total size of the file.
VFS_TABLE_ENTRY:    ; 32 bytes in length
    .entry: dd 0x00000000       ; starting address in RAM
    .length: dd 0x00000000      ; how large (in bytes) the file is
    .alias: times 22 db 0x00    ; filenames can be up to 22 characters long
    .aliasTerm: db 0x00         ; forcible null termination/padding
    .fileID: db 0x00             ; Byte-long UNIQUE file identifier.
