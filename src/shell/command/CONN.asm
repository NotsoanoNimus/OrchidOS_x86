; CONN.asm
; -- List enumerated PCI devices, from info in PCI_INFO (0x71000 to 0x72000).
szCONNErrArg1	db "ARG1 ERROR: Input value should be a hex value no greater than 0xFF & not 0.", 0
szCONNErrArg2	db "That device number does not exist. Check all devices with CONN and try again.", 0
szCONNDetail1	db "     SPECIFIC HARDWARE DEVICE CODES:", 0
szCONNDetail2	db "       Class: 0xNN"
szCONNDetail21	db "    Subclass: 0xNN"
szCONNDetail22	db "    Interface: 0xNN"
szCONNDetail2TermString db 0	; defined explicitly as a referenced label to edit szCONNDetail22 #s
szPCITmpIntro	db "0xXX PCI devices active on this computer:", 0
szPCITmp1		db "XX-> DeviceID: 0x0000"
szPCITmp2		db "     VendorID: 0x0000", 0
szPCITmp3		db "     Bus#: 0x00"
szPCITmp4		db "     Slot#: 0x00"
szPCITmpAddin1	db "     Function: 0x00", 0		;EOL2
szPCITmp5		db "     Description: "
szPCITmp6		times (80-16)-(0x0+($-szPCITmp5)) db 0x20
szPCITmp7		db " Revision: xx", 0			;EOL3
szPCITmp8		db "     STATUS register: 0x0000"
szPCITmp9		db "     COMMAND register: 0x0000", 0	;EOL4
szPCITmp10		db "     BIST: xxx  //  Header: 0x00  //  Latency: 0x00  //  Cache: 0x00", 0 	;EOL5
szPCITmpEnd		db 0

; -- Get connected devices from PCI_INFO. Display the DeviceID, VendorID, and a brief description based on a small included dictionary.
COMMAND_CONN:
	pushad
	xor ebx, ebx
	xor eax, eax

	mov edi, PARSER_ARG1
	cmp strict byte [edi], 0x00
	jne .specificDevice
	push dword 0x00000000
	call CONN_listDevices
	add esp, 4
	jmp .leaveCall
 .specificDevice:
 	;check the argument for validity.
	; Equates to if(!isNaN(x) && String(x).length <= 8 && (x > 0 && x < 0xFF) && deviceExists(x)) {listDevice(x);} else {err1();}
	mov byte bl, [PARSER_ARG1_LENGTH]
	cmp bl, 8
	ja .err1
	mov esi, PARSER_ARG1
	call UTILITY_HEX_STRINGtoINT	;EAX = value
	jc .err1	;CF on error
	or eax, eax
	jz .err1
	cmp eax, 0x100
	jae .err1
	cmp al, strict byte [PCI_INFO_NUM_ENTRIES]
	ja .err2
	; ready to go! Call the lookup function with arg dev# (0 is reserved for 'all')
	push dword eax
	call CONN_listDevices
	add esp, 4
	jmp .leaveCall

 .err1:
 	PrintString szCONNErrArg1,0x0C
	jmp .leaveCall
 .err2:
 	PrintString szCONNErrArg2,0x0C
 .leaveCall:
 	popad
	ret


CONN_listDevices:
	push ebp
	mov ebp, esp
	xor ecx, ecx
	xor eax, eax
	xor edx, edx
	xor ebx, ebx	; EBX is only used in single-device requests to hold CLASS,SUBCLASS,INTERFACE vals

	mov edi, PCI_INFO	; set EDI to base of PCI_INFO table.
	mov dword edx, [ebp+8]	;EDX = device id to get details of
	or edx, edx
	jz .listAll		; if EDX == 0, list all devices.
	mov al, dl
	mov cl, dl
	sub cl, 1		; set loop counter to DEVICE_INDEX-1
	or cl, cl
	jz .EDI_Remain	; If the first device is selected, don't move EDI
	.placeEDItoDevice:
		add edi, 20	; Iterate up to the DEVICE_INDEX (remember: each entry in PCI_INFO = 20 bytes)
		loop .placeEDItoDevice
	.EDI_Remain:
	xor ecx, ecx		; set counter to 0 and jmp
	jmp .getInfoSingleDevice

 .listAll:
	mov byte al, [PCI_INFO_NUM_ENTRIES]	; ECX = num_PCI_entries
	mov cl, 1
	mov edi, PCI_INFO			; EDI = 71000h, base of PCI_INFO area.

	; Enter intro string's device total count, display it, and jmp to display iteration.
	mov esi, szPCITmpIntro+4
	call UTILITY_BYTE_HEXtoASCII
	PrintString szPCITmpIntro,0x0A
	jmp .getInfo

 .getInfoSingleDevice:	;only for single-device requests
	; set device_index number in display
	mov esi, szPCITmp1+2
	call UTILITY_BYTE_HEXtoASCII
	; (NOT NECESSARY) Clean detailed info-specific string buffers here before JMPing...
	jmp .beginDisplaySingleDevice

	; [edi]    = Physical location on MB
	; [edi+4]  = DeviceID | VendorID
	; [edi+8]  = Stt | Cmd areas
	; [edi+12] = Class | Subclass | ProgIF | Revision
	; [edi+16] = BIST | Header-Type | Latency Timer | Cache Line Size
 .getInfo:
	; set device_index number in display
	mov esi, szPCITmp1+2
	mov al, cl
	call UTILITY_BYTE_HEXtoASCII
 .beginDisplaySingleDevice:		; used only as a label for single-device requests.

	; Quickly reset Description field to all spaces.
	mov esi, szPCITmp6
   .cleanupDesc:
	mov byte [esi], 0x20
	inc esi
	cmp esi, szPCITmp7
	je .exitCleaning
	jmp .cleanupDesc
   .exitCleaning:

	mov esi, szPCITmp2		; End of buffer for szPCITmp1
	mov dword eax, [edi+4]	; EAX = DeviceID | VendorID
	push eax
	shr eax, 16
	call UTILITY_WORD_HEXtoASCII	; write VendorID into buffer
	pop eax
	mov esi, szPCITmp3-1
	call UTILITY_WORD_HEXtoASCII	; write DeviceID into buffer

	mov esi, szPCITmpAddin1
	mov dword eax, [edi]			; Get PCI bus device location
	push eax
	shr eax, 16
	call UTILITY_BYTE_HEXtoASCII
	shr eax, 8
	mov esi, szPCITmp4
	call UTILITY_BYTE_HEXtoASCII
	pop eax
	shr eax, 8
	mov esi, szPCITmp5-1
	call UTILITY_BYTE_HEXtoASCII

	push edi
	mov dword eax, [edi+12]		; Get the device type
	mov edi, szPCITmp6		; Get in position to write in the spaces.
	call CONN_INTERNAL_dictionaryLookup
	pop edi

	mov esi, szPCITmp8-1
	call UTILITY_BYTE_HEXtoASCII	;EAX = [edi+12] still here. Last byte is revision. Write it out.

	PrintString szPCITmp1,0x0B
	PrintString szPCITmp3,0x0E
	PrintString szPCITmp5,0x05
 .skip:
 	add edi, 20		; next entry
	inc cl			; increment counter
	cmp cl, 1		;if cl = 1 (specific-device requests), show detailed information
	je .singleDeviceMoreInfo
	push dword eax
	mov byte al, [PCI_INFO_NUM_ENTRIES]
	inc al
	cmp byte cl, al		;if cl = num_entries(+1) on listall requests, leave
	pop dword eax
	je .breakLoop
	call SCREEN_Pause	; pause the screen before the next device is listed.
	jmp .getInfo

 .singleDeviceMoreInfo:	; here is where a verbose information sheet regarding EVERY PCI variable is output.
 	sub edi, 20	; cancel 'next entry' operation above (@label 'skip')
 	mov dword eax, [edi+12]	;EAX = CLASS|SUBCLASS|INTERFACE|REVISION
	shr eax, 8	; shift out REVISION, unimportant & unnecessary
	mov esi, szCONNDetail2TermString
	call UTILITY_BYTE_HEXtoASCII
	shr eax, 8	; AL = SUBCLASS
	mov esi, szCONNDetail22
	call UTILITY_BYTE_HEXtoASCII
	shr eax, 8	; AL = CLASS
	mov esi, szCONNDetail21
	call UTILITY_BYTE_HEXtoASCII

	mov esi, szPCITmp9
	mov dword eax, [edi+8]		; EAX = Status/Command register infos
	push eax
	shr eax, 16
	call UTILITY_WORD_HEXtoASCII
	pop eax
	mov esi, szPCITmp10-1
	call UTILITY_WORD_HEXtoASCII

	mov dword eax, [edi+16]
	mov esi, szPCITmp10+11		; BIST: xxx spot
	push eax
	and eax, 0x80000000
	cmp dword eax, 0x80000000
	je .yesBIST
	mov dword [esi], "No  "
	jmp .skipYesBIST
  .yesBIST:
	mov dword [esi], "Yes "
  .skipYesBIST:
	pop eax
	mov esi, szPCITmpEnd-1
	call UTILITY_BYTE_HEXtoASCII
	shr eax, 8
	mov esi, szPCITmpEnd-18
	call UTILITY_BYTE_HEXtoASCII
	shr eax, 8
	mov esi, szPCITmpEnd-37
	call UTILITY_BYTE_HEXtoASCII

	PrintString szPCITmp8,0x04
	PrintString szPCITmp10,0x02
	PrintString szCONNDetail1,0x03
	PrintString szCONNDetail2
 .breakLoop:
 	pop ebp
	ret


; INPUTS: (non-stack)
; 	EAX = DWORD of Classcode (31-24) | Subclass (23-16) | ProgIF (15-08) | Revision (07-00)
;  	EDI = Start of output buffer. Transfer directly to it.
; -- Translates CC,SC,ProgIF into string that most accurately describes a device. For now only include MOST COMMON/IMPORTANT DEVICES.
CONN_INTERNAL_dictionaryLookup:
	push eax
	push esi
	push edi
	; Revision will be unimportant. Shift it out. Now do direct cmps to CC->SC->PIF to get devices.
	shr eax, 8

	; Speed up parsing by getting CC and jumping to appropriate section...
	push eax
	shr eax, 16		;AL = ClassCode
	cmp byte al, 0x00
	je .CC0x00
	cmp byte al, 0x01
	je .CC0x01
	cmp byte al, 0x02
	je .CC0x02
	cmp byte al, 0x03
	je .CC0x03
	cmp byte al, 0x04
	je .CC0x04
	cmp byte al, 0x05
	je .CC0x05
	cmp byte al, 0x06
	je .CC0x06
	cmp byte al, 0x07
	je .CC0x07
	cmp byte al, 0x08
	je .CC0x08
	cmp byte al, 0x09
	je .CC0x09
	cmp byte al, 0x0C
	je .CC0x0C

	;If no proper CC is here, automatically label device unknown...
	mov esi, szCONNDevNotFound		; Not Found!
	jmp .leaveCall

 .CC0x00:
	pop eax
	mov esi, szCONNGenericUnnamed
	cmp dword eax, 0x00000000		;CC0, SC0, PIF0 - Generic/Unnamed Device, not VGA-Compatible.
	je .leaveCall
	mov esi, szCONNGenericVGA
	cmp dword eax, 0x00000100		;CC0, SC1, PIF0 - Generic VGA-Compatible Device
	je .leaveCall
	mov esi, szCONNDevNotFound		; Not Found!
	jmp .leaveCall

 .CC0x01:
	pop eax
	mov esi, szCONNSCSIBusCont
	cmp dword eax, 0x00010000		;CC1, SC0, PIF0 - SCSI Bus Controller.
	je .leaveCall
	;Need to ignore PIF here...
	push eax
	shr eax, 8
	mov esi, szCONNIDEController
	cmp dword eax, 0x00000101		;CC1, SC1, PIF[any] - IDE Controller.
	pop eax
	je .leaveCall
	;...
	mov esi, szCONNFloppyCont
	cmp dword eax, 0x00010200		;CC1, SC2, PIF0 - Floppy Disk Controller.
	je .leaveCall
	mov esi, szCONNIPIBusCont
	cmp dword eax, 0x00010300		;CC1, SC3, PIF0 - IPI Bus Controller.
	je .leaveCall
	mov esi, szCONNRAIDCont
	cmp dword eax, 0x00010400		;CC1, SC4, PIF0 - RAID Controller.
	je .leaveCall
	mov esi, szCONNATASCont
	cmp dword eax, 0x00010520		;CC1, SC5, PIF20 - ATA Controller: Single DMA.
	je .leaveCall
	mov esi, szCONNATACCont
	cmp dword eax, 0x00010530		;CC1, SC5, PIF30 - ATA Controller: Chained DMA.
	je .leaveCall
	mov esi, szCONNSATAVSICont
	cmp dword eax, 0x00010600		;CC1, SC6, PIF0 - Serial ATA Controller (Vendor-Specific).
	je .leaveCall
	mov esi, szCONNSATAHCICont
	cmp dword eax, 0x00010601		;CC1, SC6, PIF1 - Serial ATA Controller (AHCI 1.0).
	je .leaveCall
	mov esi, szCONNSASCSI
	cmp dword eax, 0x00010700		;CC1, SC7, PIF0 - Serial Attached SCSI (SAS).
	je .leaveCall
	mov esi, szCONNOtherMassMedia
	cmp dword eax, 0x00018000		;CC1, SC80, PIF0 - Other Mass Media Controller.
	je .leaveCall
	mov esi, szCONNDevNotFound		; Not Found!
	jmp .leaveCall

 .CC0x02:
	pop eax
	mov esi, szCONNEthernetCont
	cmp dword eax, 0x00020000		;CC2, SC0, PIF0 - Ethernet Controller.
	je .leaveCall
	mov esi, szCONNDevNotFound		; Not Found!
	jmp .leaveCall

 .CC0x03:
	pop eax
	mov esi, szCONNVGAController
	cmp dword eax, 0x00030000		;CC3, SC0, PIF0 - VGA-Compatible Display Controller.
	je .leaveCall
	mov esi, szCONN8512Cont
	cmp dword eax, 0x00030001		;CC3, SC0, PIF1 - 8512 Controller.
	je .leaveCall
	mov esi, szCONNXGACont
	cmp dword eax, 0x00030100		;CC3, SC1, PIF0 - XGA Controller.
	je .leaveCall
	mov esi, szCONN3DCont
	cmp dword eax, 0x00030200		;CC3, SC2, PIF0 - 3D Controller.
	je .leaveCall
	mov esi, szCONNOtherDisplay
	cmp dword eax, 0x00038000		;CC3, SC80, PIF0 - Other display Controller.
	je .leaveCall
	mov esi, szCONNDevNotFound		; Not Found!
	jmp .leaveCall

 .CC0x04:
	pop eax
	mov esi, szCONNVideoDev
	cmp dword eax, 0x00040000		;CC4, SC0, PIF0 - Video Controller.
	je .leaveCall
	mov esi, szCONNAudioDev
	cmp dword eax, 0x00040100		;CC4, SC1, PIF0 - Audio Controller.
	je .leaveCall
	mov esi, szCONNCompTelephony
	cmp dword eax, 0x00040200		;CC4, SC2, PIF0 - Telephony Controller.
	je .leaveCall
	mov esi, szCONNVideoDev
	cmp dword eax, 0x00048000		;CC4, SC80, PIF0 - Other MM Controller.
	je .leaveCall
	mov esi, szCONNDevNotFound		; Not Found!
	jmp .leaveCall

 .CC0x05:
	pop eax
	mov esi, szCONNRAMCont
	cmp dword eax, 0x00050000		;CC5, SC0, PIF0 - RAM Controller.
	je .leaveCall
	mov esi, szCONNFlashCont
	cmp dword eax, 0x00050100		;CC5, SC1, PIF0 - Flash Controller.
	je .leaveCall
	mov esi, szCONNOtherMemCont
	cmp dword eax, 0x00058000		;CC5, SC80, PIF0 - Other Memory Controller.
	je .leaveCall
	mov esi, szCONNDevNotFound		; Not Found!
	jmp .leaveCall

 .CC0x06:
	pop eax
	mov esi, szCONNHostBridge
	cmp dword eax, 0x00060000		;CC6, SC0, PIF0 - PCI Host Bridge.
	je .leaveCall
	mov esi, szCONNISABridge
	cmp dword eax, 0x00060100		;CC6, SC1, PIF0 - PCI-to-ISA Bridge.
	je .leaveCall
	mov esi, szCONNEISABridge
	cmp dword eax, 0x00060200		;CC6, SC2, PIF0 - EISA bridge
	je .leaveCall
	mov esi, szCONNMCABridge
	cmp dword eax, 0x00060300		;CC6, SC3, PIF0 - MCA Bridge
	je .leaveCall
	; Any PIF here... Checking for all types of PCI-to-PCI.
	push eax
	shr eax, 8
	mov esi, szCONNPCIBridge
	cmp dword eax, 0x00000604		;CC6, SC4, PIF[any] - PCI-to-PCI
	pop eax
	je .leaveCall
	push eax
	shr eax, 8
	mov esi, szCONNPCIBridge
	cmp dword eax, 0x00000609		;CC6, SC9, PIF[any] - PCI-to-PCI (Semi-transparent)
	pop eax
	je .leaveCall
	;...
	mov esi, szCONNPCMCIABridge
	cmp dword eax, 0x00060500		;CC6, SC5, PIF0 - PCMCIA
	je .leaveCall
	mov esi, szCONNNuBus
	cmp dword eax, 0x00060600		;CC6, SC6, PIF0 - NuBus Bridge
	je .leaveCall
	mov esi, szCONNCardBus
	cmp dword eax, 0x00060700		;CC6, SC7, PIF0 - CardBus
	je .leaveCall
	; Any PIF ...
	push eax
	shr eax, 8
	mov esi, szCONNRaceway
	cmp dword eax, 0x00000608		;CC6, SC8, PIF[any] - RACEWAY Bridge
	pop eax
	je .leaveCall
	;...
	mov esi, szCONNInfiniBrand
	cmp dword eax, 0x00060A00		;CC6, SCA, PIF0 - InfiniBrand-to-PCI
	je .leaveCall
	mov esi, szCONNOtherBridge
	cmp dword eax, 0x00068000		;CC6, SC80, PIF0 - Other Bridge Device
	je .leaveCall
	mov esi, szCONNDevNotFound		; Not Found!
	jmp .leaveCall

 .CC0x07:
	pop eax
	mov esi, szCONNSerialPort
	; fill with types later.
	jmp .leaveCall

 .CC0x08:
   	pop eax
  	mov esi, szCONNTimerPICORAPIC
  	; fill with types later.
  	jmp .leaveCall


 .CC0x09:
	pop eax
	mov esi, szCONNKeyboardCont
	cmp dword eax, 0x00090000		;CC9, SC0, PIF0 - Keyboard Controller
	je .leaveCall
	mov esi, szCONNDigitizer
	cmp dword eax, 0x00090100		;CC9, SC1, PIF0 - Digitizer
	je .leaveCall
	mov esi, szCONNMouseCont
	cmp dword eax, 0x00090200		;CC9, SC2, PIF0 - Mouse Controller
	je .leaveCall
	mov esi, szCONNScannerCont
	cmp dword eax, 0x00090300		;CC9, SC3, PIF0 - Scanner Controller
	je .leaveCall
	mov esi, szCONNOtherInputCont
	cmp dword eax, 0x00098000		;CC9, SC80, PIF0 - Other Input Cont
	je .leaveCall
	mov esi, szCONNDevNotFound		; Not Found!
	jmp .leaveCall

 .CC0x0C:
	pop eax
	mov esi, szCONNUSBUniversal
	cmp dword eax, 0x000C0300		;CC[C], SC3, PIF0 - usb univ spec
	je .leaveCall
	mov esi, szCONNUSBOpen
	cmp dword eax, 0x000C0310		;CC[C], SC3, PIF10 - usb open spec
	je .leaveCall
	mov esi, szCONNUSB2Host
	cmp dword eax, 0x000C0320		;CC[C], SC3, PIF20 - usb2
	je .leaveCall
	mov esi, szCONNUSB3XHCI
	cmp dword eax, 0x000C0330		;CC[C], SC3, PIF30 - usb3
	je .leaveCall
	mov esi, szCONNUSBUnspec
	cmp dword eax, 0x000C0380		;CC[C], SC3, PIF80 - usb unspecified
	je .leaveCall
	mov esi, szCONNUSBNotHost
	cmp dword eax, 0x000C03FE		;CC[C], SC3, PIF[FE] - Usb non-host
	je .leaveCall
	mov esi, szCONNDevNotFound		; Not Found!
	jmp .leaveCall


 .leaveCall:
	movsb
	cmp byte [esi], 0
	je .trueExit
	jmp .leaveCall
 .trueExit:
 	mov byte [edi], ","
	pop edi
	pop esi
	pop eax
	ret

szCONNDevNotFound		db "Unknown device: could not match classes", 0
szCONNGenericUnnamed	db "Generic/Unnamed Device, not VGA-Compatible", 0
szCONNGenericVGA		db "Generic VGA-Compatible Device", 0
szCONNSCSIBusCont		db "SCSI Bus Controller", 0
szCONNIDEController		db "IDE Controller", 0
szCONNFloppyCont		db "Floppy Disk Controller", 0
szCONNIPIBusCont		db "IPI Bus Controller", 0
szCONNRAIDCont			db "RAID Controller", 0
szCONNATASCont			db "ATA Controller: Single DMA", 0
szCONNATACCont			db "ATA Controller: Chained DMA", 0
szCONNSATAHCICont		db "Serial ATA Controller (AHCI 1.0)", 0
szCONNSATAVSICont		db "Serial ATA Controller (Vendor-Specific)", 0
szCONNSASCSI			db "Serial Attached SCSI (SAS)", 0
szCONNOtherMassMedia	db "Other mass-storage media controller", 0
szCONNEthernetCont		db "Ethernet Controller", 0
szCONNVGAController		db "VGA-Compatible Display Controller", 0
szCONN8512Cont			db "8512-Compatible Display Controller", 0
szCONNXGACont			db "XGA-Compatible Display Controller", 0
szCONN3DCont			db "3D Display Controller (not VGA-Compatible)", 0
szCONNOtherDisplay		db "Other/Generic Display Controller", 0
szCONNVideoDev			db "Video Multimedia Device", 0
szCONNAudioDev			db "Audio Multimedia Device", 0
szCONNCompTelephony		db "Computer Telephony Device", 0
szCONNOtherMultimedia	db "Other Multimedia Device Controller", 0
szCONNRAMCont			db "RAM Controller", 0
szCONNFlashCont			db "Flash Controller", 0
szCONNOtherMemCont		db "Other Memory Controller", 0
szCONNHostBridge		db "PCI Host Bridge", 0
szCONNISABridge			db "PCI-to-ISA Bridge", 0
szCONNEISABridge		db "PCI-to-EISA Bridge", 0
szCONNMCABridge			db "PCI-to-MCA Bridge", 0
szCONNPCIBridge			db "PCI-to-PCI Bridge", 0
szCONNPCMCIABridge		db "PCI-to-PCMCIA Bridge", 0
szCONNNuBus				db "PCI-to-NuBus Bridge", 0
szCONNCardBus			db "PCI-to-CardBus Bridge", 0
szCONNRaceway			db "RACEWAY Bridge", 0
szCONNInfiniBrand		db "InfiniBrand-to-PCI Host Bridge", 0
szCONNOtherBridge		db "Other Bridge Device", 0
szCONNKeyboardCont		db "Keyboard Controller", 0
szCONNMouseCont			db "Mouse Controller", 0
szCONNDigitizer			db "Digitizer", 0
szCONNScannerCont		db "Scanner Controller", 0
szCONNOtherInputCont	db "Other Input Controller", 0
szCONNUSBUniversal		db "USB Universal Host Controller Specification", 0
szCONNUSBOpen			db "USB Open Host Controller Specification", 0
szCONNUSB2Host			db "USB2 Host Controller (Intel-Enhanced HCI)", 0
szCONNUSB3XHCI			db "USB3 XHCI Controller", 0
szCONNUSBUnspec			db "Unspecified USB Controller", 0
szCONNUSBNotHost		db "USB (not Host Controller)", 0

szCONNSerialPort		db "Simple Comms Controller (type unknown)", 0

szCONNTimerPICORAPIC	db "Timer, PIC, or APIC Chip", 0
