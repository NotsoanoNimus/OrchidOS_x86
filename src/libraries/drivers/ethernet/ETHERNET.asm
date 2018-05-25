; ETHERNET.asm
; -- Used to initialize the Ethernet adapter and to perform ethernet operations,
; ---- such as rx/tx. OSI Layer 1 functions.

%include "libraries/drivers/ethernet/setup/ETHERNET_definitions.asm"
%include "libraries/drivers/ethernet/setup/ETHERNET_SETUP.asm"

ETHERNET_initialize:
    call ETHERNET_SETUP_begin
 .leaveCall:
    ret



; INPUTS:
;   ARG1 = Base ptr to packet data.
;   ARG2 = Length of packet.
; OUTPUTS: CF on error.
; -- Called as a meta-function to send a packet of information.
ETHERNET_SEND_PACKET:
    clc
    FunctionSetup
    pushad

    mov eax, dword [ETHERNET_DRIVER_SPECIFIC_SEND_FUNC] ; testing the send func for 0 (not set)
    or eax, eax
    jz .error

    ; Check for 0 length.
    cmp dword [ebp+12], 0x00000000
    je .error

    MEMCPY [ebp+8],[ETHERNET_PACKET_SEND_BUFFER_BASE],[ebp+12]  ; copy from base of data, to send buffer, len of arg.

    mov esi, dword [ebp+8]  ; ESI = ptr to packet base
    mov ecx, dword [ebp+12] ; ECX = Length
    func(eax,esi,ecx)   ; call the driver-specific packet TX function w/ args

    jmp .leaveCall

 .error:
    stc
 .leaveCall:
    popad
    FunctionLeave
