#!/bin/bash
# __run32.sh runs the compiled Orchid x86 image with QEMU at will.

# For ease of access, I recommend creating a bash alias in the ~/.bashrc file
# and updating it with `. ~/.bashrc`
# In the case a user does craft an alias for running this, force the current directory.
cd `dirname "$0"`

# Run the Orchid image on the emulator using the last build, provided it exists.
if ! [ -e "../bin/image.img" ]
then
    echo "The Orchid binary image '$PWD/../bin/image.img' does not exist.\n"
    echo "Either it has been renamed, this __run32 script has been moved, or you have not run the compiler."
    exit 1
fi

# Make sure QEMU is installed.
command -v qemu-system-x86_64 >/dev/null 2>&1 || (echo "You do not have QEMU (qemu-system-x86_64) installed. Aborting..."; exit 1;)

echo "=============================="
echo "Starting OrchidOS with QEMU..."
echo "=============================="
# Emulate an x86_64 system with 128MB of RAM.
qemu-system-x86_64 -m 8G -usb -device usb-ehci,id=ehci -device isa-debug-exit,iobase=0xF4,iosize=0x04 -drive format=raw,index=0,file="../bin/image.img"
exit 0
