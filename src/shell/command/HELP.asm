; HELP.asm
; -- Print out a list of orchid commands.

_commandHELP:
	pushad

	mov bl, 0x03
	mov esi, szHelp1
	call _screenWrite
	mov esi, szHelp2
	call _screenWrite
	mov esi, szHelpAddin2
	call _screenWrite
	mov esi, szHelpAddin3
	call _screenWrite
	mov esi, szHelp3
	call _screenWrite
	mov esi, szHelpAddin1
	call _screenWrite
	mov esi, szHelp4
	call _screenWrite
	mov esi, szHelp5
	call _screenWrite
	mov esi, szHelp6
	call _screenWrite
	mov esi, szHelp7
	call _screenWrite
	mov esi, szHelp8
	call _screenWrite
	mov esi, szHelp9
	call _screenWrite

	;call _screenPause		; keep for screen pauses once the help list exceed a certain length.

	popad
	ret

szHelp1			db "List of orchid console commands:", 0
szHelp2			db "   CLS - Clear the console screen.", 0
szHelpAddin2	db " COLOR - Change the color of the user input text.", 0
szHelpAddin3	db "         (%1 = 8-bit hexadecimal color code)", 0
szHelp3			db "  CONN - Show a technical list of devices connected to the PCI Bus.", 0
szHelpAddin1	db "         ([%1] = Get more information about a specific device number)", 0
szHelp4			db "  DUMP - Dump the current states of the primary registers.", 0
szHelp5			db "  MEMD - Arranged 16-byte-aligned hex dump of memory.", 0
szHelp6			db "         (%1 = Memory Location | %2 = Length of memdump (Max 0x100)).", 0
szHelp7			db " START - Starts an ELF binary application within the kernel Heap.", 0
szHelp8			db "         ([%1] = Quoted File Name and Directory).", 0
szHelp9			db "   SYS - Information about Orchid and the system status.", 0
