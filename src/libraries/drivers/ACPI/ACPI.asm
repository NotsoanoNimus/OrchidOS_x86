; ACPI.asm
; -- Contains all ACPI interaction functions, for use after the ACPI driver environment has been set up,
; -- and the ACPI memory has been released to the system for use.
; ---- For system policies, such as thermal management, power profiles(policies),
; ---- and ISR service routines for the PIC, see "Policies/ACPI_POLICIES.asm"

%include "libraries/drivers/ACPI/setup/ACPI_SETUP.asm"
%include "libraries/drivers/ACPI/Policies/ACPI_POLICIES.asm"


; Override a current policy with a new one.
; The argument to this function will be a base ptr to an object that is the policy's definition.
ACPI_setPolicy:
    push ebp
    mov ebp, esp

 .leaveCall:
    pop ebp
    ret
