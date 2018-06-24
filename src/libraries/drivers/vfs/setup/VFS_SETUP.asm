; VFS_SETUP.asm
; -- Setup definitions and functions for the Virtual File System in system RAM.


; Called by the INIT.asm file during system initialization.
VFS_initialize:
    call VFS_BUFFER_CLEAR_ALL
    call VFS_TABLE_CLEAR_ENTRY_BUFFER
 .leaveCall:
    ret
    

; Destroy every file/bit in the VFS_BUFFER and in the VFS_TABLE.
VFS_BUFFER_CLEAR_ALL:
    pushad
    ZERO eax,ecx
    mov edi, VFS_BUFFER_BASE    ; point EDI to the beginning of the VFS_BUFFER table to prepare cleaning.
    mov ecx, (VFS_BUFFER_SIZE/4)  ; div by 4 because this will be a DWORD operation and the size is always aligned.
    rep stosd
    mov edi, VFS_TABLE_BASE
    mov ecx, (VFS_TABLE_SIZE/4)
    rep stosd
 .leaveCall:
    popad
    ret


; Clean the VFS_TABLE_ENTRY variable (and subvars) so that the next copy into memory is clean.
VFS_TABLE_CLEAR_ENTRY_BUFFER:
    MultiPush edi,eax,ecx
    ZERO eax
    mov edi, VFS_TABLE_ENTRY
    mov ecx, 0x00000008 ; 8 loops
    rep stosd
 .leaveCall:
    MultiPop ecx,eax,edi
    ret
