; USB.asm
; -- Implements support for UHCI, OHCI, and EHCI. USB3 (XHCI) is not necessary for x86.
; ---- most mass storage controllers use EHCI, which is the imost important thing to implement right now.

; KNOWN ISSUES:
; -- If there's a USB controller on Bus0, Dev0, Func0 (HIGHLY UNLIKELY),
;     the driver won't interpret ANY USB ports.

%include "libraries/drivers/USB/UHCI/UHCI.asm"
;%include "libraries/drivers/USB/OHCI/OHCI.asm"
;%include "libraries/drivers/USB/EHCI/EHCI.asm"


USB_initializeDriver:
    pushad

    call USB_DRIVER_setupUHCI

    popad
    ret





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;DELEGATED FUNCTIONS: Work is delegated here from the main initialization, so as to keep it clean.

USB_DRIVER_setupUHCI:
    ; Find all PCI bus devices with the matching UHCI config: 0x0C, 0x03, 0x00, 0xNN.
    ; Matching devices that come through have the config:
    ;  DEVICE[n] = (Bus<<24|Device<<16|Function<<8|Offset/00h) <-- Offset is always 00h here.
    call USB_INTERNAL_findMatchingUHCI

    ; Now use the matches to iterate through each UHCI device/function's BAR4 in the config space.
    call USB_INTERNAL_iterateUHCIBARs

    ; UHCI is all set, clean the buffers to prepare for OHCI...
    call PCI_INTERNAL_cleanMatchedBuffers

    ret
