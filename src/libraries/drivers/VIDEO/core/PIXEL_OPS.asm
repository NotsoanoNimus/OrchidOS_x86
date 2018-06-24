; PIXEL_OPS.asm
; -- Part of the CORE video driver interface/API, this handles the lowest-level functions
; ---- revolving around pixel operations in the majority of higher-level video operations,
; ---- and is an essential component of the video driver.

; TODO: Move PIXEL_OPS functions here and rename/rework them for efficiency.


; INPUTS:
;	1: EBX = (x | y<<16) location
;	2: LFB address !OFFSET!.
;	3: Pixel color.
; NO OUTPUTS. CF if error.
; -- Same as putPixel, but the LFB OFFSET is already calculated.
VIDEO_putPixel_noCalc:
	FunctionSetup
	pushad
	popad
	FunctionLeave


; INPUTS:
;	1: EBX, 0-15 = xpos // 16-31 = ypos
;	2: EAX = color.
; NO OUTPUTS. CF if OOB or failure otherwise.
; -- Paints a pixel the given color.
VIDEO_putPixel:
	FunctionSetup
    pushad

	mov dword ebx, [ebp+8]	; arg1 (Y,X)

	push word bx	; XPOS
	shr ebx, 16
	push word bx	; YPOS
	call VIDEO_selectPixel		; EAX = pixel's linear address.
	add esp, 4

	mov dword edi, [SCREEN_FRAMEBUFFER_ADDR]		; Should change to buffer 2? Probably not for the simple put operation.
	add edi, eax

	mov dword eax, [ebp+12]	; arg2 (Color)
	mov dword [edi], eax

	popad
    FunctionLeave


; INPUTS:
;	1: YPOS word
;	2: XPOS word
; OUTPUTS:
;	EAX = Offset from LFB_BASE, linear address of pixel.
; +- Calculates a pixel's linear address based on an X,Y input.
; `---> FORMULA: pixelOffset (from LFB_BASE) = y*pitch + (x*(bpp/8))
VIDEO_selectPixel:
    FunctionSetup
    MultiPush ebx,ecx,edx

    ; Zero primary registers (clear EDX for 32-bit MUL instructions).
	ZERO eax,ebx,ecx,edx

	mov word ax, [ebp + 8]		; EAX = xpos
	mov word bx, [ebp + 10]		; EBX = ypos

	mov word cx, [SCREEN_PITCH]
	mul ecx			; EAX = (Y * PITCH)
	push eax		; save

	ZERO ecx,eax
	mov byte cl, [BYTES_PER_PIXEL]
	mov ax, bx		; EAX = X
	mul ecx			;  * (BPP/8)

	mov ebx, eax	; EBX = [X*(BPP/8)]
	pop eax			; restore EAX (Y*PITCH)
	add eax, ebx	; add them. EAX = (Y*PITCH) + [X*(BPP/8)].

    MultiPop edx,ecx,ebx
    FunctionLeave
