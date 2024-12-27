#!/bin/bash

function get_volume_size
{
    if [ $# -lt 1 ]; then
        echo "args lack"
        return 1
    fi
    vol_name="$1"
    info=`ubinfo -d0 -N ${vol_name}`
    if [ $? == 0 ]; then
        tmp=`echo "${info}" | grep "Size:" | awk -F' ' '{print $4}'`
        echo ${tmp:1}
        return 0
    fi
    return 1
}

function volume_name_to_dev
{
    if [ $# -lt 1 ]; then
        echo "args lack"
        return 1
    fi
    vol_name="$1"
    info=`ubinfo -d0 -N ${vol_name}`
    if [ $? == 0 ]; then
        num=`echo "${info}" | grep "Volume ID:" | awk -F' ' '{print $3}'`
        echo "/dev/ubi0_${num}"
        return 0
    else
        return 1
    fi
}

function update_rootfs_volume
{
    img=$1

    old_vol="rootfs_old"
    new_vol="rootfs_new"
    user_vol="user"

    #check img
    if [ $# -lt 1 -o ! -f ${img} ]; then
        echo "${img} no found"
        return 3
    fi

    #umount
    mount | grep "/home/developer" 1>/dev/null 2>&1
    if [ $? == 0 ]; then
        #umount user_vol
        umount /home/developer 1>/dev/null 2>&1
        if [ $? != 0 ]; then
            echo "umount /home/developer fail"
            return 1
        fi
    fi

    #del user_volume
    ubinfo -d0 -N ${user_vol} 1>/dev/null 2>&1
    if [ $? == 0 ]; then
        ubirmvol -N ${user_vol} /dev/ubi0 1>/dev/null 2>&1
        if [ $? != 0 ]; then
            echo "del ${user_vol} volume fail"
            return 1
        fi
        echo "del ${user_vol} volume"
    fi

    #get rootfs size
    size=`get_volume_size rootfs`
    if [ $? != 0 ]; then
        echo "get volume size fail"
        return 1
    fi
    echo "get rootfs size $size"

    # if old_vol exist, maybe did not reboot after update,
    # should restore rootfs name
    ubinfo -d0 -N ${old_vol} 1>/dev/null 2>&1
    if [ $? == 0 ]; then
        ubirename /dev/ubi0 ${old_vol} rootfs rootfs ${new_vol} 1>/dev/null 2>&1
        if [ $? != 0 ]; then
            echo "rename volume fail"
            return 2
        fi
        echo "restore rootfs volume name"
        sync
    fi

    #create update vol
    ubinfo -d0 -N ${new_vol} 1>/dev/null 2>&1
    if [ $? != 0 ]; then
        ubimkvol -t dynamic -s ${size} -N ${new_vol} /dev/ubi0 1>/dev/null 2>&1
        if [ $? != 0 ]; then
            echo "create ${new_vol} fail"
            return 1
        fi
        echo "create ${new_vol} ok"
    fi

    #check vol size
    newsize=`get_volume_size ${new_vol}`
    if [ ${size} != ${newsize} ]; then
        echo "${new_vol} size not eq rootfs"
        return 1
    fi

    #get dev
    dev=`volume_name_to_dev ${new_vol}`
    if [ $? != 0 ]; then
        echo "get vol dev fail"
        return 1
    fi
    echo "get ${dev}"

    #update volume
    echo "start update rootfs volume"
    ubiupdatevol ${dev} ${img} 1>/dev/null 2>&1
    if [ $? != 0 ]; then
        echo "update ${dev} fail"
        return 2
    fi
    echo "update rootfs volume done."
    sync

    #check new rootfs
    tmpdir=/tmp/rootfs
    mkdir -p ${tmpdir}
    mount -t ubifs ubi0:${new_vol} ${tmpdir}
    if [ $? != 0 ]; then
        echo "mount ubi0:${new_vol} fail"
        return 2
    fi
    if [ -d ${tmpdir}/usr \
        -a -d ${tmpdir}/bin \
        -a -d ${tmpdir}/sbin \
        -a -d ${tmpdir}/home \
        -a -d ${tmpdir}/etc \
        -a -f ${tmpdir}/linuxrc ]; then

        rootfs_check_ok="ok"
    else
        rootfs_check_ok="error"
    fi
    umount ${tmpdir}
    if [ $? != 0 ]; then
        echo "umount ${tmpdir} fail"
        return 1
    fi
    if [ ${rootfs_check_ok} != "ok" ]; then
        echo "check rootfs error"
        return 2
    fi

    #rename volume name
    ubirename /dev/ubi0 ${new_vol} rootfs rootfs ${old_vol} 1>/dev/null 2>&1
    if [ $? != 0 ]; then
        echo "rename volume fail"
        return 2
    fi
    echo "swap volume name"
    sync

    echo "update rootfs finish !"
    return 0
}

function update_common_volume
{
    if [ $# -lt 2 ]; then
        echo "args lack"
        return 1
    fi

    vol_name=$1
    img=$2
    #echo $vol_name $img

    #check img
    if [ ! -f ${img} ]; then
        echo "${img} no found"
        return 3
    fi

    #find dev
    dev=`volume_name_to_dev ${vol_name}`
    if [ $? != 0 ]; then
        echo "get vol dev fail"
        return 2
    fi

    #do umount
    info=`mount | grep "ubi0:${vol_name}"`
    if [ $? == 0 ]; then
        #rm config vol
        mount_dir=`echo "${info}" |awk '{print $3}'`
        echo "start umount ${mount_dir}"
        umount ${mount_dir} 1>/dev/null 2>&1
        if [ $? != 0 ]; then
            echo "umount ${mount_dir} fail"
            return 1
        fi
    fi

    # do update
    echo "start update ${dev}"
    ubiupdatevol ${dev} ${img}
    if [ $? != 0 ]; then
        echo "update ${dev} fail"
        return 3
    fi

    # mount
    echo "mount ubi0:${vol_name} ${mount_dir}"
    mount -t ubifs ubi0:${vol_name} ${mount_dir} 1>/dev/null 2>&1
    if [ $? != 0 ]; then
        echo "mount ubi0:${vol_name} fail"
        return 4
    fi

    sync
    echo "update ${vol_name} success"

    return 0
}

manual_stop_app="no"
function restore_genius_app
{
    #restore genius-app status
    if [ ${manual_stop_app} == "yes" ];then
        echo "start genius-app"
        systemctl start genius-app
    fi
}

function stop_genius_app
{
    app_status=`systemctl status genius-app | grep "Active:" | awk '{print$2}'`
    if [ ${app_status} == "active" ];then
        echo "stop genius-app"
        systemctl stop genius-app
        manual_stop_app="yes"
        sleep 1
    fi
}

function try_stop_watchdog
{
    #stop watchdog
    echo "stop watchdog"
    echo -n 'V' >/dev/watchdog
}

let "DEF_CODE=0x30"
let "ERR_CODE=0x30"
PACKET_PATH=/tmp/packet

if [ -r config.img ]; then
    echo -e "\n>>> start update config.img"
    update_common_volume "config" "${PACKET_PATH}/config.img"
    if [ $? != 0 ]; then
        let "ERR_CODE |= 0x01"
        exit ${ERR_CODE}
    fi
fi

if [ -r app.img ]; then
    echo -e "\n>>> start update app.img"
    stop_genius_app
    try_stop_watchdog
    update_common_volume "app" "${PACKET_PATH}/app.img"
    if [ $? != 0 ]; then
        let "ERR_CODE |= 0x02"
        echo "err code ${ERR_CODE}"
        restore_genius_app
        exit ${ERR_CODE}
    fi
fi

if [ -r rootfs.img ]; then
    echo -e "\n>>> start update rootfs.img"
    update_rootfs_volume "${PACKET_PATH}/rootfs.img"
    if [ $? != 0 ]; then
        let "ERR_CODE |= 0x04"
        restore_genius_app
        exit ${ERR_CODE}
    fi
fi

restore_genius_app
sync

exit 0

