@ECHO OFF
TITLE Run Orchid OS (x86 platform)
COLOR 4E
CLS

:: Run the Orchid image on the emulator using the last build, provided it exists.

IF NOT EXIST "..\bin\image.img" GOTO MISSING_IMG

ECHO ==============================
ECHO Starting OrchidOS with QEMU...
ECHO ==============================
:: Emulate an i386 system with 128MB of RAM.
qemu-system-i386 -m 128M -usb -device isa-debug-exit,iobase=0xF4,iosize=0x04 -drive format=raw,index=0,file="..\bin\image.img"
GOTO :EOF

:MISSING_IMG
ECHO The Orchid binary image "%CD%\..\bin\image.img" does not exist^!
ECHO.
ECHO Either it has been renamed, this __run32 script has been moved, or you have not run the compiler.
ECHO.
ECHO.
PAUSE
GOTO :EOF
