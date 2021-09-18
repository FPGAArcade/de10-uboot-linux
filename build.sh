#wget https://developer.arm.com/-/media/Files/downloads/gnu-a/10.2-2020.11/binrel/\
#	gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf.tar.xz
#tar xf gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf.tar.xz
cd ~
export PATH=`pwd`/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf/bin:$PATH
cd /mnt/c/replay/de10-uboot-linux

export TOP_FOLDER=`pwd`

# TODO regenerate BSP if QSYS changes ????

cd $TOP_FOLDER/replay_ghrd/software/bootloader

git clone https://github.com/altera-opensource/u-boot-socfpga
cd u-boot-socfpga

git checkout -b replay-bootloader -t origin/socfpga_v2021.01

./arch/arm/mach-socfpga/qts-filter.sh cyclone5 ../../../ ../ ./board/terasic/de10-nano/qts/

export CROSS_COMPILE=arm-none-linux-gnueabihf-
make socfpga_de10_nano_defconfig
make -j 48

