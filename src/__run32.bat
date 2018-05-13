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
qemu-system-x86_64 ^
    -m 8G -usb -device usb-ehci,id=ehci ^
    -device isa-debug-exit,iobase=0xF4,iosize=0x04 ^
    -netdev user,id=eth0,net=10.0.2.0/24,dhcpstart=10.0.2.6,hostfwd=tcp::5555-:22 ^
    -device e1000,netdev=eth0,mac=11:22:33:44:55:66 ^
    -drive format=raw,index=0,file="../bin/image.img" ^
    -object filter-dump,id=eth0,netdev=eth0,file="%USERPROFILE%/Documents/QEMUDUMP.txt"
GOTO :EOF

:MISSING_IMG
ECHO The Orchid binary image "%CD%\..\bin\image.img" does not exist^!
ECHO.
ECHO Either it has been renamed, this __run32 script has been moved, or you have not run the compiler.
ECHO.
ECHO.
PAUSE
GOTO :EOF
