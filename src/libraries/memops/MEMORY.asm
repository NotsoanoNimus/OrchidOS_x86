; MEMORY.asm
; -- Wrapper file to contain all memops functions in a single file.

%include "libraries/memops/OPS.asm"	; General memory operations.
%include "libraries/memops/DATA_OPS.asm" ; Data manipulation functions.
%include "libraries/memops/MMIO.asm" ; MMIO functions.
%include "libraries/memops/PORT_OPS.asm" ; Port I/O & manipulation functions.

%include "libraries/memops/heap/HEAP.asm" ; Heap setup and heap-specific functions.
%include "libraries/memops/process/PROCESS.asm" ; Process-related functions.
