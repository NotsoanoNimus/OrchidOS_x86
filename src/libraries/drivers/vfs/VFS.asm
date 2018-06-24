; VFS.asm
; -- Primary header file for Virtualized File System functions and operations.
; ---- This file goes hand-in-hand with memops in how it uses those functions to manipulate the VFS in RAM.

%include "libraries/drivers/vfs/setup/VFS_definitions.asm"
%include "libraries/drivers/vfs/setup/VFS_SETUP.asm"


; INPUTS:
;   ARG1 = Ptr to base of alias/name of the file (string).
; OUTPUTS:
;   EAX = File ID.
; CARRY ON ERROR!
; Return the ID of a file based on its alias/name.
VFS_GET_FILE_ID:
    FunctionSetup
    MultiPush edi,esi
    ;mov edi, VFS_TABLE_BASE     ;EDI = start of VFS_TABLE
    mov esi, dword [ebp+8]      ;ESI = arg1
    clc

    STRSCAN VFS_TABLE_BASE,VFS_TABLE_END,esi    ;EAX = the beginning of the alias location in the VFS TABLE.
    or eax, eax     ; null pointer returned?
    jz .notFound
    mov edi, eax    ; EDI = pointer to string
    xor eax, eax    ; clean EAX
    add edi, 23     ; 23 bytes ahead (string + null-term) = the ID of the file.
    mov al, strict byte [edi]
    jmp .leaveCall

 .notFound:
    stc
 .leaveCall:
    MultiPop esi,edi
    FunctionLeave


; INPUTS:
;   ARG1 = File ID#
; OUTPUTS:
;   EAX = Memory pointer to base of name string.
;   -> 0 on error.
; Return a pointer to the alias/name of a file.
VFS_GET_FILE_NAME:
    FunctionSetup
    MultiPush ebx,edi
    ZERO eax
    mov edi, VFS_TABLE_BASE
    mov ebx, dword [ebp+8]  ; EBX = arg1 = file ID#
    and ebx, 0x000000FF     ; Force BL only

    push dword ebx  ; save EBX
    shl ebx, 5  ; quickly multiply by 32
    dec ebx ; subtract by 1 (to get the ID location rather than the start of next entry)
    add edi, ebx    ; EDI = VFS_TABLE_BASE + [(arg1*32)-1]
    pop dword ebx   ; restore

    cmp strict byte [edi], bl   ; compare the byte at EDI to the requested FileID.
    jne .leaveCall  ; if not equal, leave (EAX = 0)
    sub edi, 23     ; go back 23 spaces...
    mov eax, edi    ; ... and move the pointer into EAX
 .leaveCall:
    MultiPop edi,ebx
    FunctionLeave


; INPUTS: NONE
; OUTPUTS: NONE
; Enters the pre-built VFS_TABLE_ENTRY into memory in the appropriate place
; -- in the VFS_TABLE for file handles (0x2000-0x4000).
VFS_CREATE_FILE_ENTRY:
    MultiPush ecx,edi
    movzx ecx, strict byte [VFS_TABLE_CURRENT_ID]   ; get current FileID
    shl ecx, 5  ; multiply by 32
    mov edi, VFS_TABLE_BASE
    add edi, ecx    ; add offset to file handle/entry location.
    MEMCPY VFS_TABLE_ENTRY,edi,VFS_TABLE_ENTRY_LENGTH
 .leaveCall:
    call VFS_TABLE_CLEAR_ENTRY_BUFFER   ; Axe the leftover data.
    MultiPop edi,ecx
    ret
