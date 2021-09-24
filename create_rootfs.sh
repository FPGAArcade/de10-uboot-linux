#!/bin/bash

# apt install chrpath diffstat

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $REPO_ROOT

mkdir rootfs && cd rootfs
export set ROOTFS_TOP=`pwd`

cd $ROOTFS_TOP
rm -rf cv && mkdir cv && cd cv
git clone -b gatesgarth git://git.yoctoproject.org/poky.git
git clone -b master git://git.yoctoproject.org/meta-intel-fpga.git
source poky/oe-init-build-env ./build
echo 'MACHINE = "cyclone5"' >> conf/local.conf
echo 'BBLAYERS += " ${TOPDIR}/../meta-intel-fpga "' >> conf/bblayers.conf
# echo 'CORE_IMAGE_EXTRA_INSTALL += "openssh gdbserver"' >> conf/local.conf
bitbake core-image-minimal

# remove 'modules' at line 2039 of ./tmp/work/armv7at2hf-neon-poky-linux-gnueabi/linux-libc-headers/5.8-r0/linux-5.8/init/Kconfig
# and run again
# bitbake core-image-minimal

cp $ROOTFS_TOP/cv/build/tmp/deploy/images/cyclone5/core-image-minimal-cyclone5.tar.gz $REPO_ROOT
