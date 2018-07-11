; TASKMAN.asm
; -- Global functions and include directory for the STEM task manager.
; -- The task manager is the critical task delegation arm of Orchid.
; ---- It controls process states, weighting, and memory allocation through the kernel libraries.
; ---- It consistently monitors ONLY system process conditions to make sure that vital processes are alive.

%include "stem/task/TASKMAN_definitions.asm"    ; Include the header file with TASKMAN definitions.

TASKMAN_INIT:
