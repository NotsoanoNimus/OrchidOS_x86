; WINDOW.asm
; -- Contains functions for managing windows/displays with overlapping windows
; ---- and window interactions.

; WINDOW:
; .ID db 0x00
; .DEPTH db 0x00
; .FLAGS dw 0x0000 ;reserved for later use.
; .DIMENSIONS dd 0x00000000
; .WINDOW_COORDS dd 0x00000000

VIDEO_WINDOW_CURRENT_ID_INDEX   db 0x00


; INPUTS:
;   ARG1 = VIDEO_DIMENSIONS object
;   ARG2 = Starting coordinates (will be snapped to the GRID object)
;   ARG3 = Window process.
; OUTPUTS: carry on error.
; Create a window object and draw it to the display.
VIDEO_WINDOW_CREATE:
    FunctionSetup
    clc
    jmp .leaveCall
 .error: stc
 .leaveCall:
    FunctionLeave
