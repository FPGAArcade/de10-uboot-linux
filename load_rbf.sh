#!/bin/bash

[ "$EUID" -ne 0 ] && { echo >&2 "run with : sudo $0 $@"; exit 1; }

[ -z $1 ] && { echo >&2 "usage : $0 <rbf_file>"; exit 1; }

export RBF_FILE=$1
export OVL_NAME=load_rbf

[ -f ${RBF_FILE} ] || { echo >&2 "'${RBF_FILE}' is missing!"; exit 1; }

# make sure there is something to program
cat /sys/class/fpga_manager/fpga0/state 2>/dev/null || { echo >&2 "No FPGA manager! Are you running on the DE10?!"; exit 1; }

set -xe

# we need the device tree compiler
if ! hash dtc 2>/dev/null; then
	apt update
	apt install -y device-tree-compiler
fi

# create device tree overlay config
cat << EOF > ${OVL_NAME}.dtso
/dts-v1/;
/plugin/;

/{
	fragment@0 {
        target-path = "/soc/base-fpga-region";
        __overlay__ {
	    #address-cells = <1>;
            #size-cells = <1>;
            firmware-name = "${RBF_FILE}";
        };
    };
};

EOF

# compile the overlay
dtc -O dtb -o  ${OVL_NAME}.dtbo -b 0 -@ ${OVL_NAME}.dtso

# copy the overlay data to /lib/firmware
mkdir -p /lib/firmware
cp ${OVL_NAME}.dtbo /lib/firmware
cp ${RBF_FILE} /lib/firmware

# create config file system
mkdir -p /config
mount -t configfs configfs /config || echo already mounted

# create overlay environment
pushd /config/device-tree/overlays

[ -d ${OVL_NAME} ] && rmdir ${OVL_NAME}

mkdir ${OVL_NAME}
cat ${OVL_NAME}/status

# kick the overlay ; program the FPGA
echo -n "${OVL_NAME}.dtbo" > ${OVL_NAME}/path

cat ${OVL_NAME}/status

# clean up
rmdir ${OVL_NAME}
popd
rm ${OVL_NAME}.dtso ${OVL_NAME}.dtbo
rm /lib/firmware/${OVL_NAME}.dtbo
rm /lib/firmware/${RBF_FILE}

# ok!
echo "DONE!"
