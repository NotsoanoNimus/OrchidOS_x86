@ECHO OFF
TITLE OS Automatic Compiling Utility
COLOR 4E
CLS

:: This batch file assumes the compilation is happening on a Windows platform, with a DD for Windows utility.
:: ---> DD for Windows: http://www.chrysocome.net/dd

:: Compile OS source into raw binaries with NASM.
echo ======================================
echo Compiling Operating System binaries...
del /f /q "..\bin\boot.bin"
del /f /q "..\bin\boot2.bin"
del /f /q "..\bin\kernel.bin"
nasm "BOOT.asm" -f bin -o "..\bin\boot.bin"
nasm "BOOT_ST2.asm" -f bin -o "..\bin\boot2.bin"
nasm "KERNEL.asm" -f bin -o "..\bin\kernel.bin"
echo ======================================
echo.

:: Create the image to use.
echo ======================================
echo Creating MBR boot image...
del /f /q "..\bin\image.img"
dd if="..\bin\boot.bin" of="..\bin\image.img" bs=512
echo ======================================
echo.

:: Add stage-two loader (AKA ST2).
echo ======================================
echo Creating second-stage loader...
dd if="..\bin\boot2.bin" of="..\bin\image.img" bs=512 seek=1
echo ======================================
echo.

:: Append the ST2 with the kernel code...
echo ======================================
echo Appending kernel onto image...
dd if="..\bin\kernel.bin" of="..\bin\image.img" bs=512 seek=3
:: Delete the raw binaries and leave the image release.
del /f /q "..\bin\boot.bin"
del /f /q "..\bin\boot2.bin"
del /f /q "..\bin\kernel.bin"
echo ======================================

echo.
echo.
CHOICE /C YN /M "Would you like to test the bootable image with QEMU?"
IF ERRORLEVEL 2 EXIT
:: Emulate an i386 system with 128MB of RAM.
"%PROGRAMFILES%\qemu\qemu-system-i386.exe" -m 128M -drive format=raw,index=0,file="..\bin\image.img"
