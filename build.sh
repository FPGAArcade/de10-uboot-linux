#!/bin/bash

# apt install bison flex

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $REPO_ROOT

GCC_PREFIX=arm-none-linux-gnueabihf-

# check if we already have GCC
if ! hash ${GCC_PREFIX}gcc 2>/dev/null; then
    CROSS_GCC_ROOT=$HOME/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf

    echo "'${GCC_PREFIX}gcc' not found; is it in '${CROSS_GCC_ROOT}/' .. ?"

    if [ -e $CROSS_GCC_ROOT/bin/${GCC_PREFIX}gcc ]; then
        echo "Yep! All good!"
        export PATH=$CROSS_GCC_ROOT/bin:$PATH
    else
        echo "Nope; Let's download it!"
        wget https://developer.arm.com/-/media/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf.tar.xz
        echo "Extracting..."
        tar xf gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf.tar.xz -C $HOME
        export PATH=$CROSS_GCC_ROOT/bin:$PATH
        rm gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf.tar.xz
        echo "OK! All good!"
    fi
fi

${GCC_PREFIX}gcc --version


export TOP_FOLDER=$REPO_ROOT

# TODO regenerate BSP if QSYS changes ????

UBOOT_ROOT=$TOP_FOLDER/replay_ghrd/software/bootloader/u-boot-socfpga
[ -f ${UBOOT_ROOT}/Makefile ] || { echo >&2 "Repo not cloned with '--recurse-submodules'. Aborting."; exit 1; }

cd ${UBOOT_ROOT}

./arch/arm/mach-socfpga/qts-filter.sh cyclone5 ../../../ ../ ./board/terasic/de10-nano/qts/

export CROSS_COMPILE=${GCC_PREFIX}
make socfpga_de10_nano_defconfig
make -j 48

[ -f u-boot-with-spl.sfp ] && { git reset --hard; cp u-boot-with-spl.sfp $REPO_ROOT; }

# build kernel
KERNEL_ROOT=$TOP_FOLDER/replay_ghrd/software/linux/linux-socfpga
[ -f ${KERNEL_ROOT}/Makefile ] || { echo >&2 "Repo still not cloned with '--recurse-submodules'?"; exit 1; }

cd ${KERNEL_ROOT}

cp ../socfpga_cyclone5_de10_replay.dts arch/arm/boot/dts/

export ARCH=arm
make socfpga_defconfig
make -j 48 zImage Image dtbs modules
make -j 48 modules_install INSTALL_MOD_PATH=modules_install
make -j 48 socfpga_cyclone5_de10_replay.dtb

rm -rf modules_install/lib/modules/*/build
rm -rf modules_install/lib/modules/*/source

mkdir -p $REPO_ROOT/linux

ln -s ${KERNEL_ROOT}/arch/arm/boot/zImage ${REPO_ROOT}/linux/
ln -s ${KERNEL_ROOT}/arch/arm/boot/Image ${REPO_ROOT}/linux/
ln -s ${KERNEL_ROOT}/arch/arm/boot/dts/socfpga_cyclone5_de10_replay.dtb ${REPO_ROOT}/linux/
ln -s ${KERNEL_ROOT}/modules_install/lib/modules ${REPO_ROOT}/linux/

tar cvzhf ${REPO_ROOT}/linux_kernel.tar.gz -C ${REPO_ROOT}/linux .
rm -rf ${REPO_ROOT}/linux

make distclean
git reset --hard
git clean -fdx

echo "DONE!"
