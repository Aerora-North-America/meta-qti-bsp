# QTI Linux mbb minimal image file.
# Provides packages required to build a csm image with
# boot to console

inherit qimage qramdisk

IMAGE_FEATURES += "read-only-rootfs"

CORE_IMAGE_EXTRA_INSTALL += "\
              glib-2.0 \
              coreutils \
              packagegroup-qti-data \
              systemd-machine-units \
              ${@bb.utils.contains('DISTRO_FEATURES','selinux', 'packagegroup-selinux-minimal', '', d)} \
"
