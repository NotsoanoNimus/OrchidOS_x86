# TODOs for Orchid
This document includes many different TODO features to add, as well as bugs and patches, that need to be made to the system, listed by their respective components/categories. These changes are all tentative and are deleted as the patches/hotfixes are committed to Github.

---

# General Bugs
The bugs listed in this category will be formally registered as Github "Issues", so they will be visible there and trackable as I work on the bug.
- There is a _persistent_ bug that keeps the UTILITY functions (writing hex in memory to an ASCII string) from outputting an actual result on the screen. This typically happens in the booting process whenever the COMMAND_DUMP call is issued. This is a priority because COMMAND_DUMP is very useful for quick debugging. A good example of this bug is a BSOD during the booting process. No error code is issued (_besides **0x**, which is NOT useful_).
- Due to the longer (small-but-noticeable) start time between timer initialization and actual timer value updates, the OS tends to be about a second behind. This is because in the main SHELL_MODE loop, the timer is readied with the RTC values before loading everything else, and updates to the timer are not given until the system starts up completely. This can't be fixed by moving timer initialization (my first thought) because there are some early functions that strictly depend on an initialized timer for the global SLEEP function.
- Need to fix the month date display to interpret a BSD-formatted integer, rather than HEX. Will be quick, but have been putting it off.

---

# IDT (Interrupt Descriptor Table)
- The IDT needs a rework for dynamic INT lines that PCI devices may have. This might be able to happen with both a `DYNAMIC_ISR` macro as well as a table of ISR functions, with a global indexing label from which call addresses can be calculated/stored. For example:
    ```
    ;;;;;;;;;;;;;;;;;;;;;;;
    ; IDT.asm
    ;;;;;;;;;;;;;;;;;;;;;;;
    IDT_DYNAMIC_ISR:
    ISR_IRQ_32 dd 0x00000000
    ISR_IRQ_33 dd 0x00000000
    ...
    ISR_IRQ_47 dd 0x00000000

    ;;;;;;;;;;;;;;;;;;;;;;;
    ; [GENERIC_DEVICE].asm
    ;;;;;;;;;;;;;;;;;;;;;;;
    device_driver_irq db 0x00
    func(PCI_READ_CONFIG,([device_pci_address & 0xFFFFFF00]|0x3C))
    and eax, 0xFF
    mov byte [device_driver_irq], al
    mov edi, IDT_DYNAMIC_ISR
    mov cl, 4
    mul cl
    add edi, eax
    mov eax, dword [device_specific_isr_function_ptr]
    mov dword [edi], eax
    ```

---

# PCI (Device Management)
This whole section needs a desperate rework, as it was written sometime around version 0.2.

## Device Info & IRQ Management
IRQ mgmt only recently became a concern due to the implementation of the Ethernet Controller IRQ, but is going to be a crucial part of device management in the future.
- Rework the **CONN** function to absorb more information. This involves a very thorough and fundamental change to the PCI_INFO array, which could break everything. Considering just adding a different PCI_INFO array elsewhere with all the extra info in it. _Unsure_.

---

# Memory Management

## The Heap
- Better safety, security, and error-catching that actually affects the system with proper notifications about allocation and heap information.

---

# SHELL_MODE
There are so many words about how inefficient and rickety the Orchid SHELL_MODE is, but at the moment it is crucial because it allows for (1) actual system usage, and (2) debugging as needed. There is nothing more to it, and SHELL_MODE may very well always be a core part of the Orchid kernel.

## Video/Screen/UI Internal Functionality
- Consider the idea of _streams_ and writing to them as psuedo-objects. For example, instead of the keyboard IRQ directly calling a 'printChar' function, it could instead just send the signal about the character to the _OUTSTREAM_ object buffer.

---

# GUI_MODE
Not enough about this mode yet to really talk about smaller TODOs. Coming eventually.

---

# BLOOM

## User-Instantiated Process Management
The problem with managing a "user space" is that anyone who uses Orchid is compiling it themselves (or is using someone else's compilation). This opens the question as to whether or not security should be a question due to the open-source nature of the kernel, because anyone who views the source and compiles it can just make changes to the `core` part of Orchid when they compile it. I think this is a challenge that the developers of the Linux core kernel also ran into.

As a counter point, some developers may never be interested in writing anything to the kernel, and just want to run a system with useful, optional scripts. Perhaps a weak security feature could be implemented, but the idea of the Orchid kernel is to allow full control to confident and expert users, not necessarily your average Joe.

This section is written with respect to applications that users have written onto the kernel and is absolutely **subject to complete change or removal** based on the decision made about the above text.
- Write to a process' memory through an easy system interruption. This will help with security implementations later.
  + **SYSTEM_PROCESS_GET_PTR(PID, offsetIntoProcessRAM)** : Gets the pointer in RAM of where the process can request a write.
  + **SYSTEM_PROCESS_WRITE_DATA(PID, processAccessPtr, infoBasePtr, lengthOfInfo)** : Verbose name/args.

---
