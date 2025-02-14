# Provides packages required to build
# QTI Ramdisk archive with systemd as init

LICENSE = "BSD-3-Clause"

# Ramdisk image generation doesn't need abl
EXTRA_IMAGEDEPENDS_remove = "edk2"

PACKAGE_INSTALL = "\
    adbd \
    usb-composition \
    usb-composition-usbd \
    busybox \
    ext4-utils \
    gki-kernel-modules-first-stage \
    fsmgr \
    glib-2.0 \
    glibc \
    initrd-release \
    libbase \
    libcutils \
    libgcc \
    liblog \
    logwrapper \
    packagegroup-core-boot \
    udev \
    ${@bb.utils.contains('DISTRO_FEATURES', 'selinux', 'libselinux libpcre', '', d)} \
"

IMAGE_FSTYPES = "${INITRAMFS_FSTYPES}"
IMAGE_NAME_SUFFIX = ""
IMAGE_FEATURES = ""
IMAGE_LINGUAS = ""

# Set default target to initrd.target
SYSTEMD_DEFAULT_TARGET = "initrd.target"

inherit core-image
