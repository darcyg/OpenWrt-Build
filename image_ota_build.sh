#!/bin/bash

function print_red(){
    echo -e '\033[0;31;1m'
    echo $1
    echo -e '\033[0m'
}

print_red "You confirm version.conf and versionCode have changed?"
read -p "[Yes/no] " confirm

if [ x"$confirm" != x"Yes" ]; then
    print_red "You cancelled OTA image build!"
    exit -1
fi

#env
source build/envsetup.sh
lunch astar_parrot-tina

#ota make
OTA_IMG_DIR=out/astar-parrot/ota
if [ -d ${OTA_IMG_DIR} ]; then
rm -rf ${OTA_IMG_DIR}
fi

make_ota_image

echo "OTA image built, now pack..."
echo "copy pack script..."
cp -f ./tools/image_ota_pack.sh ${OTA_IMG_DIR}/

echo "packing..."
cd ${OTA_IMG_DIR}/
./midea_ota_pack.sh

if [ $? -ne 0 ]; then
    print_red "pack failed, exit!"
    exit -1
fi

print_red "pack done."
print_red $FIRMWARE_NAME

croot

