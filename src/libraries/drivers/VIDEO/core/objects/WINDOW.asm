; WINDOW.asm
; -- Contains functions for managing windows/displays with overlapping windows
; ---- and window interactions.

; WINDOW:   ;24 bytes in length --> total of 16 windows = 384 bytes
; .ID db 0x00
; .DEPTH db 0x00
; .FLAGS db 0x00
    ;Bit7 set when the window ID is in use
; .PID: db 0x00  ;PROCESS ID.
; .DIMENSIONS dd 0x00000000
; .WINDOW_COORDS dd 0x00000000

VIDEO_WINDOW_CURRENT_FOCUS_ID db 0x00

; arg = amount of windows to create (reserve space)
%macro VIDEO_INIT_CREATE_WINDOWS 1
    %define init_create_windows_internal 0
    %rep %1
        InitializeWindow init_create_windows_internal
        %assign init_create_windows_internal init_create_windows_internal+1
    %endrep
    %undef init_create_windows_internal
%endmacro
%macro InitializeWindow 1
    .WINDOW%1:
        db %1
        times 3 db 0x00
        times 2 dd 0x00000000
%endmacro
WINDOWS: VIDEO_INIT_CREATE_WINDOWS 16


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
