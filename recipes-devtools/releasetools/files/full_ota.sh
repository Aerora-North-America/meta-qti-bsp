#!/bin/sh
# Copyright (c) 2017, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of The Linux Foundation nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# full_ota.sh      script to generate OTA upgrade pacakges.
# if sign is part of arguments, the testkey.pk8 located at OTA/build/target/product/security is taken as private key.
# OEMs can replaces this file with their own private key.

# Changes from Qualcomm Innovation Center are provided under the following license:
# Copyright (c) 2022 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear

set -o xtrace

if [ "$#" -lt 4 ]; then
    echo "Usage  : $0 target_files_zipfile rootfs_path ext4_or_ubi [-c fsconfig_file [-p prefix]][--system_path path]"
    echo "------------------------------------------------------------------"
    echo "example: $0 target_files_ubi.zip  machine_image/1.0-r0/rootfs ubi --system_path <path>"
    echo "example: $0 target_files_ext4.zip machine_image/1.0-r0/rootfs ext4 --system_path <path>"
    echo "example: $0 target_files_ext4.zip machine_image/1.0-r0/rootfs ext4  -p system/ -c fsconfig.conf --block --system_path <path>"
    echo "example: $0 target_files_ext4.zip machine_image/1.0-r0/rootfs ext4 --sign"
    exit 1
fi

export PATH=.:$PATH:/usr/bin
export OUT_HOST_ROOT=.

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export FSCONFIGFOPTS=" "
block_based=" "
ubuntu=" "
python_version="python3"
system_path=" "
cache_location=" "
sign_ota_package=" "
mirror_sync=" "
install_only=" "
package_name=""
generate_package_name=false
vendor_code=""
ru_type=""
update_release=""
maintainance_release=""
build_type=""

if [ "$#" -gt 4 ]; then
    IFS=' ' read -a allopts <<< "$@"
    for i in $(seq 3 $#); do
       if [ "${allopts[${i}]}" = "--block" ]; then
           block_based="${allopts[${i}]}"
       elif [ "${allopts[${i}]}" = "--ubuntu" ]; then
           ubuntu="${allopts[${i}]}"
       elif [ "${allopts[${i}]}" = "--system_path" ]; then
           i=$((i+1))
           system_path="${allopts[${i}]}"
       elif [ "${allopts[${i}]}" = "--sign" ]; then
           sign_ota_package="${allopts[${i}]}"
       elif [ "${allopts[${i}]}" = "--mirror_sync" ]; then
           mirror_sync="${allopts[${i}]}"
       elif [ "${allopts[${i}]}" = "--install_only" ]; then
           install_only="${allopts[${i}]}"
       elif [ "${allopts[${i}]}" = "--package_name" ]; then
           generate_package_name=true
       elif [ "${allopts[${i}]}" = "--vendor_code" ]; then
           i=$((i+1))
           vendor_code="${allopts[${i}]}"
       elif [ "${allopts[${i}]}" = "--ru_type" ]; then
           i=$((i+1))
           ru_type="${allopts[${i}]}"
       elif [ "${allopts[${i}]}" = "--update_release" ]; then
           i=$((i+1))
           update_release="${allopts[${i}]}"
       elif [ "${allopts[${i}]}" = "--maintainance_release" ]; then
           i=$((i+1))
           maintainance_release="${allopts[${i}]}"
       elif [ "${allopts[${i}]}" = "--build_type" ]; then
           i=$((i+1))
           build_type="${allopts[${i}]}"
       else
           FSCONFIGFOPTS=$FSCONFIGFOPTS${allopts[${i}]}" "
       fi
    done
fi

# Specify MMC or MTD type device and support MMC device with Squash file system. MTD by default
[[ $3 = "ext4" || $3 = "emmc_sqsh" ]] && device_type="MMC" || device_type="MTD"

# Setup temp folder to unzip target files
target_files=target_files_full_ota_$3
rm -rf $target_files
unzip -qo $1 -d $target_files
mkdir -p $target_files/META
mkdir -p $target_files/SYSTEM
mkdir -p $target_files/BOOT/RAMDISK
touch $target_files/BOOT/RAMDISK/empty

if [ "${block_based}" = "--block" ]; then
    # python2 is needed for block based OTA.
    python_version="python2"
else
    # File-based OTA needs this to assign the correct context to '/' after OTA upgrade
    echo "/system -d system_u:object_r:root_t:s0" >> $target_files/BOOT/RAMDISK/file_contexts

    # File-based OTA also can use canned_fs_config to set uid, gid & mode to all the files
    # The "-x" is to tell fs_config that the modes in fsconfig file are in hex, not octal.
    if [ -e $target_files/META/system.canned.fsconfig ]; then
        FSCONFIGFOPTS=${FSCONFIGFOPTS}" -p system/ -x $target_files/META/system.canned.fsconfig "
    fi
fi

# Generate selabel rules only if file_contexts is packed in target-files
if grep "selinux_fc" $target_files/META/misc_info.txt
then
    zipinfo -1 $1 |  awk 'BEGIN { FS="SYSTEM/" } /^SYSTEM\// {print "system/" $2}' | fs_config ${FSCONFIGFOPTS} -C -S $target_files/BOOT/RAMDISK/file_contexts -D ${2} > $target_files/META/filesystem_config.txt
else
    zipinfo -1 $1 |  awk 'BEGIN { FS="SYSTEM/" } /^SYSTEM\// {print "system/" $2}' | fs_config ${FSCONFIGFOPTS} -D ${2} > $target_files/META/filesystem_config.txt
fi

cd $target_files && zip -q $1 META/*filesystem_config.txt SYSTEM/build.prop BOOT/RAMDISK/empty && cd ..

if $generate_package_name; then
    package_name=$vendor_code$ru_type"ORU"$(date +%y%q)$update_release$maintainance_release$build_type$(date +%Y%m%d)".zip"
else
    package_name="update_$3.zip"
fi

$python_version ./ota_from_target_files $block_based $mirror_sync $install_only $ubuntu -n -v -d $device_type -p . -m linux_embedded --no_signing --system_mount_path $system_path $1 $package_name > ota_debug.txt 2>&1

if [[ $? = 0 ]]; then
    if [ "${sign_ota_package}" = "--sign" ]; then
        # Pipe the contents of OTA zip to openssl to generate the signature of the OTA zip
        unzip -p $package_name | openssl dgst -sha256 -sign private.pem -out update.sig
        if [[ $? = 0 ]]; then
            zip -q -u $package_name update.sig
            echo "OTA zip signing is successful"
        else
            echo "OTA zip signing is failed"
            # Add the python script errors back into the target-files zip
            zip -q $1 ota_debug.txt
            rm $package_name # delete the half-baked update.zip if any;
        fi
    else
        echo "$package_name generation was successful"
    fi
else
    echo "$package_name generation failed"
    # Add the python script errors back into the target-files zip
    zip -q $1 ota_debug.txt
    rm $package_name # delete the half-baked update.zip if any;
fi

# Clean up temporary folder.
rm -rf $target_files
