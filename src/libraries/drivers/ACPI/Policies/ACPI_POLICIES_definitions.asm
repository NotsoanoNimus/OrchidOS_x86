; ACPI_POLICIES_definitions.asm
; -- Defines misc. variables and standards used by the ACPI_POLICIES.asm file to implement
; -- system power management profiles accordingly.

ACPI_CURRENT_POLICY     db 0x00     ; ID of current policy on the system.
; The below policies are standard defaults used on first setup.
; Orchid will maintain the number afterwards, and not need to fetch it on every boot.
;  Eventually, power state configuration will need to be a saved state on the hard-drive. This will
;  require a filesystem and the ability to parse file data/handles.
ACPI_POLICY_LOW_POWER   db 0x01     ; Low power profile, quiet with no cooling. Used on laptops and battery-based systems.
ACPI_POLICY_HIGH_POWER  db 0x02     ; High power, high cooling. Used on all other machines.
