; USB.asm
; -- Implements support for UHCI, OHCI, and EHCI. USB3 (XHCI) is not necessary for x86.
; ---- most mass storage controllers use EHCI, which is the imost important thing to implement right now.

; KNOWN ISSUES:
; -- If there's a USB controller on Bus0, Dev0, Func0 (HIGHLY UNLIKELY),
;     the UHCI driver won't interpret ANY USB ports.

USB_CONNECTED_DEVICE_COUNT      db 0x00


%include "libraries/drivers/USB/UHCI/UHCI.asm"
;%include "libraries/drivers/USB/OHCI/OHCI.asm"  ; OHCI = untested physically. Unsure if functional.
%include "libraries/drivers/USB/EHCI/EHCI.asm"


USB_initializeDriver:
    pushad

    ; Get the supported USB PCI information and perform some initial setup.
    ;call USB_DRIVER_setupOHCI
    call USB_DRIVER_setupUHCI
    call USB_DRIVER_setupEHCI

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

    ; UHCI is all set, clean the buffers to prepare for EHCI...
    call PCI_INTERNAL_cleanMatchedBuffers

    ret


USB_DRIVER_setupEHCI:
    ; Find all PCI bus devices with the matching EHCI config: 0x0C, 0x03, 0x20, 0xNN.
    ; Matching devices come through with the same PCI address config as UHCI above.
    call USB_INTERNAL_findMatchingEHCI

    ; Get information about the EHCI ports/devices and their base I/O addrs.
    call USB_INTERNAL_iterateEHCIBARs

    ;EHCI is ready, clean the internal PCI buffers.
    call PCI_INTERNAL_cleanMatchedBuffers

    ret
