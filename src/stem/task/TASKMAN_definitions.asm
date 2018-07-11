; TASKMAN_definitions.asm
; -- Task Manager definitions for process management and task delegation/control.

; ===========================
;   PROCESS INFO COLLECTION
; ===========================
; When trying to obtain the specific information from a Process' flags DWORD,
; -- the taskman will logically & with one or more of these values (OR'd together) to get the info.
TASK_SECTION_STATE      equ 0x0000000F
TASK_SECTION_STATE_CODE equ 0x00000FF0
TASK_SECTION_PRIORITY   equ 0x0000F000
TASK_SECTION_DESC_CODE  equ 0x00FF0000
TASK_SECTION_DESC       equ 0x0F000000
TASK_SECTION_PERMISSION equ 0xF0000000

; ==================
;   PROCESS STATES
; ==================
TASK_STATE_DAEMON       equ 0x00000001  ; process is an active daemon and has a daemon function address.
; ^ A FALSE for this value indicates that the process is in an initialization state.
; -- If the task mgr gets a SIGNAL_INITIALIZED from the process and it is NOT a daemon, it will be put into DYING and eventually die.
TASK_STATE_SLEEPING     equ 0x00000002  ; process is suspended/idle and is not running a daemon.
; ^ This is always set for tasks with no daemons.
TASK_STATE_DYING        equ 0x00000004  ; process crashed and needs to run the "noRecovery" function.
; ^ If the process is dying, the DAEMON & SLEEPING statuses do not matter.
; ---- The TASKMAN will attempt to run the process' noRecovery function and will then clean it up regardless
; ---- of that function's exit code.
TASK_STATE_DEAD         equ 0x00000008  ; process is dead and is pending removal from the global PROCESS table.

; =======================
;   PROCESS DESCRIPTORS
; =======================
; ** One 'Task' is one iteration of a process' "daemon" loop.
; Interruption permissions.
TASK_DESC_CRITICAL      equ 0x80000000 ; System Critical process; cannot be killed w/o a reboot.
TASK_DESC_INTERRUPT     equ 0x40000000 ; Process can be safely interrupted mid-task for higher-priority tasks.
TASK_DESC_RESURRECT     equ 0x20000000 ; Process can be killed and resurrected without performing exit cleanup.

; Interruption reasons.
TASK_DESC_DEATH_NOTIF   equ 0x08000000 ; Task was interrupted because it crashed or was forcibly killed.
TASK_DESC_SUSPENDED     equ 0x04000000 ; Task was interrupted because it is being suspended or put to sleep.
TASK_DESC_ZOMBIE        equ 0x02000000 ; Task interrupted permanently but can be restarted when requested.
TASK_DESC_HANGED        equ 0x01000000 ; Task interrupted normally, at the end of the daemon loop.
; ^ A FALSE in the HANGED field indicates the task was interrupted mid-daemon.

; ======================
;   PROCESS PRIORITIES
; ======================
TASK_PRIORITY_REALTIME  equ 0x00008000
TASK_PRIORITY_HIGH      equ 0x00004000
TASK_PRIORITY_NORMAL    equ 0x00002000
TASK_PRIORITY_LOW       equ 0x00001000



; ===================
;   PROCESS SIGNALS
; ===================
; --- STATE codes ---
SIGNAL_INITIALIZED      equ 00000001b
SIGNAL_SLEEP            equ 00000010b


; --- DESC codes ---
SIGNAL_INTERRUPT        equ 10000000b
