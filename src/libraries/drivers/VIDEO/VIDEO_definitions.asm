; VIDEO_definitions.asm
; -- Contains global video driver definitions for the GUI_MODE video mode to utilize when drawing/interacting.

VGA_INFORMATION			equ 0x800		; Store the VGA/VIDEO info starting at 0x800, for 0x400 bytes (to 0xc00).
VESA_CURRENT_MODE_INFO 	equ 0xC00		; Store VESA info from 0xC00 to 0xE00.
VESA_DESIRED_MODE		equ 0x0118		; Tentative mode. Will change later to be more flexible than supporting only one standard.
SCREEN_PITCH			equ VESA_CURRENT_MODE_INFO+0x10		;how many bytes per line. (WORD)
SCREEN_WIDTH			equ VESA_CURRENT_MODE_INFO+0x12		; WORD
SCREEN_HEIGHT			equ VESA_CURRENT_MODE_INFO+0x14		; WORD
SCREEN_BPP				equ VESA_CURRENT_MODE_INFO+0x19		; BYTE
SCREEN_FRAMEBUFFER_ADDR	equ VESA_CURRENT_MODE_INFO+0x28		; DWORD
SCREEN_OFFSCREEN_MEMORY equ VESA_CURRENT_MODE_INFO+0x30		; Amount of memory outside the framebuffer, off-screen (extra mem). (WORD)
;SCREEN_BACKBUFFER		equ 0x100000						; Second buffer for LFB is going to be allocated at 0x100000 (1MiB into phys mem).
; This will not happen because the SystemWindowManager process will control the management of GUI layers.
BYTES_PER_PIXEL			db 0x00
SCREEN_FRAMEBUFFER		dd 0x00000000
SCREEN_LFB_SIZE_KB		dw 0x0000
SCREEN_PIXEL_COUNT		dd 0x00000000


VIDEO_TENTATIVE_WIDTH   equ 0x400
VIDEO_TENTATIVE_HEIGHT  equ 0x300
; The argument for this macro is basically the "Granularity" of the video grid, defining how many entries there are.
; This will be subject to change when dynamic video resolution is introduced.
%macro DEFINE_VIDEO_GRID 1
    %define i 0
    %define j 0
    %define grid_height_units (VIDEO_TENTATIVE_HEIGHT/%1)
    %define grid_width_units (VIDEO_TENTATIVE_WIDTH/%1)
    %rep %1
        %rep %1
            %assign grid_coords_label VIDEO_GRID_COORDS_i_j
            grid_coords_label equ ((grid_height_units*i)<<16|(grid_width_units*j))
            %assign j j+1
        %endrep
        %assign i i+1
    %endrep
%endmacro


; The video grid, aside from being a critical GUI component, is useful because it has a flexible granularity.
;  When writing to the LFB, the coords go through this file first and the coords are modulo'd by the grid granularity/step.
;  The result of the modulo is an index into the below tables that gives the correct coordinates to 'snap' to.
; For example, coordinates of 0x203,0x049 would 'snap' up and to the left on the STARTING COORDINATE ONLY.
;  The ending coordinate shrinks only by the distance the first coord had to move (remainder), so the object does not change shape.
VIDEO_GRID_COORDS_STEP_X equ 8
VIDEO_GRID_COORDS_STEP_Y equ 6
;ALIGN 4
;VIDEO_GRID_COORDS:
;    DEFINE_VIDEO_GRID 128 ;128 grid spaces on the display. 8x6
