; ACPI_POLICIES.asm
; -- Contains 'global' variables AND FUNCTIONS for all ACPI profiles/policies in the driver.
; -- ALL ACPI power management policies will use this file's definitions, whether in a shared context or static context.

;%include policy1-x

ACPI_CURRENT_POLICY     db 0x00     ; ID of current policy on the system.
ACPI_POLICY_LOW_POWER   db 0x01     ; Low power profile, quiet with no cooling.
ACPI_POLICY_HIGH_POWER  db 0x02     ; High power, high cooling.

; Override a current policy with a new one.
; The argument to this function will be a base ptr to an object that is the policy's definition.
ACPI_setPolicy:
    push ebp
    mov ebp, esp

 .leaveCall:
    pop ebp
    ret
