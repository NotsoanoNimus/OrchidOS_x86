; VFS.asm
; -- Primary header file for Virtualized File System functions and operations.
; ---- This file goes hand-in-hand with memops in how it uses those functions to manipulate the VFS in RAM.

%include "libraries/drivers/vfs/setup/VFS_definitions.asm"
%include "libraries/drivers/vfs/setup/VFS_SETUP.asm"

; Called by the INIT.asm file during system initialization.
VFS_initialize:
    call VFS_BUFFER_CLEAR_ALL
    call VFS_TABLE_CLEAR_ENTRY_BUFFER
 .leaveCall:
    ret


; INPUTS:
;   ARG1 = Ptr to base of alias/name of the file (string).
; OUTPUTS:
;   EAX = File ID.
; Return the ID of a file based on its alias/name.
VFS_GET_FILE_ID:
    push ebp
    mov ebp, esp
    push edi
    push esi

    ;mov edi, VFS_TABLE_BASE     ;EDI = start of VFS_TABLE
    mov esi, dword [ebp+8]      ;ESI = arg1

    STRSCAN VFS_TABLE_BASE,VFS_TABLE_END,esi    ;EAX = the beginning of the alias location in the VFS TABLE.
    mov edi, eax    ; EDI = pointer to string
    xor eax, eax    ; clean EAX
    add edi, 23     ; 23 bytes ahead (string + null-term) = the ID of the file.
    mov al, strict byte [edi]

 .leaveCall:
    pop esi
    pop edi
    pop ebp
    ret


; INPUTS:
;   ARG1 = File ID#
; OUTPUTS:
;   EAX = Memory pointer to base of name string.
; Return a pointer to the alias/name of a file.
VFS_GET_FILE_NAME:
    push ebp
    mov ebp, esp
    push ebx
    push ecx

    movzx ecx, byte [VFS_TABLE_CURRENT_ID]  ; put the count of the to-be-delegated id into CL.
    mov ebx, dword [ebp+8]  ; EBX = arg1 = file ID#
    and ebx, 0x000000FF     ; Force BL only

 .leaveCall:
    pop ecx
    pop ebx
    pop ebp
    ret
