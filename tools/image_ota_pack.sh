#!/bin/bash

function print_red(){
    echo -e '\033[0;31;1m'
    echo $1
    echo -e '\033[0m'
}

echo "start pack firmware..."

RAMDISK_PKG=ramdisk_sys.tar.gz
TARGET_PKG=target_sys.tar.gz
OTA_VERSION_CONF=`cat ../../../package/allwinner/midea_upgrade/version.conf`

if [ -z $OTA_VERSION_CONF ]; then
	print_red "OTA_VERSION_CONF not defined!"
	exit -1
fi

FIRMWARE_NAME=${OTA_VERSION_CONF}.tar.gz

rm -rf ${FIRMWARE_NAME}

tar -zcvf ${FIRMWARE_NAME} ${TARGET_PKG} ${RAMDISK_PKG}

if [ $? -eq 0 ]; then
	echo "firmware packed!"
	md5sum ${FIRMWARE_NAME} | awk '{print $FIRMWARE_NAME}' > ${FIRMWARE_NAME}.md5
else
	print_red "firmware pack failed!"
	exit -1
fi

