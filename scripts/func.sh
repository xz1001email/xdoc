###!/bin/bash
#!/usr/bin/bash

#write a function in this scripts
#run with function name to test it

function validateMac
{
    local mac=$1
    local result=`expr "${mac}" : "\(\([a-fA-F0-9]\{2\}:\)\{5\}[a-fA-F0-9]\{2\}$\)"`
    #echo "${result}"

    if [ -z ${result} ];then
        echo "mac[${mac}] match error"
        return 1
    fi

    return 0
}

function validateIP
{
    local  ip=$1
    local result=`expr "${ip}" : "\(\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}$\)"`
    if [ -z ${result} ]; then
        echo "ip $1 error"
        return 1
    fi

    local arr=`echo "$result" | awk -F'.' '{print $1 " " $2 " " $3 " " $4}'`
    for val in $arr
    do
        if [ $val -gt 255 ]; then
            echo "ip ${result} error"
            return 2
        fi
    done

    return 0
}

function findLineNum
{
    local key=$1
    local filename=$2
    cat ${filename} | grep -n ${key} | tail -n1 | cut -d':' -f1
}

#replace netconfig
function replaceIP
{
    local key=$1
    local val=$2
    local file=$3
    echo "replace ${key} ${file}"
    line=`findLineNum "${key}" "${file}"`
    if [ -n "${line}" ];then
        sed -ri ''${line}'s/(\b[0-9]{1,3}\.){3}[0-9]{1,3}\b'/"${val}"/ ${file}
    fi
}

function replaceMac
{
    local key=$1
    local val=$2
    local file=$3
    echo "replace ${key} ${file}"
    line=`findLineNum "${key}" "${file}"`
    if [ -n "${line}" ];then
        #echo "replace mac, line ${#line}"
        sed -ri ''${line}'s/(\b[a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}\b'/"${val}"/ ${file}
    else
        #echo "create mac"
        echo "${key} ${val}" >>${file}
    fi
}

#run in git env
function git_reversion()
{
    git_version=`git rev-parse --verify --short HEAD`
    if [ -z "$(git status --untracked-files=no --porcelain)" ]; then
        git_version+=""
    else
        git_version+="_M"
    fi
    echo -n "${git_version}"
}


if [ $# -lt 1 ];then
    echo "input function name to test"
    exit 1
fi

func_name=$1
echo "start test ${func_name}"

if [ "${func_name}" == "validateMac" ]; then
    validateMac "11:11:11:22:22:22"
    validateMac "11:11:11:22:22:2g"
    validateMac "11:11:11:22:22:"
    validateMac "11:11:11:22:22:22:"
    validateMac "11:11:11:22:22:22:11"
elif [ "${func_name}" == "validateIP" ]; then
    validateIP "192.168.10.192"
    validateIP "192.168.10.255"
    validateIP "192.168.10.256"
    validateIP "192.168.300.26"
    validateIP "192.168.300."
elif [ "${func_name}" == "findLineNum" ]; then
    findLineNum "address" "./interfaces"
    aa=`findLineNum "address" "./interfaces"`
    echo "address line num is ${aa}"
    aa=`findLineNum "Address" "./interfaces"`
    echo "Address line num is ${aa}"
elif [ "${func_name}" == "interfaces" ]; then
    netconfig_tmp="./interfaces"
    ip="192.168.1.12"
    mask="255.255.255.0"
    gw="192.168.10.1"
    mac="92:5F:7B:5F:83:EA"
    replaceIP "address" "${ip}" "${netconfig_tmp}"
    replaceIP "netmask" "${mask}" "${netconfig_tmp}"
    replaceIP "gateway" "${gw}" "${netconfig_tmp}"
    replaceMac "MACADDR" "${mac}" "${netconfig_tmp}"
else
    echo "function name not found"
fi

exit 0
