#!/bin/bash

ROOT_DIR=$TINA_BUILD_TOP
OUT_DIR=$TINA_BUILD_TOP/out/$TARGET_BOARD

K=linux-3.10
BIT=32bit
if [ "$TARGET_PLATFORM" = "astar" -o "$TARGET_PLATFORM" = "octopus" -o "$TARGET_PLATFORM" = "banjo" -o "$TARGET_PLATFORM" = "nuclear" ]; then
	K=linux-3.4
	BIT=32bit
fi
if [ "$TARGET_PLATFORM" = "tulip" -o "${TARGET_PLATFORM}" = "koto" ];then
	K=linux-4.4
	BIT=64bit

	grep 'CONFIG_COMPLILE_KERNEL64_USER32=y' ${ROOT_DIR}/.config > /dev/null
	if [ $? -eq 0 ]; then
		BIT=32bit
	fi
fi

KERNEL_DIR=$ROOT_DIR/lichee/$K

build_initramfs()
{
	cd $KERNEL_DIR
	./scripts/build_rootfs.sh $1 $2
	cd -
}

rm -rf $OUT_DIR/verity
mkdir -p $OUT_DIR/verity/keys

openssl genrsa -out $OUT_DIR/verity/keys/rsa_key.pair 2048
openssl rsa -in $OUT_DIR/verity/keys/rsa_key.pair -pubout -out $OUT_DIR/verity/keys/rsa.pk

build_initramfs e rootfs_tina_${BIT}.cpio.gz > /dev/null
cp -rf $OUT_DIR/verity/keys/rsa.pk $KERNEL_DIR/skel/verity_key
build_initramfs c rootfs_tina_${BIT}.cpio.gz > /dev/null

