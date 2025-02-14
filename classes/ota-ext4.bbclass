# To add OTA upgrade support on an emmc/ufs target,
# add the MACHINE name to this list.
# This is the "only" list that will control whether
# OTA upgrade will be supported on a target.
DEPENDS += "releasetools-native zip-native fsconfig-native applypatch-native bc-native bsdiff-native"

RM_WORK_EXCLUDE_ITEMS += "rootfs rootfs-dbg"

IMAGE_SYSTEM_MOUNT_POINT = "/"

OTA_TARGET_IMAGE_ROOTFS_EXT4 = "${WORKDIR}/ota-target-image-ext4"

OTA_TARGET_FILES_EXT4 = "target-files-ext4.zip"
OTA_TARGET_FILES_EXT4_PATH = "${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}/${OTA_TARGET_FILES_EXT4}"
OTA_FULL_UPDATE_EXT4 = "full_update_ext4.zip"
OTA_FULL_UPDATE_EXT4_PATH = "${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}/${OTA_FULL_UPDATE_EXT4}"
OTA_INCREMENTAL_UPDATE_EXT4 = "incremental_update_ext4.zip"
OTA_INCREMENTAL_UPDATE_EXT4_PATH = "${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}/${OTA_INCREMENTAL_UPDATE_EXT4}"

MACHINE_FILESMAP_SEARCH_PATH_EXT4 ?= "${@':'.join('%s/conf/machine/filesmap' % p for p in '${BBPATH}'.split(':'))}}"
MACHINE_FILESMAP_FULL_PATH_EXT4 = "${@machine_search(d.getVar('MACHINE_FILESMAP_CONF_EMMC'), d.getVar('MACHINE_FILESMAP_SEARCH_PATH_EXT4')) or ''}"

#Create directory structure for targetfiles.zip
do_recovery_ext4[cleandirs] += "${OTA_TARGET_IMAGE_ROOTFS_EXT4}"
do_recovery_ext4[cleandirs] += "${OTA_TARGET_IMAGE_ROOTFS_EXT4}/BOOTABLE_IMAGES"
do_recovery_ext4[cleandirs] += "${OTA_TARGET_IMAGE_ROOTFS_EXT4}/DATA"
do_recovery_ext4[cleandirs] += "${OTA_TARGET_IMAGE_ROOTFS_EXT4}/META"
do_recovery_ext4[cleandirs] += "${OTA_TARGET_IMAGE_ROOTFS_EXT4}/OTA"
do_recovery_ext4[cleandirs] += "${OTA_TARGET_IMAGE_ROOTFS_EXT4}/RECOVERY"
do_recovery_ext4[cleandirs] += "${OTA_TARGET_IMAGE_ROOTFS_EXT4}/SYSTEM"
do_recovery_ext4[cleandirs] += "${OTA_TARGET_IMAGE_ROOTFS_EXT4}/RADIO"
do_recovery_ext4[cleandirs] += "${OTA_TARGET_IMAGE_ROOTFS_EXT4}/IMAGES"
do_recovery_ext4[cleandirs] += "${OTA_TARGET_IMAGE_ROOTFS_EXT4}/DTBO"

# Create this folder just for saving file_contexts(SElinux security context file),
# It will be used to generate OTA packages when selinux_fc is set.
do_recovery_ext4[cleandirs] += "${OTA_TARGET_IMAGE_ROOTFS_EXT4}/BOOT/RAMDISK"

# recovery rootfs is required for generating OTA files.
# Wait till all tasks of machine-recovery-image complete.

do_recovery_ext4() {
    echo "base image rootfs: ${IMAGE_ROOTFS_EXT4}"
    echo "recovery image rootfs: ${RECOVERY_IMAGE_ROOTFS}"

    # if exists copy filesmap into RADIO directory
    radiofilesmap=${MACHINE_FILESMAP_FULL_PATH_EXT4}
    [[ ! -z "$radiofilesmap" ]] && install -m 755 $radiofilesmap ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/RADIO/filesmap

    # copy the boot\recovery images
    cp ${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}/${BOOTIMAGE_TARGET} ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/BOOTABLE_IMAGES/boot.img
    cp ${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}/${BOOTIMAGE_TARGET} ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/BOOTABLE_IMAGES/recovery.img
    cp ${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}/${BOOTIMAGE_TARGET} ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/IMAGES/boot.img
    cp ${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}/${BOOTIMAGE_TARGET} ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/IMAGES/recovery.img

    cp ${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}/${SYSTEMIMAGE_TARGET} ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/IMAGES/system.img
    cp ${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}/${SYSTEMIMAGE_MAP_TARGET} ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/IMAGES/system.map

    cp ${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}/${USERDATAIMAGE_TARGET} ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/IMAGES/userdata.img
    cp ${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}/${USERDATAIMAGE_MAP_TARGET} ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/IMAGES/userdata.map

    # if dtbo.img file exist then copy
    if [ -f ${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}/${DTBOIMAGE_TARGET} ]; then
        cp ${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}/${DTBOIMAGE_TARGET} ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/IMAGES/dtbo.img
    fi

    # copy the contents of system rootfs
    cp -r ${IMAGE_ROOTFS_EXT4}/. ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/SYSTEM/.
    cd  ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/SYSTEM
    rm -rf var/run
    ln -snf ../run var/run

    # copy the contents of system overlayfs
    cp -r ${IMAGE_ROOTFS_EXT4}/overlay/. ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/DATA/.

    cp -r ${RECOVERY_IMAGE_ROOTFS}/. ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/RECOVERY/.

    #generate recovery.fstab which is used by the updater-script
    echo #mount point fstype device [device2] >> ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/RECOVERY/recovery.fstab
    echo /boot     emmc  /dev/block/bootdevice/by-name/boot >> ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/RECOVERY/recovery.fstab
    echo /overlay     ext4  /dev/block/bootdevice/by-name/userdata >> ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/RECOVERY/recovery.fstab
    echo ${IMAGE_SYSTEM_MOUNT_POINT}   ext4  /dev/block/bootdevice/by-name/system >> ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/RECOVERY/recovery.fstab

    #Getting content for OTA folder
    mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/OTA/bin
    cp ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/RECOVERY/usr/bin/applypatch ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/OTA/bin/.

    cp ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/RECOVERY/usr/bin/updater ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/OTA/bin/.

    # Pack releasetools.py into META folder itself.
    # This could also have been done by passing "--device_specific" to
    # ota_from_target_files.py but it would be hacky to find the absolute path there.
    cp ${WORKSPACE}/OTA/device/qcom/common/releasetools.py ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/META/.

    # copy contents of META folder
    #recovery_api_version is from recovery module
    echo recovery_api_version=3 >> ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/META/misc_info.txt

    #blocksize = BOARD_FLASH_BLOCK_SIZE
    echo blocksize=131072 >> ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/META/misc_info.txt

    # boot_size: Size of boot partition from partition.xml
    echo boot_size=0x011DC000 >> ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/META/misc_info.txt

    # recovery_size : Size of recovery partition from partition.xml
    echo recovery_size=0x011DC000 >> ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/META/misc_info.txt

    #system_size : Size of system partition from partition.xml
    echo system_size=0x10000000 >> ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/META/misc_info.txt

    #userdate_size : Size of data partition from partition.xml
    echo userdata_size=0x0F000000 >> ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/META/misc_info.txt

    #cache_size : Size of data partition from partition.xml
    echo cache_size=0x00800000 >> ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/META/misc_info.txt

    #mkyaffs2_extra_flags : -c $(BOARD_KERNEL_PAGESIZE) -s $(BOARD_KERNEL_SPARESIZE)
    echo mkyaffs2_extra_flags=-c 4096 -s 16 >> ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/META/misc_info.txt

    #extfs_sparse_flag : definition in build
    echo extfs_sparse_flags=-s >> ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/META/misc_info.txt

    #default_system_dev_certificate : Dummy location
    echo default_system_dev_certificate=build/abcd >> ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/META/misc_info.txt

    # set block img diff version to v3
    echo "blockimgdiff_versions=3" >> ${OTA_TARGET_IMAGE_ROOTFS_EXT4}/META/misc_info.txt

    cd ${OTA_TARGET_IMAGE_ROOTFS_EXT4} && zip -qry ${OTA_TARGET_FILES_EXT4_PATH} *
}
addtask do_recovery_ext4 after do_image_complete before do_build

# Generate OTA zip files
do_gen_ota_incremental_zip_ext4[dirs] += "${DEPLOY_DIR_IMAGE}/ota-scripts"
do_gen_ota_incremental_zip_ext4() {
    if [ -f "${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}/${OTA_TARGET_FILES_EXT4}" ]; then

        ./incremental_ota.sh ${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}/${OTA_TARGET_FILES_EXT4} ${OTA_TARGET_FILES_EXT4_PATH} ${IMAGE_ROOTFS_EXT4} ext4 --block --system_path ${IMAGE_SYSTEM_MOUNT_POINT}

        cp update_incr_ext4.zip ${DEPLOY_DIR_IMAGE}/${OTA_INCREMENTAL_UPDATE_EXT4}
    else
        return 0
    fi
}

do_gen_ota_full_zip_ext4[dirs] += "${DEPLOY_DIR_IMAGE}/ota-scripts"
do_gen_ota_full_zip_ext4() {
    ./full_ota.sh ${OTA_TARGET_FILES_EXT4_PATH} ${IMAGE_ROOTFS_EXT4} ext4 --block --system_path ${IMAGE_SYSTEM_MOUNT_POINT}

    cp update_ext4.zip ${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}/${OTA_FULL_UPDATE_EXT4}
}
addtask do_gen_ota_full_zip_ext4 after do_recovery_ext4 before do_build
