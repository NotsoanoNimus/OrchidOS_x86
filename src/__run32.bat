@ECHO OFF
TITLE Run Orchid OS (x86 platform)
COLOR 4E
CLS

:: Run the Orchid image on the emulator using the last build.

ECHO ==============================
ECHO Starting OrchidOS with QEMU...
ECHO ==============================
:: Emulate an i386 system with 128MB of RAM.
qemu-system-i386 -m 128M -device isa-debug-exit,iobase=0xF4,iosize=0x04 -drive format=raw,index=0,file="..\bin\image.img"
