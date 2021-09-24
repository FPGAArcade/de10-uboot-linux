#!/bin/bash

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $REPO_ROOT

ROOTFS_URL=https://rcn-ee.com/rootfs/eewiki/minfs/ubuntu-20.04-minimal-armhf-2020-05-10.tar.xz
ROOTFS_ARC=`basename $ROOTFS_URL`

[ -f $ROOTFS_ARC ] || wget -c $ROOTFS_URL

sudo rm -rf sd_card && mkdir sd_card && cd sd_card
wget https://releases.rocketboards.org/release/2020.05/gsrd/tools/make_sdimage_p3.py
chmod +x make_sdimage_p3.py

export TOP_FOLDER=$REPO_ROOT

cd $TOP_FOLDER/sd_card
tar xvzf $REPO_ROOT/linux_kernel.tar.gz

tar xf $REPO_ROOT/$ROOTFS_ARC

cd $TOP_FOLDER/sd_card
mkdir sdfs && cd sdfs
cp ../zImage .
cp ../socfpga_cyclone5_de10_replay.dtb .
mkdir extlinux
echo "LABEL Linux Default" > extlinux/extlinux.conf
echo "    KERNEL ../zImage" >> extlinux/extlinux.conf
echo "    FDT ../socfpga_cyclone5_de10_replay.dtb" >> extlinux/extlinux.conf
echo "    APPEND root=/dev/mmcblk0p2 rw rootwait earlyprintk console=ttyS0,115200n8" >> extlinux/extlinux.conf

cd $TOP_FOLDER/sd_card
mkdir rootfs && cd rootfs
#sudo tar xf $REPO_ROOT/core-image-minimal-cyclone5.tar.gz
sudo tar xf $TOP_FOLDER/sd_card/ubuntu-20.04-minimal-armhf-2020-05-10/armhf-rootfs-ubuntu-focal.tar
sudo rm -rf lib/modules/*
sudo mkdir -p lib/modules
sudo cp -r $TOP_FOLDER/sd_card/modules/* lib/modules

cd $TOP_FOLDER/sd_card
cp $REPO_ROOT/u-boot-with-spl.sfp .

cd $TOP_FOLDER/sd_card
sudo python3 ./make_sdimage_p3.py -f \
-P u-boot-with-spl.sfp,num=3,format=raw,size=10M,type=A2  \
-P sdfs/*,num=1,format=fat32,size=32M \
-P rootfs/*,num=2,format=ext4,size=1838M \
-s 1880M \
-n sdcard_replay.img

md5sum sdcard_replay.img

cp sdcard_replay.img $REPO_ROOT

echo "DONE!"
