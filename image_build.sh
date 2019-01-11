#!/bin/bash

function print_red(){
    echo -e '\033[0;31;1m'
    echo $1
    echo -e '\033[0m'
}

#make
source build/envsetup.sh
lunch astar_parrot-tina
make

#pack
if [ $? -ne 0 ]; then
    print_red "make failed, exit!"
    exit -1
fi

pack
if [ $? -ne 0 ]; then
    print_red "pack failed, exit!"
    exit -1
fi

cp -f out/astar-parrot/tina*.img .
