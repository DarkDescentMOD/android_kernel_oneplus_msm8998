#!/bin/bash

#
#  Build Script for RenderZenith for OnePlus 5!
#  Based off AK'sbuild script - Thanks!
#

# Bash Color
rm .version
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="Image.gz-dtb"
DEFCONFIG="oneplus5_defconfig"

# Kernel Details
VER=RenderZenith
VARIANT="OP5-OOS-O-EAS"

# Kernel zip name
HASH=`git rev-parse --short=8 HEAD`
KERNEL_ZIP="RZ-$VARIANT-$(date +%y%m%d)-$HASH" 

# Vars
export LOCALVERSION=~`echo $VER`
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=RenderZenith
export KBUILD_BUILD_HOST=renderserver.net
export LOCALVERSION=~`echo $KERNEL_ZIP`
export CCACHE=ccache

# Paths
KERNEL_DIR=`pwd`
KBUILD_OUTPUT="${KERNEL_DIR}/../out"
REPACK_DIR="${HOME}/android/source/kernel/AnyKernel2"
PATCH_DIR="${HOME}/android/source/kernel/AnyKernel2/patch"
MODULES_DIR="${HOME}/android/source/kernel/AnyKernel2/ramdisk/renderzenith/modules"
ZIP_MOVE="${HOME}/android/source/zips/OP5-zips"
ZIMAGE_DIR="$KBUILD_OUTPUT/arch/arm64/boot"

# Functions
function checkout_ak2_branches {
        cd $REPACK_DIR
        git checkout rk-op5-oos-o
        cd $KERNEL_DIR
}

function clean_all {
        cd $REPACK_DIR
        rm -rf $MODULES_DIR/*
        rm -rf $KERNEL
        rm -rf $DTBIMAGE
        rm -rf zImage
        cd $KERNEL_DIR
        echo
        make O=${KBUILD_OUTPUT} clean && make O=${KBUILD_OUTPUT} mrproper
}

function make_kernel {
        echo
        make O=${KBUILD_OUTPUT} $DEFCONFIG
        make O=${KBUILD_OUTPUT} $THREAD
}

function make_modules {
	# Remove and re-create modules directory
	rm -rf $MODULES_DIR
	mkdir -p $MODULES_DIR

	# Copy modules over
	echo ""
        find $KBUILD_OUTPUT -name '*.ko' -exec cp -v {} $MODULES_DIR \;

	# Strip modules
	${CROSS_COMPILE}strip --strip-unneeded $MODULES_DIR/*.ko

	# Sign modules
	find $MODULES_DIR -name '*.ko' -exec $KBUILD_OUTPUT/scripts/sign-file sha512 $KBUILD_OUTPUT/certs/signing_key.pem $KBUILD_OUTPUT/certs/signing_key.x509 {} \;
}

function make_zip {
        cp -vr $ZIMAGE_DIR/$KERNEL $REPACK_DIR/zImage
        cd $REPACK_DIR
        zip -r9 $KERNEL_ZIP.zip * 
        mv $KERNEL_ZIP.zip $ZIP_MOVE
        cd $KERNEL_DIR
}

DATE_START=$(date +"%s")

echo -e "${green}"
echo "RenderZenith creation script:"
echo -e "${restore}"

echo "Pick Toolchain..."
select choice in gcc-linaro-6.4.1-2018.05-x86_64_aarch64-linux-gnu gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu
do
case "$choice" in
    "gcc-linaro-6.4.1-2018.05-x86_64_aarch64-linux-gnu")
        export CROSS_COMPILE=${HOME}/android/source/toolchains/gcc-linaro-6.4.1-2018.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
        break;;
    "gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu")
        export CROSS_COMPILE=${HOME}/android/source/toolchains/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
        break;;

esac
done

# Use CCACHE
export CROSS_COMPILE="${CCACHE} ${CROSS_COMPILE}"

while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
    y|Y )
        checkout_ak2_branches
        clean_all
        echo
        echo "All Cleaned now."
        break
        ;;
    n|N )
        break
        ;;
    * )
        echo
        echo "Invalid try again!"
        echo
        ;;
esac
done

echo

while read -p "Do you want to build kernel (y/n)? " dchoice
do
case "$dchoice" in
  y|Y)
    make_kernel
    break
    ;;
  n|N )
    break
    ;;
  * )
    echo
    echo "Invalid try again!"
    echo
    ;;
esac
done

while read -p "Do you want to ZIP kernel (y/n)? " dchoice
do
case "$dchoice" in
  y|Y)
    make_modules
    make_zip
    break
    ;;
  n|N )
    break
    ;;
  * )
    echo
    echo "Invalid try again!"
    echo
    ;;
esac
done

echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo
