inherit deploy

DESCRIPTION = "Little Kernel bootloader"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=0835ade698e0bcf8506ecda2f7b4f302"
HOMEPAGE = "https://www.codeaurora.org/gitweb/quic/la?p=kernel/lk.git"

PACKAGE_ARCH = "${MACHINE_ARCH}"
FILESPATH =+ "${WORKSPACE}:"

SRC_URI   =  "file://bootable/bootloader/lk"
SRC_URI  +=  "file://0001-Add-instructionset-extension.patch"

S         =  "${WORKDIR}/bootable/bootloader/lk"

MY_TARGET_mdm9650 = "mdm9640"
MY_TARGET_sdx20 = "mdm9640"
MY_TARGET_apq8009  = "msm8909"
MY_TARGET_msm8909  = "msm8909"
MY_TARGET_msm8909w = "msm8909"
MY_TARGET_apq8096  = "msm8996"
MY_TARGET_mdm9607  = "mdm9607"
MY_TARGET_apq8053  = "msm8953"
MY_TARGET_apq8017  = "msm8952"
MY_TARGET         ?= "${BASEMACHINE}"

BOOTLOADER_NAME = "${@bb.utils.contains('MACHINE_FEATURES', 'emmc-boot', 'emmc_appsboot', 'appsboot', d)}"

emmc_bootloader = "${@bb.utils.contains('MACHINE_FEATURES', 'emmc-boot', '1', '0', d)}"

LIBGCC = "${STAGING_LIBDIR}/${TARGET_SYS}/8.2.0/libgcc.a"
LIBGCC_mdm9607 = "${STAGING_LIBDIR}/${TARGET_SYS}/9.3.0/libgcc.a"

# Disable display for nodisplay products
DISPLAY_SCREEN = "1"
DISPLAY_SCREEN_drone = "0"
DISPLAY_SCREEN_batcam = "0"
DISPLAY_SCREEN_robot-som = "0"

ENABLE_DISPLAY = "${DISPLAY_SCREEN}"

EXTRA_OEMAKE = "${MY_TARGET} TOOLCHAIN_PREFIX='${TARGET_PREFIX}'  LIBGCC='${LIBGCC}' DISPLAY_SCREEN=${DISPLAY_SCREEN} ENABLE_DISPLAY=${ENABLE_DISPLAY}"

EXTRA_OEMAKE_append_mdm9650 = " ENABLE_EARLY_ETHERNET=1"

EXTRA_OEMAKE_append = " TARGET_USE_SYSTEM_AS_ROOT_IMAGE=1 VERIFIED_BOOT=0 DEFAULT_UNLOCK=true EMMC_BOOT=${emmc_bootloader}"

EXTRA_OEMAKE_append = " ${@bb.utils.contains('DISTRO_FEATURES', 'ab-support', '', 'APPEND_CMDLINE=1', d)}"

EXTRA_OEMAKE_append = " ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'USE_LE_SYSTEMD=true', '', d)}"

EXTRA_OEMAKE_append = " ${@bb.utils.contains('DISTRO_FEATURES', 'qti-vble', 'VERIFIED_BOOT_LE=1', '', d)}"

EXTRA_OEMAKE_append = " ${@bb.utils.contains('DISTRO_FEATURES', 'dm-verity', bb.utils.contains('MACHINE_FEATURES', 'dm-verity-bootloader', 'VERITY_LE=1', '', d), '', d)}"

EXTRA_OEMAKE_append = " 'ENABLE_LE_VARIANT=1'"

EXTRA_OEMAKE_append_robot-som = "TARGET_USE_QSEECOM_V4=1"

#enable hardfloat
EXTRA_OEMAKE_append = " ${@bb.utils.contains('TUNE_FEATURES', 'callconvention-hard', 'ENABLE_HARD_FPU=1', '', d)}"

#add more cflags to lk, if GCC6.3 version
EXTRA_OEMAKE_append = " 'LKLE_CFLAGS=-Wno-shift-negative-value -Wno-misleading-indentation -Wunused-const-variable=0 -DINIT_BIN_LE=\"/sbin/init\"' "

do_install() {
        install -d ${D}/boot
        install build-${MY_TARGET}/*.mbn ${D}/boot
}

FILES_${PN} = "/boot"
FILES_${PN}-dbg = "/boot/.debug"

do_deploy() {
        install -d ${DEPLOYDIR}
        install build-${MY_TARGET}/*.mbn ${DEPLOYDIR}
}

addtask deploy before do_build after do_install

PACKAGE_STRIP = "no"
