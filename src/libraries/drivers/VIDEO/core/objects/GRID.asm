; GRID.asm
; -- Contains files for manipulating the snap-grid involved in GUI_MODE.
; -- This file is crucuial for video components and windows and provides a uniform interface for all windowing operations.


; INPUTS:
;   ARG1 = VIDEO_COORDS 'object' to snap and verify.
; OUTPUTS:
;   EAX = The LFB address of the pixel.
;   EDX = (delta) Values subtracted on X,Y coords in order to snap (for primitives to use when repositioning their drawing)
; Take a VIDEO_COORDS input, snap it to the 'grid' object, and return the linear address of the pixel.
VIDEO_GRID_SNAP_AND_TRANSLATE:
    FunctionSetup
    MultiPush ebx,ecx
    ZERO eax,ebx,ecx,edx
    clc
    mov ebx, dword [ebp+8]  ; EBX = arg1

    ; X-coordinate snapping...
    push ebx    ; save coords
    and ebx, 0x0000FFFF ; Keep only the X coord
    mov ax, bx  ; AX = X-coord
    mov ecx, VIDEO_GRID_COORDS_STEP_X   ; modulo X by the step, then remultiply, to 'snap'
    div cx ; DX:AX / CX ---> DX = remainder, AX = quotient
    push edx ; save the x-adj-offset (X mod GRID_STEP)
    xor ebx, ebx
    mov bx, VIDEO_GRID_COORDS_STEP_X ; BX = step
    mul bx  ; BX * AX --> DX = high WORD, AX = low WORD (only one needed)
    pop edx ; restore the x-adj-offset
    pop ebx ; restore the original coordinates

    push eax    ; save new X (in AX)
    
    ; Y-coordinate snapping...
    push edx    ; save delta
    and ebx, 0xFFFF0000
    shr ebx, 16 ;BX = Y coord
    mov ax, bx
    mov ecx, VIDEO_GRID_COORDS_STEP_Y   ; modulo Y by the step, remul, and snap
    ZERO ebx,edx
    div cx  ; DX:AX / CX ---> DX = delta, AX = quotient
    mov ecx, edx    ; ECX = y-delta
    mov bx, VIDEO_GRID_COORDS_STEP_Y    ; BX = step
    mul bx  ; BX * AX --> DX = high WORD, AX = low WORD (only one needed)
    pop edx     ; restore X-delta

    ; Put the delta in the appropriate format...
    shl edx, 16
    mov dx, cx
    rol edx, 16

    ; Piece the new coords together.
    mov ecx, eax
    pop eax
    shl eax, 16
    mov ax, cx
    rol eax, 16

    jmp .leaveCall
 .error: stc
 .leaveCall:
    MultiPop ecx,ebx
    FunctionLeave
