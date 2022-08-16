#!/bin/sh

#set -e
BLD_PART=/dev/mtd1
ROOTFS_PART=/dev/mtd4
ROOTFS_PART1=/dev/mtd8
KERNEL_PART=/dev/mtd5
KERNEL_PART1=/dev/mtd9
APP_PART=/dev/mtd6
APP_PART1=/dev/mtd10
CONFIG_PART=/dev/mtd7
CONFIG_PART1=/dev/mtd11


TMP_DIR=/tmp/packet
UPDATE_PACK=update.img
BLD_FILE=bld_release.bin
DTB_FILE=genius.dtb
LNX_FILE=ubifs
KER_FILE=Image
APP_FILE=app
CFG_FILE=config

SIGN_TOOL=openssl
SIGN_F=update.sign
PUB_KEY=/usr/share/gp/key/rsa_public_key.pem

# no upgrade file
if [ -z  "$1" -o ! -r "$1" ]; then
    echo "No update file."
    exit 1
fi

PACK_FILE=$(basename $1)
PACK_DIR=$(dirname $1)

mkdir -p ${TMP_DIR}
cd ${PACK_DIR}
tar xzf ${PACK_FILE} -C ${TMP_DIR}
if [ "$?" != "0" ]; then
	echo tar pack_file error
    exit 6
fi

cd ${TMP_DIR}
if [ ! -r ${UPDATE_PACK} -o ! -r ${SIGN_F} ]; then
	echo update or sign not here
    exit 7
fi

# Verify package
${SIGN_TOOL} dgst -verify ${PUB_KEY} -sha256 -signature ${SIGN_F} ${UPDATE_PACK} >/dev/null 2>&1
if [ "$?" != "0" ]; then
    echo "Check packet error."
    exit 6
fi

tar xzf ${UPDATE_PACK} -C ${TMP_DIR}
if [ "$?" != "0" ]; then
	echo tar update_pack error
    exit 7
fi

if [ ! -r ${KER_FILE} -a ! -r ${APP_FILE} -a ! -r ${CFG_FILE} -a ! -r ${BLD_FILE} -a ! -r ${DTB_FILE} -a ! -r ${LNX_FILE}];then
	echo "No update file found!"
	exit 3
fi
#flashcp image
if [ -r ${BLD_FILE} ]; then
	echo bld is in here
	flash_eraseall ${BLD_PART}
	if [ "$?" != "0" ]; then
		exit 2
	fi

	#flashcp ${BLD_FILE} ${BLD_PART}
	nandwrite -p ${BLD_PART} ${BLD_FILE}
	if [ "$?" != "0" ];then
		exit 6
	else
		echo "bld update success!"
	fi
fi

if [ -r ${DTB_FILE} ]; then
	echo dtb is in here
	fw_updatadtb `pwd`/${DTB_FILE}
	if [ "$?" != "0" ];then
		exit 6
	fi
fi

ROOTFS_USED=$(fw_printenv 2>/dev/null | grep "using_part_rootfs" | awk -F ':' '{printf $2}')
if [ -r ${LNX_FILE} ]; then
	echo rootfs is in here
    case ${ROOTFS_USED} in
    "0")
        ubiformat ${ROOTFS_PART1} -f ${LNX_FILE}
		if [ "$?" != "0" ];then
			exit 6
		else
			fw_setenv using_part_rootfs 1
		fi
		;;

	"1")
        ubiformat ${ROOTFS_PART} -f ${LNX_FILE}
	    if [ "$?" != "0" ];then
			exit 3
	    else
			fw_setenv using_part_rootfs 0
	    fi
		;;
	esac
	echo rootfs updata success
fi

KERNEL_USED=$(fw_printenv 2>/dev/null | grep "using_part_kernel" | awk -F ':' '{printf $2}')
if [ -r ${KER_FILE} ]; then
	echo kernel is in here
    case ${KERNEL_USED} in
    "0")
        flash_eraseall ${KERNEL_PART1}
        if [ "$?" != "0" ]; then
            exit 2
        fi

        nandwrite -p ${KERNEL_PART1} ${KER_FILE}
		if [ "$?" != "0" ];then
			exit 6
		else
			fw_setenv using_part_kernel 1
		fi
		;;

	"1")
        flash_eraseall ${KERNEL_PART}
        if [ "$?" != "0" ]; then
            exit 2
        fi

        nandwrite -p ${KERNEL_PART} ${KER_FILE}
	    if [ "$?" != "0" ];then
			exit 3
	    else
			fw_setenv using_part_kernel 0
	    fi
		;;
	esac
	echo kernel updata success
fi

APP_USED=$(fw_printenv 2>/dev/null | grep "using_part_app" | awk -F ':' '{printf $2}')
if [ -r ${APP_FILE} ]; then
	echo app is in here
    case ${APP_USED} in
    "0")
        ubiformat ${APP_PART1} -f ${APP_FILE}
		if [ "$?" != "0" ];then
			exit 6
		else
			fw_setenv using_part_app 1
		fi
		;;

	"1")
        ubiformat ${APP_PART} -f ${APP_FILE}
	    if [ "$?" != "0" ];then
			exit 3
	    else
			fw_setenv using_part_app 0
	    fi
		;;
	esac
	echo app updata success
fi

CFG_USED=$(fw_printenv 2>/dev/null | grep "using_part_config" | awk -F ':' '{printf $2}')
if [ -r ${CFG_FILE} ]; then
	echo config is in here
    case ${CFG_USED} in
    "0")
        ubiformat ${CONFIG_PART1} -f ${CFG_FILE}
		if [ "$?" != "0" ];then
			exit 6
		else
			fw_setenv using_part_config 1
		fi
		;;

	"1")
        ubiformat ${CONFIG_PART} -f ${CFG_FILE}
	    if [ "$?" != "0" ];then
			exit 3
	    else
			fw_setenv using_part_config 0
	    fi
		;;
	esac
	echo config updata success
fi

rm -rf ${TMP_DIR}
echo "Update sucessfully,please reboot device."
exit 0
