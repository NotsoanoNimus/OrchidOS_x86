; VFS.asm
; -- Primary header file for Virtualized File System functions and operations.
; ---- This file goes hand-in-hand with memops in how it uses those functions to manipulate the VFS in RAM.

%include "libraries/drivers/vfs/setup/VFS_definitions.asm"
%include "libraries/drivers/vfs/setup/VFS_SETUP.asm"

; Called by the INIT.asm file during system initialization.
VFS_initialize:

 .leaveCall:
    ret
