; HELP.asm
; -- Print out a list of orchid commands.

COMMAND_HELP:
	pushad
	PrintString szHelp1,0x03
	PrintString szHelp2
	PrintString szHelpAddin2
	PrintString szHelpAddin3
	PrintString szHelp3
	PrintString szHelpAddin1
	PrintString szHelp4
	PrintString szHelp5
	PrintString szHelp6
	PrintString szHelpAddin4
	PrintString szHelpAddin5
	PrintString szHelp7
	PrintString szHelp8
	PrintString szHelp9
	PrintString szHelp10
	PrintString szHelp11

	;call _screenPause		; keep for screen pauses once the help list exceed a certain length.

	popad
	ret

szHelp1			db "List of Orchid console commands:", 0
szHelp2			db "      CLS - Clear the console screen.", 0
szHelpAddin2	db "    COLOR - Change the color of the user input text.", 0
szHelpAddin3	db "            (%1 = 8-bit hexadecimal color code)", 0
szHelp3			db "     CONN - Show a technical list of devices connected to the PCI Bus.", 0
szHelpAddin1	db "            ([%1] = Get more information about a specific device number)", 0
szHelp4			db "     DUMP - Dump the current states of the primary registers.", 0
szHelp5			db "     MEMD - Arranged 16-byte-aligned hex dump of memory.", 0
szHelp6			db "            (%1 = Memory Location | %2 = Length of memdump (Max 0x100)).", 0
szHelpAddin4	db "   REBOOT - Reboot the system. Calling it once will prompt for surety.", 0
szHelpAddin5	db " SHUTDOWN - Power off the system. Just like reboot, will ask for surety.", 0
szHelp7			db "    START - Starts an ELF binary application within the kernel Heap.", 0
szHelp8			db "            ([%1] = Quoted File Name and Directory).", 0
szHelp9			db "      SYS - Information about Orchid and the system status.", 0
szHelp10		db "      USB - Displays and configures USB ports/devices on the system.", 0
szHelp11		db "            ([%1]) = DRIVE_ID // ([%2]) = COMMAND (see docs, more later)", 0
