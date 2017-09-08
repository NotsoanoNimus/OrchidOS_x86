; CMDDIR.asm:
;		Holds the include files for all valid shell commands and functions.
;		Serves as a directory for the parse tree to search for commands to execute.

%include "shell/command/CLS.asm"
%include "shell/command/HELP.asm"
%include "shell/command/DUMP.asm"
%include "shell/command/SYS.asm"
%include "shell/command/USR.asm"
%include "shell/command/MEMD.asm"
%include "shell/command/START.asm"
%include "shell/command/CONN.asm"
%include "shell/command/COLOR.asm"
%include "shell/command/REBOOT.asm"
