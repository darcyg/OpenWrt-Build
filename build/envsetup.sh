function hmm() {
cat <<EOF
Invoke ". build/envsetup.sh" from your shell to add the following functions to your environment:
- lunch:   lunch <product_name>-<build_variant>
- tapas:   tapas [<App1> <App2> ...] [arm|x86|mips|armv5|arm64|x86_64|mips64] [eng|userdebug|user]
- croot:   Changes directory to the top of the tree.
- m:       Makes from the top of the tree.
- mm:      Builds all of the modules in the current directory, but not their dependencies.
- mmm:     Builds all of the modules in the supplied directories, but not their dependencies.
           To limit the modules being built use the syntax: mmm dir/:target1,target2.
- mma:     Builds all of the modules in the current directory, and their dependencies.
- mmma:    Builds all of the modules in the supplied directories, and their dependencies.
- cgrep:   Greps on all local C/C++ files.
- ggrep:   Greps on all local Gradle files.
- jgrep:   Greps on all local Java files.
- resgrep: Greps on all local res/*.xml files.
- sgrep:   Greps on all local source files.
- godir:   Go to the directory containing a file.

Look at the source to view more functions. The complete list is:
EOF
    T=$(gettop)
    local A
    A=""
    for i in `cat $T/build/envsetup.sh | sed -n "/^[ \t]*function /s/function \([a-z_]*\).*/\1/p" | sort | uniq`; do
      A="$A $i"
    done
    echo $A
}

PLATFORM_CHOICES=(nuclear astar octopus tulip koto azalea sitar cello banjo violin mandolin)
# check to see if the supplied product is one we can build
function check_platform()
{
    for v in ${PLATFORM_CHOICES[@]}
    do
        if [ "$v" = "$1" ]
        then
            return 0
        fi
    done
    return 1
}

# Get the value of a build variable as an absolute path.
function get_abs_build_var()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    (\cd $T; CALLED_FROM_SETUP=true BUILD_SYSTEM=build \
      command make --no-print-directory -f build/config.mk dumpvar-abs-$1)
}

# Get the exact value of a build variable.
function get_build_var()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    (\cd $T; CALLED_FROM_SETUP=true BUILD_SYSTEM=build \
      command make --no-print-directory -f build/config.mk dumpvar-$1)
}

function check_product()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    TARGET_PRODUCT=$1 \
    TARGET_BUILD_VARIANT= \
    TARGET_BUILD_TYPE= \
    TARGET_BUILD_APPS= \
    get_build_var TARGET_DEVICE > /dev/null
}

VARIANT_CHOICES=(tina dragonboard)

# check to see if the supplied variant is valid
function check_variant()
{
    for v in ${VARIANT_CHOICES[@]}
    do
        if [ "$v" = "$1" ]
        then
            return 0
        fi
    done
    return 1
}

function printconfig()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi

    get_build_var report_config
}

function set_stuff_for_environment()
{
    set_sequence_number

    export TINA_BUILD_TOP=$(gettop)
    # With this environment variable new GCC can apply colors to warnings/errors
    export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
}

function set_sequence_number()
{
    export BUILD_ENV_SEQUENCE_NUMBER=10
}

# Clear this variable.  It will be built up again when the vendorsetup.sh
# files are included at the end of this file.
unset LUNCH_MENU_CHOICES
function add_lunch_combo()
{
    local new_combo=$1
    local c
    for c in ${LUNCH_MENU_CHOICES[@]} ; do
        if [ "$new_combo" = "$c" ] ; then
            return
        fi
    done
    LUNCH_MENU_CHOICES=(${LUNCH_MENU_CHOICES[@]} $new_combo)
}

# add the default one here

function print_lunch_menu()
{
    local uname=$(uname)
    echo
    echo "You're building on" $uname
    echo
    echo "Lunch menu... pick a combo:"

    local i=1
    local choice
    for choice in ${LUNCH_MENU_CHOICES[@]}
    do
        echo "     $i. $choice"
        i=$(($i+1))
    done

    echo
}

function lunch()
{
    local answer

    if [ "$1" ] ; then
        answer=$1
    else
        print_lunch_menu
        echo -n "Which would you like?"
        read answer
    fi

    local selection=

    if [ -z "$answer" ]
    then
        selection=astar_parrot-tina
    elif (echo -n $answer | grep -q -e "^[0-9][0-9]*$")
    then
        if [ $answer -le ${#LUNCH_MENU_CHOICES[@]} ]
        then
            selection=${LUNCH_MENU_CHOICES[$(($answer-1))]}
        fi
    elif (echo -n $answer | grep -q -e "^[^\-][^\-]*-[^\-][^\-]*$")
    then
        selection=$answer
    fi

    if [ -z "$selection" ]
    then
        echo
        echo "Invalid lunch combo: $answer"
        return 1
    fi

    local platform=$(echo -n $selection | sed -e "s/_.*$//")
    check_platform $platform

    if [ $? -ne 0 ]
    then
        echo
        echo "** Don't have a platform spec for: '$platform'"
        echo "** Must be one of ${PLATFORM_CHOICES[@]}"
        echo "** Do you have the right repo manifest?"
        platform=
    fi
    local product=$(echo -n $selection | sed -e "s/-.*$//")
    check_product $product
    if [ $? -ne 0 ]
    then
        echo
        echo "** Don't have a product spec for: '$product'"
        echo "** Do you have the right repo manifest?"
        product=
    fi

    local variant=$(echo -n $selection | sed -e "s/^[^\-]*-//")
    check_variant $variant
    if [ $? -ne 0 ]
    then
        echo
        echo "** Invalid variant: '$variant'"
        echo "** Must be one of ${VARIANT_CHOICES[@]}"
        variant=
    fi

    if [ -z "$product" -o -z "$variant" -o -z "$platform" ]
    then
        echo
        return 1
    fi

    export TARGET_PRODUCT=$product
    export TARGET_PLATFORM=$platform
    export TARGET_BOARD=$(get_build_var TARGET_DEVICE)
    export TARGET_BUILD_VARIANT=$variant
    export TARGET_BUILD_TYPE=release

    rm -rf tmp
    echo

    set_stuff_for_environment
    printconfig
}

function get_chip()
{
	local chip=
	if [ "x$TARGET_PLATFORM" = "xsitar" -o "x$TARGET_PLATFORM" = "xviolin" ]; then
		chip=sun3iw1p1
	elif [ "x$TARGET_PLATFORM" = "xnuclear" ]; then
		chip=sun5i
	elif [ "x$TARGET_PLATFORM" = "xastar" ]; then
		chip=sun8iw5p1
	elif [ "x$TARGET_PLATFORM" = "xoctopus" ]; then
		chip=sun8iw6p1
	elif [ "x$TARGET_PLATFORM" = "xbanjo" ]; then
		chip=sun8iw8p1
	elif [ "x$TARGET_PLATFORM" = "xcello" ]; then
		chip=sun8iw10p1
	elif [ "x$TARGET_PLATFORM" = "xazalea" ]; then
		chip=sun8iw11p1
	elif [ "x$TARGET_PLATFORM" = "xmandolin" ]; then
		chip=sun8iw15p1
	elif [ "x$TARGET_PLATFORM" = "xtulip" ]; then
		chip=sun50iw1p1
	elif [ "x$TARGET_PLATFORM" = "xkoto" ]; then
		chip=sun50iw3p1
	fi
	echo $chip
}

# Build brandy(uboot,boot0,fes) if you want.
function build_boot()
{
	local T=$(gettop)
	local chip=
	local cmd=$1
	local o_option=$2
	echo $TARGET_PRODUCT $TARGET_PLATFORM $TARGET_BOARD
	if [ -z "$TARGET_BOARD" -o -z "$TARGET_PLATFORM" ]; then
		echo "Please use lunch to select a target board before build boot."
		return 1
	fi

	chip=$(get_chip)
	if [ "x$chip" = "x" ]; then
		echo "platform($TARGET_PLATFORM) not support"
		return 1
	fi

	cd $T/lichee/brandy/
	if [ x"$o_option" != "x" ]; then
		./build.sh -p $chip -o $o_option
	else
		./build.sh -p $chip
	fi
	if [ $? -ne 0 ]; then
		echo "$cmd stop for build error in brandy, Please check!"
		cd - 1>/dev/null
		return 1
	fi
	cd - 1>/dev/null
	echo "$cmd success!"
	return 0
}

# Build uboot, uboot for nor, boot0
function mboot()
{
	build_boot "mboot" ""
}

# Build uboot, uboot for nor
function muboot()
{
	build_boot "muboot" "uboot"
}

# Build uboot for nor
function muboot_nor()
{
	build_boot "muboot_nor" "uboot_nor"
}

# Build boot0
function mboot0()
{
	build_boot "mboot0" "boot0"
}

# Tab completion for lunch.
function _lunch()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    COMPREPLY=( $(compgen -W "${LUNCH_MENU_CHOICES[*]}" -- ${cur}) )
    return 0
}
complete -F _lunch lunch

function gettop
{
    local TOPFILE=build/envsetup.sh
    if [ -n "$TOP" -a -f "$TOP/$TOPFILE" ] ; then
        # The following circumlocution ensures we remove symlinks from TOP.
        (cd $TOP; PWD= /bin/pwd)
    else
        if [ -f $TOPFILE ] ; then
            # The following circumlocution (repeated below as well) ensures
            # that we record the true directory name and not one that is
            # faked up with symlink names.
            PWD= /bin/pwd
        else
            local HERE=$PWD
            T=
            while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
                \cd ..
                T=`PWD= /bin/pwd -P`
            done
            \cd $HERE
            if [ -f "$T/$TOPFILE" ]; then
                echo $T
            fi
        fi
    fi
}

function mm() {
	local T=$(gettop)
	$T/scripts/mm.sh $T $*
}

function mlibc() {
	local T=$(gettop)
	$T/scripts/mlibc.sh $T $*
}

# function make_ota_image(){
# 	local T=$(gettop)
# 	printf "build ota package\n"
# 	[ -e $T/package/utils/otabuilder/Makefile ] &&
# 		make -j
# 		make package/utils/otabuilder/clean -j
# 		make package/utils/otabuilder/install -j
# 		print_red bin/sunxi/ota_md5.tar.gz
# 	printf "build ota package end\n"
# }
function make_img_md5(){
    #$1: target image
    md5sum $1 | awk '{print $1}' > $1.md5
}
function print_red(){
    echo -e '\033[0;31;1m'
    echo $1
    echo -e '\033[0m'
}

function ota_general_keys()
{
    local target_dir=$1
    local key_name=OTA_Key.pem

    [ $# -lt 1 ] && echo "usage:ota_general_keys key_dir" && return 1
    rm -f "$target_dir"/*.pem
    #this is for test, finally we should manage ota key with other keys
    #general key
    openssl genrsa -out "$target_dir"/OTA_Key.pem -f4 2048
    #get public key
    openssl rsa -in "$target_dir"/OTA_Key.pem -pubout -out "$target_dir"/OTA_Key_pub.pem
    ls -ll "$target_dir"
    echo "done! please keep the key safe!"
}

function ota_sign_files()
{
    local target_dir=$1
    local key_dir=$2
    local key_name=OTA_Key.pem
    [ ! -n $3 ] && key_name=$3
    [ $# -lt 2 ] && echo "usage:ota_sign_files files_dir key_dir [key_name]" && return 1
    target_list="boot.img rootfs.img recovery.img boot_package.img boot0_nand.img boot0_sdcard.img"
    rm -f "$patch_dir"/*.signature
    for i in $target_list; do
        [ ! -f "$target_dir"/"$i" ] &&  print_red "$target_dir/$i is not exist!"
	echo "do signature for $target_dir/$i"
	openssl dgst -sha256 -out "$target_dir"/"$i.signature" -sign "$key_dir"/"$key_name" "$target_dir"/"$i"
    done
    ls -ll "$target_dir"
}

function ota_general_patchs()
{
    local old_file_dir=$1
    local new_file_dir=$2
    local patch_dir=$3
    target_list="boot.img rootfs.img recovery.img boot_package.img boot0_nand.img boot0_sdcard.img"
    [ $# -lt 3 ] && echo "usage:ota_general_patchs old_file_dir new_file_dir patch_dir" && return 1


    rm -f "$patch_dir"/*.patch "$patch_dir"/*.md5 "$patch_dir"/*.signature

    for i in $target_list; do
        [ ! -f "$old_file_dir"/"$i" ] && print_red "$old_file_dir/$i is not exist!"
	[ ! -f "$new_file_dir"/"$i" ] &&  print_red "$new_file_dir/$i is not exist!"
	echo "generaling patch for $i"
	bsdiff "$old_file_dir"/"$i" "$new_file_dir"/"$i" "$patch_dir"/"$i.patch"
	cp "$new_file_dir"/"$i.md5" "$patch_dir"/"$i.md5"
	cp "$new_file_dir"/"$i.signature" "$patch_dir"/"$i.signature"
    done
    ls -ll "$patch_dir"
}

function ota_save_files()
{
    [ $# -lt 1 ] && echo "usage:ota_save_files file_dir" && return 1
    local target_dir=$1
    echo target_dir:"$target_dir"
    [ ! -d "$target_dir" ] && echo target_dir:"$target_dir" not exit!! &&  return 1

    local T=$(gettop)
    local BIN_DIR=$T/out/${TARGET_BOARD}
    local boot_img="$(readlink -f "$BIN_DIR"/image/boot.fex)"
    local rootfs_img="$(readlink -f "$BIN_DIR"/image/rootfs.fex)"
    local recovery_img="$(readlink -f "$BIN_DIR"/image/recovery.fex)"
    #uboot and boot0
    local boot_package_img="$(readlink -f "$BIN_DIR"/image/boot_package.fex)"
    local boot0_nand_img="$(readlink -f "$BIN_DIR"/image/boot0_nand.fex)"
    local boot0_sdcard_img="$(readlink -f "$BIN_DIR"/image/boot0_sdcard.fex)"

    rm -f "$target_dir"/*.img "$target_dir"/*.md5 "$target_dir"/*.signature
    [ -f "$boot_img" ] && cp "$boot_img" "$target_dir"/boot.img && make_img_md5 "$target_dir"/boot.img
    [ -f "$rootfs_img" ] && cp "$rootfs_img" "$target_dir"/rootfs.img && make_img_md5 "$target_dir"/rootfs.img
    [ -f "$recovery_img" ] && cp "$recovery_img" "$target_dir"/recovery.img && make_img_md5 "$target_dir"/recovery.img

    [ -f "$boot_package_img" ] && cp "$boot_package_img" "$target_dir"/boot_package.img && make_img_md5 "$target_dir"/boot_package.img
    [ -f "$boot0_nand_img" ] && cp "$boot0_nand_img" "$target_dir"/boot0_nand.img && make_img_md5 "$target_dir"/boot0_nand.img
    [ -f "$boot0_sdcard_img" ] && cp "$boot0_sdcard_img" "$target_dir"/boot0_sdcard.img && make_img_md5 "$target_dir"/boot0_sdcard.img
    ls -l "$target_dir"
}

function make_recovery() {
    local T=$(gettop)
    local make_recovery_fail=0

    print_red "build recovery img"

    mv "$T/.config" "$T/.config.bk"
    mv "$T/target/allwinner/${TARGET_BOARD}/defconfig" "$T/target/allwinner/${TARGET_BOARD}/defconfig.bk"
    cp "$T/target/allwinner/${TARGET_BOARD}/defconfig_recovery" .config
    cp .config "$T/target/allwinner/${TARGET_BOARD}/defconfig"

    make V=s "$@"
    if [ $? -ne 0 ]
    then
        print_red "make recovery fail!"
        make_recovery_fail=1
    fi

    mv "$T/.config.bk" "$T/.config"
    mv "$T/target/allwinner/${TARGET_BOARD}/defconfig.bk" "$T/target/allwinner/${TARGET_BOARD}/defconfig"

    if [ $make_recovery_fail -ne 0 ];then
        print_red "build recovery fail!"
    else
        print_red "build recovery finish!"
    fi
}

function make_ramfs() {
    local T=$(gettop)
    local make_ramfs_fail=0

    print_red "build ramfs img"

    mv "$T/.config" "$T/.config.bk"
    mv "$T/target/allwinner/${TARGET_BOARD}/defconfig" "$T/target/allwinner/${TARGET_BOARD}/defconfig.bk"
    cp "$T/target/allwinner/${TARGET_BOARD}/defconfig_ramfs" .config
    cp .config "$T/target/allwinner/${TARGET_BOARD}/defconfig"

    make V=s "$@"
    if [ $? -ne 0 ]
    then
        print_red "make ramfs fail!"
        make_ramfs_fail=1
    fi

    mv "$T/.config.bk" "$T/.config"
    mv "$T/target/allwinner/${TARGET_BOARD}/defconfig.bk" "$T/target/allwinner/${TARGET_BOARD}/defconfig"

    if [ $make_ramfs_fail -ne 0 ];then
        print_red "build ramfs fail!"
    else
        print_red "build ramfs finish!"
        print_red "cp  $T/out/${TARGET_BOARD}/compile_dir/target/rootfs to $T/out/${TARGET_BOARD}/compile_dir/target/rootfs_ramfs"
        rm -rf "$T/out/${TARGET_BOARD}/compile_dir/target/rootfs_ramfs"
        cp -fpr "$T/out/${TARGET_BOARD}/compile_dir/target/rootfs"  "$T/out/${TARGET_BOARD}/compile_dir/target/rootfs_ramfs"
        du -sh "$T/out/${TARGET_BOARD}/compile_dir/target/rootfs_ramfs"
    fi

    cd "$T/out/${TARGET_BOARD}/compile_dir/target/"
    ramfs_cpio=rootfs_ramfs.cpio.none
    #ramfs_cpio=rootfs_ramfs.cpio.gz
    #ramfs_cpio=rootfs_ramfs.cpio.xz
    rm -f ${ramfs_cpio}
    ln -s rootfs_ramfs skel
    ../../../../scripts/build_rootfs.sh c ${ramfs_cpio}
    mv ${ramfs_cpio} "$T/target/allwinner/${TARGET_BOARD}/"
    cd "$T"
    du -sh "$T/target/allwinner/${TARGET_BOARD}/${ramfs_cpio}"
}


function make_ota_image(){
    local T=$(gettop)
    local chip=sunxi
    local need_usr=0
    local make_ota_fail=0
    [ x$CHIP = x"sun5i" ] && chip=sun5i
    local BIN_DIR=$T/out/${TARGET_BOARD}
    local OTA_DIR=$BIN_DIR/ota
    mkdir -p $OTA_DIR
    print_red "build ota package"
    grep "CONFIG_SUNXI_SMALL_STORAGE_OTA=y" $T/.config && need_usr=1
    #target image
    target_list="$BIN_DIR/boot.img $BIN_DIR/rootfs.img $BIN_DIR/usr.img"
    if [ $need_usr -eq 0 ];then
        target_list="$BIN_DIR/boot.img $BIN_DIR/rootfs.img"
    fi
    [ -n $1 ] && [ x$1 = x"--force" ] && rm -rf $target_list
    for i in $target_list; do
        if [ ! -f $i ]; then
            img=${i##*/}
            print_red "$i is not exsit! rebuild the image."
            make
            if [ $? -ne 0 ]
            then
                print_red "make $img file! make_ota_image fail!"
                make_ota_fail=1
            fi
            break
        fi
    done

    rm -rf $OTA_DIR/target_sys
    mkdir -p $OTA_DIR/target_sys
    cp $BIN_DIR/boot.img $OTA_DIR/target_sys/
    make_img_md5 $OTA_DIR/target_sys/boot.img

    cp $BIN_DIR/rootfs.img $OTA_DIR/target_sys/
    make_img_md5 $OTA_DIR/target_sys/rootfs.img
    if [ $need_usr -eq 1 ];then
        rm -rf $OTA_DIR/usr_sys
        mkdir -p $OTA_DIR/usr_sys
        cp $BIN_DIR/usr.img $OTA_DIR/usr_sys/
        make_img_md5 $OTA_DIR/usr_sys/usr.img
    fi
    #upgrade image
    mv $T/.config $OTA_DIR/.config.old

    grep -v -e CONFIG_TARGET_ROOTFS_INITRAMFS  $T/target/allwinner/${TARGET_BOARD}/defconfig_ota > .config
    echo 'CONFIG_TARGET_ROOTFS_INITRAMFS=y' >> .config
	echo 'CONFIG_TARGET_AW_OTA_INITRAMFS=y' >> .config
	echo 'CONFIG_TARGET_INITRAMFS_COMPRESSION_XZ=y' >> .config
	cp .config $T/target/allwinner/${TARGET_BOARD}/defconfig
    #refresh_ota_env
    make V=s
    if [ $? -ne 0 ]
    then
        print_red "make_ota_image fail!"
        make_ota_fail=1
    fi

    cp $OTA_DIR/.config.old $T/.config
    cp $OTA_DIR/.config.old $T/target/allwinner/${TARGET_BOARD}/defconfig

    rm -rf $OTA_DIR/ramdisk_sys
    mkdir -p $OTA_DIR/ramdisk_sys

    cp $BIN_DIR/boot_initramfs.img $OTA_DIR/ramdisk_sys/
    make_img_md5 $OTA_DIR/ramdisk_sys/boot_initramfs.img

    if [ $need_usr -eq 1 ];then
        cd $OTA_DIR && \
            tar -zcvf target_sys.tar.gz target_sys && \
            tar -zcvf ramdisk_sys.tar.gz ramdisk_sys && \
            tar -zcvf usr_sys.tar.gz usr_sys && \
            cd $T
    else
        cd $OTA_DIR && \
            tar -zcvf target_sys.tar.gz target_sys && \
            tar -zcvf ramdisk_sys.tar.gz ramdisk_sys && \
            cd $T
    fi
    #refresh_ota_env
    if [ $make_ota_fail -ne 0 ];then
        print_red "build ota packag fail!"
    else
        print_red "build ota packag finish!"
    fi
}

usage()
{
	printf "Usage: pack [-cCHIP] [-pPLATFORM] [-bBOARD] [-d] [-s] [-h]
	-c CHIP (default: $chip)
	-p PLATFORM (default: $platform)
	-b BOARD (default: $board)
	-d pack firmware with debug info output to card0
	-s pack firmware with signature
	-m pack dump firmware
	-h print this help message
"
}

function pack() {
	local T=$(gettop)
	local chip=sun5i
	local platform=$(get_build_var TARGET_BUILD_VARIANT)
	local board_platform=$(get_build_var TARGET_BOARD_PLATFORM)
	local board=$(get_build_var TARGET_BOARD)
	local debug=uart0
	local sigmode=none
	local securemode=none
	local mode=normal
	unset OPTIND
	while getopts "dsvmh" arg
	do
		case $arg in
			d)
				debug=card0
				;;
			s)
				sigmode=secure
				;;
			v)
				securemode=secure
				;;
			m)
				mode=dump
				;;
			h)
				usage
				return 0
				;;
			?)
			return 1
			;;
		esac
	done

	chip=$(get_chip)
	if [ "x$chip" = "x" ]; then
		echo "platform($TARGET_PLATFORM) not support"
		return
	fi

	$T/scripts/pack_img.sh -c $chip -p $platform -b $board \
		-d $debug -s $sigmode -m $mode -v $securemode -t $T
}

function createkeys()
{
	local T=$(gettop)
	local board=$(get_build_var TARGET_BOARD)
	$T/scripts/createkeys -b $board -t $T
}

function minstall()
{
	make $1install $*
	echo "make package"
}

function mclean()
{
	make $1clean $2
	echo "make clean"
}

function croot()
{
    T=$(gettop)
    if [ "$T" ]; then
        \cd $(gettop)
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function cboot()
{
    T=$(gettop)
    U=u-boot-2014.07
    if [ "$TARGET_PLATFORM" = "astar" -o "$TARGET_PLATFORM" = "banjo" -o "$TARGET_PLATFORM" = "nuclear" -o "$TARGET_PLATFORM" = "octopus" ]; then
	U=u-boot-2011.09
    fi
    if [ "$T" ]; then
        \cd $(gettop)/lichee/brandy/$U/
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function cboot0()
{
    T=$(gettop)
    U=uboot_2014_sunxi_spl
    if [ "$TARGET_PLATFORM" = "astar" -o "$TARGET_PLATFORM" = "banjo" -o "$TARGET_PLATFORM" = "nuclear" -o ]; then
	U=uboot_2011_sunxi_spl
    fi
    if [ "$T" ]; then
        \cd $(gettop)/lichee/bootloader/$U/
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function cdts()
{
    T=$(gettop)
    K=linux-3.10
    A=arm
    S=
    if [ "$TARGET_PLATFORM" = "azalea" -o "$TARGET_PLATFORM" = "sitar" -o "$TARGET_PLATFORM" = "cello" -o "$TARGET_PLATFORM" = "violin" ]; then
	    K=linux-3.10
	    A=arm
    fi
    if [ "$TARGET_PLATFORM" = "mandolin" ]; then
	    K=linux-4.9
	    A=arm
    fi
    if [ "$TARGET_PLATFORM" = "tulip" ];then
	    K=linux-4.4
	    A=arm64
	    S=sunxi
    fi
    if [ "${TARGET_PLATFORM}" = "koto" ];then
	    K=linux-4.9
	    A=arm64
	    S=sunxi
    fi
    if [ "$T" ]; then
        \cd $(gettop)/lichee/$K/arch/$A/boot/dts/$S
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function ckernel()
{
    T=$(gettop)
    K=linux-3.10
    if [ "$TARGET_PLATFORM" = "astar" -o "$TARGET_PLATFORM" = "octopus" -o "$TARGET_PLATFORM" = "banjo" -o "$TARGET_PLATFORM" = "nuclear" ]; then
        K=linux-3.4
    fi
    if [ "$TARGET_PLATFORM" = "tulip" ];then
        K=linux-4.4
    fi
    if [ "${TARGET_PLATFORM}" = "koto" -o "${TARGET_PLATFORM}" = "mandolin" ];then
        K=linux-4.9
    fi
    if [ "$T" ]; then
        \cd $(gettop)/lichee/$K/
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function cgeneric()
{
    T=$(gettop)
    if [ "$T" ]; then
        \cd $(gettop)/target/allwinner/generic
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function cdevice()
{
    T=$(gettop)
    if [ "$T" ]; then
	    \cd $(gettop)/target/allwinner/${TARGET_BOARD}
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function cconfigs()
{
    T=$(gettop)
    if [ "$T" ]; then
	    \cd $(gettop)/target/allwinner/${TARGET_BOARD}/configs
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function ctoolchain()
{
    T=$(gettop)
    A=arm
    C=musl

    if [ -z "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
    C=`grep CONFIG_LIBC= $T/target/allwinner/${TARGET_BOARD}/defconfig |cut -d "=" -f 2 | sed 's/"//g'`

    if [ "$TARGET_PLATFORM" = "sitar" -o "$TARGET_PLATFORM" = "violin" ]; then
	    A=arm
	    C=arm9-$C
    fi
    if [ "$TARGET_PLATFORM" = "astar" -o "$TARGET_PLATFORM" = "azalea" -o "$TARGET_PLATFORM" = "octopus" \
	-o "$TARGET_PLATFORM" = "banjo" -o "$TARGET_PLATFORM" = "cello" -o "$TARGET_PLATFORM" = "mandolin" ]; then
	    A=arm
    fi
    if [ "$TARGET_PLATFORM" = "tulip" -o "${TARGET_PLATFORM}" = "koto" ];then
	    A=aarch64
    fi
    cd $(gettop)/prebuilt/gcc/linux-x86/$A/toolchain-sunxi-$C/toolchain
}

function add-rootfs-demo()
{
    T=$(gettop)
    if [ "$T" ]; then
		cp -rf $(gettop)/package/add-rootfs-demo/*  $(gettop)/out/${TARGET_BOARD}/compile_dir/target/rootfs
		rm $(gettop)/out/${TARGET_BOARD}/compile_dir/target/rootfs/README
		$(gettop)/out/host/bin/mksquashfs4          $(gettop)/out/${TARGET_BOARD}/compile_dir/target/rootfs \
						$(gettop)/out/${TARGET_BOARD}/root.squashfs -noappend -root-owned -comp xz -b 256k \
											-p '/dev d 755 0 0' -p '/dev/console c 600 0 0 5 1' -processors 1
		rm  $(gettop)/out/${TARGET_BOARD}/rootfs.img
		dd if=$(gettop)/out/${TARGET_BOARD}/root.squashfs of=$(gettop)/out/${TARGET_BOARD}/rootfs.img bs=128k conv=sync
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
	fi
}

function crootfs()
{
    T=$(gettop)
    if [ "$T" ]; then
		cd $(gettop)/out/${TARGET_BOARD}/compile_dir/target/rootfs
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
	fi
}

function mkrootfs_squashfs4()
{
	kernelfs_formate=`grep CONFIG_SQUASHFS=y $(gettop)/lichee/*/.config | cut -d ":" -f 2`
	echo -e "\033[31m$kernelfs_formate\033[0m"
	if [ -z $kernelfs_formate ];then
		echo -e "\033[31m run -make kernel_menuconfig- choice "squashfs" first!\033[0m"
	else
		compression=`grep ^CONFIG_KERNEL.*y$ $(gettop)/.config | awk 'NR==1{print}' | sed -r 's/.*_(.*)=.*/\1/' | tr '[A-Z]' '[a-z]'`
		if [ -n "$compression" ];then
			$(gettop)/out/host/bin/mksquashfs4  $(gettop)/out/${TARGET_BOARD}/compile_dir/target/rootfs  $(gettop)/out/${TARGET_BOARD}/root.squashfs \
									-noappend -root-owned -comp $compression -b 256k -p '/dev d 755 0 0' -p '/dev/console c 600 0 0 5 1' -processors 1
		else
			$(gettop)/out/host/bin/mksquashfs4  $(gettop)/out/${TARGET_BOARD}/compile_dir/target/rootfs $(gettop)/out/${TARGET_BOARD}/root.squashfs  \
											-noappend -root-owned -comp xz -b 256k -p '/dev d 755 0 0' -p '/dev/console c 600 0 0 5 1' -processors 1
		fi
		rm  $(gettop)/out/${TARGET_BOARD}/rootfs.img
		dd if=$(gettop)/out/${TARGET_BOARD}/root.squashfs of=$(gettop)/out/${TARGET_BOARD}/rootfs.img bs=128k conv=sync
	fi
}

function mkrootfs_ext4()
{
	kernelfs_formate=`grep CONFIG_EXT4_FS=y $(gettop)/lichee/*/.config | cut -d ":" -f 2`
	echo -e "\033[31m $kernelfs_formate\033[0m"
	if [ -z $kernelfs_formate ];then
		echo -e "\033[31m run -make kernel_menuconfig- choice "ext4fs" first!\033[0m"
	else
		$(gettop)/out/host/bin/make_ext4fs -l 50331648 -b 4096 -i 6000 -m 0 -J $(gettop)/out/${TARGET_BOARD}/compile_dir/target/linux-azalea-m2ultra/root.ext4  $(gettop)/out/${TARGET_BOARD}/compile_dir/target/rootfs
		rm  $(gettop)/out/${TARGET_BOARD}/rootfs.img
		dd if=$(gettop)/out/${TARGET_BOARD}/compile_dir/target/linux-azalea-m2ultra/root.ext4 of=$(gettop)/out/${TARGET_BOARD}/rootfs.img bs=128k conv=sync
	fi
}

function mkrootfs_jffs2()
{
	kernelfs_formate=`grep CONFIG_JFFS2_FS=y $(gettop)/lichee/*/.config | cut -d ":" -f 2`
	echo -e "\033[31m$kernelfs_formate\033[0m"
	if [ -z $kernelfs_formate ];then
		echo -e "\033[31m run -make kernel_menuconfig- choice "jffs2fs" first!\033[0m"
	else
		$(gettop)/out/host/bin/mkfs.jffs2  --little-endian --squash-uids -v -X rtime -x zlib -x lzma -D $(gettop)/build/device_table.txt \
					-e 128KiB -o $(gettop)/out/${TARGET_BOARD}/root.jffs2-128k -d $(gettop)/out/${TARGET_BOARD}/compile_dir/target/rootfs \
																										-v 2>&1 1>/dev/null | awk '/^.+$/'
		rm  $(gettop)/out/${TARGET_BOARD}/rootfs.img
		dd if=$(gettop)/out/${TARGET_BOARD}/root.jffs2-128k of=$(gettop)/out/${TARGET_BOARD}/rootfs.img bs=128k conv=sync
	fi
}

function recomp_rootfs()
{
    T=$(gettop)
    if [ "$T" ]; then
		file_formate=`grep ^CONFIG_TARGET_ROOTFS.*y $(gettop)/.config | cut -d "_" -f 4 | grep "=" | sed -r 's/(.*)=.*/\1/'`
		echo -e "\033[31m $file_formate\033[0m"
		if [ -z $file_formate ];then
			echo -e "\033[31m run -make menuconfig- choice fs_formate of target images!\033[0m"
		else
			[ x$file_formate = x"SQUASHFS" ] && mkrootfs_squashfs4
			[ x$file_formate = x"EXT4FS" ] && mkrootfs_ext4
			[ x$file_formate = x"JFFS2" ] && mkrootfs_jffs2
		fi
	else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
	fi
}

function cout()
{
    T=$(gettop)
    if [ "$T" ]; then
	    \cd $(gettop)/out/${TARGET_BOARD}
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function cgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' \) -print0 | xargs -0 grep --color -n "$@"
}

function godir ()
{
    if [[ -z "$1" ]]; then
        echo "Usage: godir <regex>"
        return
    fi
    T=$(gettop)
    if [[ ! -f $T/filelist ]]; then
        echo -n "Creating index..."
        (\cd $T; find . -wholename ./out -prune -o -wholename ./.repo -prune -o -type f > filelist)
        echo " Done"
        echo ""
    fi
    local lines
    lines=($(\grep "$1" $T/filelist | sed -e 's/\/[^/]*$//' | sort | uniq))
    if [[ ${#lines[@]} = 0 ]]; then
        echo "Not found"
        return
    fi
    local pathname
    local choice
    if [[ ${#lines[@]} > 1 ]]; then
        while [[ -z "$pathname" ]]; do
            local index=1
            local line
            for line in ${lines[@]}; do
                printf "%6s %s\n" "[$index]" $line
                index=$(($index + 1))
            done
            echo
            echo -n "Select one: "
            unset choice
            read choice
            if [[ $choice -gt ${#lines[@]} || $choice -lt 1 ]]; then
                echo "Invalid choice"
                continue
            fi
            pathname=${lines[$(($choice-1))]}
        done
    else
        pathname=${lines[0]}
    fi
    \cd $T/$pathname
}

# Print colored exit condition
function pez
{
    "$@"
    local retval=$?
    if [ $retval -ne 0 ]
    then
        echo -e "\e[0;31mFAILURE\e[00m"
    else
        echo -e "\e[0;32mSUCCESS\e[00m"
    fi
    return $retval
}

function get_make_command()
{
  echo command make V=s
}

function make()
{
    local start_time=$(date +"%s")
    $(get_make_command) "$@"
    local ret=$?
    local end_time=$(date +"%s")
    local tdiff=$(($end_time-$start_time))
    local hours=$(($tdiff / 3600 ))
    local mins=$((($tdiff % 3600) / 60))
    local secs=$(($tdiff % 60))
    echo
    if [ $ret -eq 0 ] ; then
        echo -n -e "#### make completed successfully "
    else
        echo -n -e "#### make failed to build some targets "
    fi
    if [ $hours -gt 0 ] ; then
        printf "(%02g:%02g:%02g (hh:mm:ss))" $hours $mins $secs
    elif [ $mins -gt 0 ] ; then
        printf "(%02g:%02g (mm:ss))" $mins $secs
    elif [ $secs -gt 0 ] ; then
        printf "(%s seconds)" $secs
    fi
    echo -e " ####"
    echo
    return $ret
}



if [ "x$SHELL" != "x/bin/bash" ]; then
    case `ps -o command -p $$` in
        *bash*)
            ;;
        *)
            echo "WARNING: Only bash is supported, use of other shell would lead to erroneous results"
            ;;
    esac
fi

# Execute the contents of any vendorsetup.sh files we can find.
for f in `test -d target && find -L target -maxdepth 4 -name 'vendorsetup.sh' | sort 2> /dev/null`
do
    echo "including $f"
    . $f
done
unset f
