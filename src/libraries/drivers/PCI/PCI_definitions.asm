; PCI_definitions.asm
; -- Contains all definitions for the main PCI initialization file, to make everything more readable.

PCI_CONFIG_ADDRESS		equ 0xCF8
PCI_CONFIG_DATA			equ 0xCFC		; 32-bit register.
; 31		30-24		23-16		15-11		10-8		7-2			1-0
; Enable? | Reserved |  Bus No. |  Device No | Func No  |  Register No | Always 00
; Register Number = Offset into the 256-byte config space.
PCI_GET_HIGH_WORD		equ 0x00000002	; Flag to get higher WORD from 32-bit CONFIG_DATA output.
PCI_INFO_INDEX			 dd 0x00071000	; Pointer the the end of the PCI_INFO table @0x71000. Each entry is 20 bytes.
PCI_INFO_NUM_ENTRIES     db 0x00        ; Number of PCI devices found on the motherboard.
PCI_NEXT_BUS			 db 0x00		; Next bus to check in a multi-controller environment.

; Header Types.
PCI_STANDARD_HEADER		equ 0x00
PCI_TO_PCI_HEADER		equ 0x01
PCI_TO_CARDBUS_HEADER	equ 0x02
PCI_HEADER_MULT_FUNC	equ 0x80		; In the header-type byte, bit 7 tells whether or not the device has multiple functions.

; BIST definitions.
PCI_BIST_CAPABLE		equ 10000000b	; Check for device BIST capability.
PCI_BIST_ACTIVATE		equ 01000000b	; Setting bit 6 of the BIST section will activate the Built-in Self Test.
; BIST returns 000b in the bottom 3 bits if successful.

; Command Register flags.
PCI_COMMAND_INT_DISABLE equ 0x0400		; Cmd BIT 10 = disable interrupt assertions if set.
PCI_COMMAND_FAST_BTB_EN equ 0x0200		; Cmd BIT 09 = enable fast back-to-back transactions if set.
PCI_COMMAND_SERR_EN		equ 0x0100		; Cmd BIT 08 = SERR# driver enable if set.
PCI_COMMAND_PARITY_ERR	equ 0x0040		; Cmd BIT 06 = 1 -> Normal action on parity error // 0 -> Device sets bit 15 of STATUS but won't assert PERR# pin.
PCI_COMMAND_VGA_PALETTE equ 0x0020		; Cmd BIT 05 = 1 -> Device doesn't respond to palette register writes and will snoop // 0 -> Treat access like others.
PCI_COMMAND_MEM_WR_INV	equ 0x0010		; Cmd BIT 04 = 1 -> Device can gen mem write & invalidate cmd // 0 -> Memory Write cmd must be used.
PCI_COMMAND_SPEC_CYCLES equ 0x0008		; Cmd BIT 03 = 1 -> Device can monitor Special Cycle ops // 0 -> It ignores them.
PCI_COMMAND_BUS_MASTER	equ 0x0004		; Cmd BIT 02 = 1 -> Device can act as Bus Master // 0 -> Can not generate PCI accesses.
PCI_COMMAND_MEM_SPACE	equ 0x0002		; Cmd BIT 01 = 1 -> Device can respond to Memory Space accesses. // 0 -> Device response disabled.
PCI_COMMAND_IO_SPACE	equ 0x0001		; Cmd BIT 00 = 1 -> Device can respond to I/O Space accesses. // 0 -> Device response disabled.

; Status Register flags.
PCI_STATUS_PARITY_ERROR equ 0x8000		; Stt BIT 15 = Flagged if parity error, even if PERR handling disabled.
PCI_STATUS_SYSTEM_ERROR equ 0x4000		; Stt BIT 14 = Flagged if device asserts a SERR# (system error).
PCI_STATUS_MASTER_ABORT equ 0x2000		; Stt BIT 13 = Flagged by a master device when its transaction (ecx. Special) is terminated with Master-Abort.
PCI_STATUS_TARGET_ABORT equ 0x1000		; Stt BIT 12 = Same as above but with Target-Abort.
PCI_STATUS_SIGNAL_ABORT	equ 0x0800		; Stt BIT 11 = Set when target device terminates a transaction with Target-Abort.
PCI_STATUS_DEVSEL		equ 0x0400		; Stt BIT 10-9 = Read-only bits. Rep slowest time a device will assert DEVSEL#. 00b=FAST, 01b=MED, 10b=SLOW
PCI_STATUS_MASTER_PAR	equ 0x0100		; Stt BIT 08 = Set upon very specific PERR# condition. See wiki.osdev.org/PCI for more.
PCI_STATUS_FAST_BTB_STT	equ 0x0080		; Stt BIT 07 = If set, device can accept fast BTB transactions from diff agents. Otherwise, only accepted from same agent.
PCI_STATUS_66MHZ_POSS	equ 0x0020		; Stt BIT 05 = If set, 66MHz. If not, 33MHz.
PCI_STATUS_CAPABILITIES equ 0x0008		; Stt BIT 04 = If set, device supports ptr to New Capab Linked List at offs 0x34. Otherwise, not available.
PCI_STATUS_INTERRUPT	equ 0x0004		; Stt BIT 03 = If set, interrupts are asserted. Otherwise, not asserted.

; Applicable to both 00h and 01h.
PCI_BAR0				equ 0x10
PCI_BAR1				equ 0x14
PCI_CAPABILITIES_PTR	equ 0x34 	; Low byte only.
PCI_INTERRUPT_PIN		equ 0x3C	; high byte. 0x00 = no pin.
PCI_INTERRUPT_LINE		equ 0x3C	; low byte. 0xFF = no connection.

; Specific to header-type 00h.
PCI_BAR2				equ 0x18
PCI_BAR3				equ 0x1C
PCI_BAR4				equ 0x20
PCI_BAR5				equ 0x24
PCI_CARDBUS_CIS_PTR		equ 0x28
PCI_SUBSYS_ID			equ (0x2C|PCI_GET_HIGH_WORD)
PCI_SUBSYS_VENDOR_ID	equ 0x2C
PCI_EXPANSION_ROM_BASE	equ 0x30
PCI_MAX_LATENCY			equ (0x3C|PCI_GET_HIGH_WORD)	; high byte of WORD. READ-ONLY. How often in 1/4-microsecond the device accesses the bus.
PCI_MIN_GRANT			equ (0x3C|PCI_GET_HIGH_WORD)	; low byte of WORD. Burst period length needed (in 1/4us).

; Specific to header-type 01h (PCI-to-PCI).
PCI_SECONDARY_LATENCY	equ 0x18|PCI_GET_HIGH_WORD		; high byte of WORD.
PCI_SUBORDINATE_BUS		equ 0x18|PCI_GET_HIGH_WORD		; low byte.
PCI_SECONDARY_BUS		equ 0x18	; high byte
PCI_PRIMARY_BUS			equ 0x18	; low byte
PCI_SECONDARY_STATUS	equ 0x1C|PCI_GET_HIGH_WORD
PCI_IO_LIMIT			equ 0x1C	; high byte
PCI_IO_BASE				equ 0x1C	; low byte
PCI_MEMORY_LIMIT		equ 0x20|PCI_GET_HIGH_WORD
PCI_MEMORY_BASE			equ 0x20
PCI_PREFETCH_MEMLIMIT	equ 0x24|PCI_GET_HIGH_WORD
PCI_PREFETCH_MEMBASE	equ 0x24
PCI_PREFETCH_LIMIT_32	equ 0x28
PCI_PREFETCH_BASE_32	equ 0x2C
PCI_IO_LIMIT_UPPER_16	equ 0x30|PCI_GET_HIGH_WORD
PCI_IO_BASE_UPPER_16	equ 0x30
PCI_BRIDGE_ROM_BASE		equ 0x38
PCI_BRIDGE_CONTROL_WORD equ 0x3C|PCI_GET_HIGH_WORD

; No CardBus support for now.

; BAR# masks to get info for memory and I/O types.
PCI_BAR_TYPE_MEMORY		equ 0x00
PCI_BAR_MEM_GET_ADDR	equ 0xFFFFFFF0	; bits 31-4, 16-byte-aligned address.
PCI_BAR_MEM_PREFETCH_EN equ 0x00000008	; bit 3. Is it prefetchable.
PCI_BAR_MEM_TYPE		equ 0x00000006	; bits 2-1, Type. 00h = 32 wide. 0x02 = 64 wide. 0x01 = reserved (legacy)
PCI_BAR_TYPE_IO			equ 0x01
PCI_BAR_IO_GET_ADDR		equ 0xFFFFFFFC	; bits 31-2 = 4-byte-aligned base address.
