#! /usr/bin/env bash

#
# Rissu's kernel build script.
# For A04+e
#

On_Red='\033[41m'         # Red
On_Yellow='\033[43m'      # Yellow
BBlack='\033[1;30m'       # Black
BWhite='\033[1;37m'       # White
On_Blue='\033[44m'        # Blue
Color_Off='\033[0m'       # Text Reset

KERNELSU_REPO="https://raw.githubusercontent.com/rsuntk/KernelSU/main/kernel/setup.sh"

pr_info() {
	echo -e "${On_Blue}${BWhite}[  INFO  ]${Color_Off} $@"
}
pr_warn() {
	echo -e "${On_Yellow}${BBlack}[  WARN  ]${Color_Off} $@"
}
pr_err() {
	echo -e "${On_Red}${BWhite}[  ERROR  ]${Color_Off} $@"
}

if [ -z $CROSS_COMPILE ]; then
	pr_err "Invalid empty variable for \$CROSS_COMPILE"
elif [ -z $PATH ]; then
	pr_err "Invalid empty variable for \$PATH"
elif [ -z $DEFCONFIG ]; then
	pr_err "Invalid empty variable for \$DEFCONFIG"
fi

if [[ "$KERNELSU" = "true" ]]; then
	curl -LSs $KERNELSU_REPO | bash -s main
else
	pr_info "KernelSU is disabled, export KERNELSU=true to enable it"
fi

export CC=clang
export LD=ld.lld
export KERNEL_OUT=$(pwd)/out

export ARCH=arm64
export ANDROID_MAJOR_VERSION=t
export PLATFORM_VERSION=13

export KCFLAGS=-w
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y

DATE=$(date +'%Y%m%d%H%M%S')
IMAGE="$KERNEL_OUT/arch/$ARCH/boot/Image"

if [ -z $JOBS ]; then
	JOBS=$(nproc --all)
fi

# we use bt folder for reference
if [ -d $(pwd)/drivers/misc/mediatek/connectivity/bt ]; then
	export TARGET_PRODUCT="a04"
fi

# Make flags
MKFLAG="-C $(pwd) --jobs $JOBS O=$KERNEL_OUT CC=clang LD=ld.lld KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y"

build() {
	if [[ $@ = "defconfig" ]]; then
		make `echo $MKFLAG` `echo $DEFCONFIG`
	elif [[ $@ = "kernel" ]]; then
		make `echo $MKFLAG`
	else
		pr_err "Usage: mka defconfig/kernel"
	fi
}

if [ -d $KERNEL_OUT ]; then
	pr_warn "An out/ folder detected, Do you wants dirty builds? (y/N)"
	read -p "" OPT;
	
	if [ $OPT = 'y' ] || [ $OPT = 'Y' ]; then
		build kernel;
	else
		rm -rR out;
		make clean;
		make mrproper;
		build defconfig && build kernel;
	fi
else
	build defconfig && build kernel;
fi

if [ -e $IMAGE ]; then
	pr_info "Build done."
	if [ -d $(pwd)/AnyKernel3 ]; then
		if [ ! -z $DEVICE ]; then
			DEVICE_MODEL="`echo $DEVICE`-"
		fi
		cp $IMAGE AnyKernel3/
		cd AnyKernel3 && zip -r6 ../`echo $DEVICE_MODEL`AnyKernel3_`echo $DATE`.zip *
	 	if [[ $IS_CI != "true" ]]; then
	  		rm Image && cd ..
		fi
	fi
else
	pr_err "Build error."
fi