#!/bin/bash
# __compile32 uses NASM assembler and dd to compile a binary image of Orchid x86.

# For ease of access, I recommend creating a bash alias in the ~/.bashrc file
# and updating it with `. ~/.bashrc`
# In the case the user does create a bash alias, force the working directory.
cd `dirname "$0"`

if ! [ -d "../bin" ]; then
    mkdir "../bin"
fi

# Check dependencies.
command -v nasm >/dev/null 2>&1 || (echo "You do not have NASM installed. Aborting..."; exit 1;)
command -v dd >/dev/null 2>&1 || (echo "You do not have DD installed (?!). Aborting..."; exit 1;)
command -v qemu-system-x86_64 >/dev/null 2>&1 || (echo "You do not have QEMU (qemu-system-x86_64) installed. Aborting..."; exit 1;)

# Compile OS source into raw binaries with NASM.
echo "======================================"
echo "Compiling Operating System binaries..."
#nasm "BOOT_TEST.asm" -f bin -o "../bin/boot_test.bin"
nasm "BOOT.asm" -f bin -o "../bin/boot.bin"
nasm "BOOT_ST2.asm" -f bin -o "../bin/boot2.bin"
nasm "KERNEL.asm" -f bin -o "../bin/kernel.bin"
printf "======================================\n\n"

# Create the image to use.
echo "======================================"
echo "Creating MBR boot image..."
rm -f "../bin/image.img"
#dd if="../bin/boot_test.bin" of="../bin/image_test.img" bs=512
dd if="../bin/boot.bin" of="../bin/image.img" bs=512
printf "======================================\n\n"

# Add stage-two loader (AKA ST2).
echo "======================================"
echo "Creating second-stage loader..."
dd if="../bin/boot2.bin" of="../bin/image.img" bs=512 seek=1
printf "======================================\n\n"

# Append the ST2 with the kernel code...
echo "======================================"
echo "Appending kernel onto image..."
dd if="../bin/kernel.bin" of="../bin/image.img" bs=512 seek=3
# Delete the raw binaries and leave the image release.
rm -f "../bin/boot.bin"
rm -f "../bin/boot2.bin"
rm -f "../bin/kernel.bin"
printf "======================================\n\n"

PS3="Compilation successful. Would you like to run Orchid now? "
select CHOICE in Yes No; do
    if [ -n $CHOICE ]; then
        break
    fi
done

# Emulate an x86_64 system with 2G of RAM.
if [ $CHOICE = "Yes" ]; then
    qemu-system-x86_64 -m 2G -usb -device usb-ehci,id=ehci -device isa-debug-exit,iobase=0xF4,iosize=0x04 -drive format=raw,index=0,file="../bin/image.img"
fi
exit 0
