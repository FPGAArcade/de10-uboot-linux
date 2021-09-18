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

cd $TOP_FOLDER/replay_ghrd/software/bootloader

git clone https://github.com/altera-opensource/u-boot-socfpga
cd u-boot-socfpga

git checkout -b replay-bootloader -t origin/socfpga_v2021.01

./arch/arm/mach-socfpga/qts-filter.sh cyclone5 ../../../ ../ ./board/terasic/de10-nano/qts/

export CROSS_COMPILE=${GCC_PREFIX}
make socfpga_de10_nano_defconfig
make -j 48

