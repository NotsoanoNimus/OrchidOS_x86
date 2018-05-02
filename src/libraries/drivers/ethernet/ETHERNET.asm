; ETHERNET.asm
; -- Used to initialize the Ethernet adapter and to perform ethernet operations,
; ---- such as rx/tx. OSI Layer 1 functions.

%include "libraries/drivers/ethernet/setup/ETHERNET_definitions.asm"
%include "libraries/drivers/ethernet/setup/ETHERNET_SETUP.asm"

ETHERNET_initialize:
    call ETHERNET_SETUP_begin
 .leaveCall:
    ret
