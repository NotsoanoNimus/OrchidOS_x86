; PCI.asm
; -- Enumerate the PCI Bus and check connected devices.
; ---- MAX PCI variables: 256 Buses, 32 Devices/Bus, 8 Functions/Device.

PCI_CONFIG_ADDRESS		equ 0xCF8
PCI_CONFIG_DATA			equ 0xCFC		; 32-bit register.
; 31		30-24		23-16		15-11		10-8		7-2			1-0
; Enable? | Reserved |  Bus No. |  Device No | Func No  |  Register No | Always 00
; Register Number = Offset into the 256-byte config space.
PCI_GET_HIGH_WORD		equ 0x00000002	; Flag to get higher WORD from 32-bit CONFIG_DATA output.

PCI_STANDARD_HEADER		equ 0x00
PCI_TO_PCI_HEADER		equ 0x01
PCI_TO_CARDBUS_HEADER	equ 0x02
PCI_HEADER_MULT_FUNC	equ 0x80		; In the header-type byte, bit 7 tells whether or not the device has multiple functions.

PCI_BIST_CAPABLE		equ 10000000b	; Check for device BIST capability.
PCI_BIST_ACTIVATE		equ 01000000b	; Setting bit 6 of the BIST section will activate the Built-in Self Test.
; BIST returns 000b in the bottom 3 bits if successful.

PCI_COMMAND_INT_DISABLE equ 0x0400		; Cmd BIT 10 = disable interrupt assertions if set.
PCI_COMMAND_FAST_BTB_EN equ 0x0200		; Cmd BIT 09 = enable fast back-to-back transactions if set.
PCI_COMMAND_SERR_EN		equ 0x0100		; Cmd BIT 08 = SERR# driver enable if set.
PCI_COMMAND_PARITY_ERR	equ 0x0040		; Cmd BIT 06 = 1 -> Normal action on parity error // 0 -> Device sets bit 15 of STATUS but won't assert PERR# pin.
PCI_COMMAND_VGA_PALETTE equ 0x0020		; Cmd BIT 05 = 1 -> Device doesn't respond to palette register writes and will snoop // 0 -> Treat access like others.
PCI_COMMAND_MEM_WR_INV	equ 0x0010		; Cmd BIT 04 = 1 -> Device can gen mem write & invalidate cmd // 0 -> Memory Write cmd must be used.
PCI_COMMAND_SPEC_CYCLES equ 0x0008		; Cmd BIT 03 = 1 -> Device can monitor Special Cycle ops // 0 -> It ignores them.
PCI_COMMAND_BUS_MASTER	equ 0x0004		; Cmd BIT 02 = 1 -> Device can act as Bus Master // 0 -> Can not generate PCI accesses.
PCI_COMMAND_MEM_SPACE	equ 0x0002		; Cmd BIT 01 = 1 -> Device can respond to Memory Space accesses. // 0 -> Device response disabled.
PCI_COMMAND_IO_SPACE	equ 0x0001		; Cmd BIT 00 = 1 -> Device can respond to I/O Space accesses. // 0 -> Device response disabled.

PCI_STATUS_PARITY_ERROR equ 0x8000		; Stt BIT 15 = Flagged if parity error, even if PERR handling disabled.
PCI_STATUS_SYSTEM_ERROR equ 0x4000		; Stt BIT 14 = Flagged if device asserts a SERR# (system error).
PCI_STATUS_MASTER_ABORT equ 0x2000		; Stt BIT 13 = Flagged by a master device when its transaction (ecx. Special) is terminated with Master-Abort.
PCI_STATUS_TARGET_ABORT equ 0x1000		; Stt BIT 12 = Same as above but with Target-Abort.
PCI_STATUS_SIGNAL_ABORT	equ 0x0800		; Stt BIT 11 = Set when target device terminates a transaction with Target-Abort.
PCI_STATUS_DEVSEL		equ 0x0400		; Stt BIT 10-9 = Read-only bits. Rep slowest time a device will assert DEVSEL#. 00b=FAST, 01b=MED, 10b=SLOW
PCI_STATUS_MASTER_PAR	equ 0x0100		; Stt BIT 08 = Set upon very specific PERR# condition. See wiki.osdev.org/PCI for more.
PCI_STATUS_FAST_BTB_STT	equ 0x0080		; Stt BIT 07 = If set, device can accept fast BTB transactions from diff agents. Otherwise, only accepted from same agent.
PCI_STATUS_66MHZ_POSS	equ 0x0020		; Stt BIT 05 = If set, 66MHz. If not, 33MHz.
PCI_STATUS_CAPABILITIES equ 0x0008		; Stt BIT 04 = If set, device supports ptr to New Capab Linked List at offs 0x34. Otherwise, not available.
PCI_STATUS_INTERRUPT	equ 0x0004		; Stt BIT 03 = If set, interrupts are asserted. Otherwise, not asserted.

PCI_INFO_INDEX			 dd 0x00071000	; Pointer the the end of the PCI_INFO table @0x71000. Each entry is 20 bytes.
PCI_NEXT_BUS			 db 0x00		; Next bus to check in a multi-controller environment.


; -- Capture all devices and functions using a recursive method of scanning.
; ---- Scans 256 buses, 32 devices each. Each entry found is put into memory from PCI_INFO
PCI_getDevicesInfo:
	push edi
	call PCI_checkAllBuses
	mov dword edi, [PCI_INFO_INDEX]
	mov dword [edi], 0xFFFFFFFF		; end of block signature.
	add edi, 4
	mov dword [PCI_INFO_INDEX], edi	; Set end ptr to true end to measure full size.

	;Might not even be worth calling...
	;call PCI_INTERNAL_destroyDuplicates

	pop edi
	ret

; This function may remain unused, since the checkBus function has become so efficient.
PCI_INTERNAL_destroyDuplicates:
	pushad

	mov edi, PCI_INFO
	mov esi, edi
	add esi, 20
 .scanForDupes:
	cmp dword [esi], 0xFFFFFFFF		; Is the next entry the end signature?
	je .leaveCall					;  If so, leave.
	cmpsd							; EDI = ESI?
	je .dupeFound
	add edi, 16
	add esi, 16						; Increment both to the next Bus/Dev/Func ptr
	jmp .scanForDupes

 .dupeFound:
	push edi
	push esi
	;call _commandDUMP
	;jmp $
  .repFix:
	movsd
	cmp dword [esi], 0xFFFFFFFF		; Is the src the end signature?
	je .cleaningAfter
	jmp .repFix

 .cleaningAfter:	; avoids endless loops
	;add esi, 16
	;add edi, 16
	pop esi
	pop edi
	mov dword [edi], 0xFFFFFFFF
	jmp .scanForDupes

 .leaveCall:
	popad
	ret


; INPUTS:
;	BL = Bus Number
;	BH = Device Number (slot)
;	CL = Function Number
;	CH = Register Number (LOWEST 2 BITS = offset --> If offset=2, use high word.)
; 	*Args are pushed as a whole DWORD, with CH (rno) being at the least significant side
; OUTPUTS:
;	AX = WORD read from CONFIG_DATA
; -- Reads from the configuration port on the PCI bus. A return WORD of FFFFh means the device does not exist.
PCI_configReadWord:
	push ebx
	push ecx
	push edx
	push ebp
	mov ebp, esp

	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx

	mov dword edx, [ebp+20]		;edx = pushed arg
	push edx
	mov ch, dl					; CH = Register Number
	shr edx, 8
	mov cl, dl					; CL = Function Number
	shr edx, 8
	mov bh, dl					; BH = Device Number
	shr edx, 8
	mov bl, dl					; BL = Bus Number

	and ch, 0xFC				; ensure the last 2 bits of the lowest byte in CONFIG_DATA are 00b
	and cl, 0x07				; ensure the function is only for bits 10-8 (00000111b)
	shl bh, 3					; shift the device number value up by 3 to make room to OR with CL
	or bh, cl					; Combine to make bits 15-8 of CONFIG_DATA

	mov al, 0x80				; bits 31-24 (10000000b)
	shl eax, 8
	mov al, bl					; bits 23-16 (Bus Number)
	shl eax, 8
	mov al, bh 					; bits 15-8 (Device Number | Function Number)
	shl eax, 8
	mov al, ch					; bits 7-0	(Register Number & 11111100b)

	; EAX now = address to send to PCI_CONFIG_DATA
	mov dx, PCI_CONFIG_ADDRESS
	out dx, eax

	xor eax, eax
	mov dx, PCI_CONFIG_DATA
	in eax, dx		; read config space addy

	xor ecx, ecx
	pop edx			; restore original arg
	and edx, 0x000000FF	; save only dl
	mov cl, dl
	and cl, 0x02	; AND register value by 00000010b (using the bits that aren't actually the register value, but are extra 00).
	; If DL was 2, the shift will be by 16, otherwise no shift is performed. So if the register offset arg has 10b at the end,
	;  it will shift the high WORD of the 32-bit section retrieved in CONFIG_DATA into the lower WORD (basically into AX)
	shl cl, 3		; DL * 8
	shr eax, cl		; Either going to be EAX >> 16 or >> 0
	and eax, 0x0000FFFF		; get low word.

	pop ebp
	pop edx
	pop ecx
	pop ebx
	ret


; INPUTS:
;	EDX = Configuration input (Bus|Device|Function|Offset)
; OUTPUTS:
;	AL = type.
; -- Puts header type byte into AL. If bit 7 is set, the device has MULTIPLE FUNCTIONS.
PCI_getHeaderType:
	push edx
	push ebp
	mov ebp, esp

	mov dword edx, [ebp+12]		;arg1
	mov dl, (0x0E)				; change offset into config block. We're getting the higher WORD from offset 0x0C. 0x0E = (0x0C|PCI_GET_HIGH_WORD)

	push dword edx
	call PCI_configReadWord		; AX = WORD from 0x0C. High byte is BIST, low is Header Type.
	add esp, 4

	pop ebp
	pop edx
	ret


; INPUTS:
;	EBX = 0x0000----, with BH = Bus# & BL = Device#
; OUTPUTS:
; 	AH
; -- Checks an entire device, tells whether or not it's multi-function, and enumerates each function if so.
; ---- CF set if no VendorID is found.
PCI_checkDevice:
	pushad
	push ebp
	mov ebp, esp

	mov dword ebx, [ebp+40]		;arg1
	and ebx, 0x0000FFFF			; Force only BX.

	mov al, bh			; Bits 31-24 = Bus#
	shl eax, 8
	mov al, bl			; Bits 23-16 = Device#
	shl eax, 8
	xor al, al			; Bits 15-08 = Function# (0 to start) --> AH
	shl eax, 8
	xor al, al			; Bits 07-00 = Offset (0 for now to get VendorID; later, this is going to turn into header info) --> AL

	; Check for a valid VendorID.
	push dword eax
	call PCI_configReadWord
	cmp word ax, 0xFFFF	; 0xFFFF = No VendorID
	pop dword eax
	je .error

	; THIS HEADER TEST IS TO SEE IF WE'RE DEALING WITH A PCI-TO-PCI BRIDGE.
	; Get Header Type in AL. BIST in AH.
	push dword eax
	call PCI_getHeaderType		; set AL = header byte
	and al, 0x7F				; 01111111b mask. Keeps multi test out.
	cmp al, 0x01				; Is the header type a PCItoPCI?
	pop dword eax				; restore before a possible call to check for secondaryBus variables.
	jne .notBridge
	call PCI_checkPCItoPCI
 .notBridge:
	; THIS HEADER TEST IS FOR MULTI-FUNCTION DEVICES.
	; Get Header Type in AL. BIST in AH.
	push dword eax
	call PCI_getHeaderType		; set AL = header byte
	; Test header for multiple functions before restoring EAX.
	and al, PCI_HEADER_MULT_FUNC
	cmp byte al, PCI_HEADER_MULT_FUNC
	pop dword eax
	je .multipleFunctions

	;This section for single-function devices.
	xor ax, ax			; reset offset and function #s
	push dword eax
	call PCI_checkFunction
	add esp, 4
	jmp .leaveCall

 .multipleFunctions:	; This section for devices with multiple functions.
	xor ecx, ecx
	mov cl, 8			; max of 8 functions per device.
	xor ax, ax			; reset offset and function #s
 .nextFunc:
	push dword eax
	call PCI_checkFunction
	add esp, 4

	inc ah				; check next function availability.
	push dword eax
	call PCI_configReadWord
	cmp ax, 0xFFFF		; is the vendorID for this function invalid?
	pop dword eax
	jne .nextFunc		; if not, continue.

	jmp .leaveCall

 .error:	; this field is ONLY for the first test of the device's vendorID, not for subseq tests of function #s.
	pop ebp
	popad
	stc
	ret

 .leaveCall:
	pop ebp
	popad
	clc
	ret


; INPUTS:
;	EAX = (Bus|Device|Function|Offset).
; NO OUTPUTS.
; -- Check individual functions from PCI_checkDevice. Store all shared sections of config info (first 0x10 bytes) into the PCI_INFO +the arg1 to ID which dev.
PCI_checkFunction:
	pushad
	push ebp
	mov ebp, esp

	mov dword eax, [ebp+40]		;arg1
	xor al, al

	xor ecx, ecx
	mov cl, 4
	mov dword edi, [PCI_INFO_INDEX]
	mov dword [edi], eax
	add edi, 4
 .getInfo:
	or al, PCI_GET_HIGH_WORD	; Get high word. OR guarantees it is set.
	push dword eax
	call PCI_configReadWord
	mov word [edi+2], ax
	pop dword eax
	xor al, PCI_GET_HIGH_WORD	; Toggle it back off. Getting low DWORD now.
	push dword eax
	call PCI_configReadWord
	mov word [edi], ax
	pop dword eax
	add edi, 4					; Next DWORD.
	add al, 0x04				; Next Offset.
	loop .getInfo				; executed 3 more times.

	mov dword [PCI_INFO_INDEX], edi

	pop ebp
	popad
	ret


; -- Check all buses. Inspect hosts and determine how many controllers there are. Follow buses thereafter.
PCI_checkAllBuses:
	pushad
;	push dword 0x00000000	; Bus0 | Dev0 | Func0 | Offset[doesn't-matter]
;	call PCI_getHeaderType	; AL = header-type
;	add esp, 4

;	and al, PCI_HEADER_MULT_FUNC
;	cmp byte al, PCI_HEADER_MULT_FUNC
;	je .multipleHosts

	;This section for single-host controller. USE THIS FOR NOW.
	push dword 0x00000000	; Bus0
	call PCI_checkBus
	add esp, 4
	jmp .leaveCall

 .multipleHosts:		; Multiple Host section.
	push dword 0x00000000
	call PCI_checkBus		; Checking Bus0 first.
	add esp, 4

	xor edx, edx	; Bus0, Dev0, Func(0+DH), Offset0(Vendor)
	xor eax, eax
	xor ecx, ecx
	mov cl, 8
  .checkNextBus:
	push dword edx
	call PCI_configReadWord
	pop dword edx
	cmp word ax, 0xFFFF
	je .breakNextBus
	inc dh		; Checking function by function now. But this is done separately to see how many buses there are.
	loop .checkNextBus

  .breakNextBus:	; at this point DH = Bus count. 0 controls 0, 1 controls 1, ..., n controls n (up to bus 7)
	xor ecx, ecx
	mov cl, dh
	dec cl			; VV - starting at Bus1
	xor edx, edx
	inc dl			; start at Bus1
 .parseNextBus:
;	cmp byte [PCI_NEXT_BUS], 0x00	; Are we waiting on a PCI-to-PCI secondary to parse?
;	je .noBridge
;	push edx
;	xor edx, edx
;	mov byte dl, [PCI_NEXT_BUS]
;	mov byte [PCI_NEXT_BUS], 0x00	; reset in case this coming bus check also has a bridge in it.
;	push dword edx
;	call PCI_checkBus	; check the secondary bus now.
;	add esp, 4
;	pop edx
;	jmp .parseNextBus	; go check again.
;  .noBridge:
	push dword edx
	call PCI_checkBus
	add esp, 4
	inc dl
	loop .parseNextBus
	jmp .leaveCall

 .leaveCall:
	popad
	ret


; INPUTS:
;	EAX = Bus to check. Value is in AL.
; NO OUTPUTS.
; -- Check a specific bus' devices.
PCI_checkBus:
	push edx
	push ecx
	push ebx
	push ebp
	mov ebp, esp

	xor ecx, ecx	; device counter
	xor edx, edx	; Bus number to check
	mov dword edx, [ebp+20]	; DL = Bus#
	and edx, 0x000000FF
	shl edx, 8		; DH = DL
	xor dl, dl		; guarantee a start on Dev0

	mov cl, 32
	xor bl, bl
 .getDeviceInfo:
	push dword edx
	call PCI_checkDevice
	pop dword edx

	inc bl
	mov dl, bl		; combine DH & BL into DX
	loop .getDeviceInfo
	; bleed

 .leaveCall:
	pop ebp
	pop ebx
	pop ecx
	pop edx
	ret


; INPUTS: (not stack-based)
;	EAX = (Bus|Device|Function|Offset). Func & Offset are always 0x00.
; -- Check if the current device is a PCI-to-PCI Bridge. If so, find the bus it points to and put it in the PCI_NEXT_BUS slot to check.
PCI_checkPCItoPCI:
	push eax
	call PCI_get2ndPrimBuses
	;mov byte [PCI_NEXT_BUS], ah
	shr eax, 8		; AL = Bus to check.
	push dword eax
	call PCI_checkBus
	add esp, 4
	pop eax
	ret


; INPUTS: (not stack-based)
; 	EAX = (Bus|Device|Function|Offset).
; OUTPUTS:
; 	EAX = 0x0000----. AH = Secondary Bus# // AL = Primary Bus#
; -- Reads configs with header-type 01h only to get Secondary and Primary buses for PCI-to-PCI.
PCI_get2ndPrimBuses:
	mov al, 0x18	;replace offset by 0x18, low WORD, so the return gives us bus info.
	push dword eax
	call PCI_configReadWord
	add esp, 4
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PCI EDIT VALS FUNCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; INPUTS:
;	ARG1: EDX = (Bus|Device|Func|Offset). Offset is important, signals the section of the config area we're changing.
; NO OUTPUTS.
PCI_changeValue:
	pushad
	push ebp
	mov ebp, esp

	mov dword edx, [ebp+40]		;arg1


	pop ebp
	popad
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; IDE BUS AREA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PCI_initializeIDEController:	; this is used only if the system detects an IDE controller.

	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
