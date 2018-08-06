FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://Disable-unused-mount-points.patch"
SRC_URI += "file://mountpartitions.rules"
SRC_URI += "file://systemd-udevd.service"
SRC_URI += "file://ffbm.target"
SRC_URI += "file://mtpserver.rules"
SRC_URI_append_batcam = " file://pre_hibernate.sh"
SRC_URI_append_batcam = " file://post_hibernate.sh"
SRC_URI += "file://sysctl-core.conf"
SRC_URI += "file://limit-core.conf"
SRC_URI += "file://logind.conf"

EXTRA_OECONF += " --disable-efi"

# Don't use systemd network name resolution manager
EXTRA_OECONF += " --disable-resolved"
PACKAGECONFIG_remove = "resolved"
ALTERNATIVE_LINK_NAME[resolv-conf] = "${sysconfdir}/resolv-systemd.conf"

# In aarch64 targets systemd is not booting with -finline-functions -finline-limit=64 optimizations
# So temporarily revert to default optimizations for systemd.
FULL_OPTIMIZATION = "-O2 -fexpensive-optimizations -frename-registers -fomit-frame-pointer -ftree-vectorize"

# Place systemd-udevd.service in /etc/systemd/system
do_install_append () {
   install -d ${D}/etc/systemd/system/
   install -d ${D}/lib/systemd/system/ffbm.target.wants
   install -d ${D}/etc/systemd/system/ffbm.target.wants
   rm ${D}/lib/udev/rules.d/60-persistent-v4l.rules
   install -m 0644 ${WORKDIR}/systemd-udevd.service \
       -D ${D}/etc/systemd/system/systemd-udevd.service
   install -m 0644 ${WORKDIR}/ffbm.target \
       -D ${D}/etc/systemd/system/ffbm.target
   # Enable logind/getty/password-wall service in FFBM mode
   ln -sf /lib/systemd/system/systemd-logind.service ${D}/lib/systemd/system/ffbm.target.wants/systemd-logind.service
   ln -sf /lib/systemd/system/getty.target ${D}/lib/systemd/system/ffbm.target.wants/getty.target
   ln -sf /lib/systemd/system/systemd-ask-password-wall.path ${D}/lib/systemd/system/ffbm.target.wants/systemd-ask-password-wall.path
   install -d ${D}/etc/security/limits.d/
   install -m 0644 ${WORKDIR}/limit-core.conf -D ${D}/etc/security/limits.d/core.conf
   install -d /etc/sysctl.d/
   install -m 0644 ${WORKDIR}/sysctl-core.conf -D ${D}/etc/sysctl.d/core.conf
   install -m 0644 ${WORKDIR}/logind.conf -D ${D}/etc/systemd/logind.conf
   #  Mask journaling services by default.
   #  'systemctl unmask' can be used on device to enable them if needed.
   ln -sf /dev/null ${D}/etc/systemd/system/systemd-journald.service
   ln -sf /dev/null ${D}${systemd_unitdir}/system/sysinit.target.wants/systemd-journal-flush.service
   ln -sf /dev/null ${D}${systemd_unitdir}/system/sysinit.target.wants/systemd-journal-catalog-update.service
}

# Scripts for pre and post hibernate functions for BatCam
do_install_append_batcam () {
   install -d ${D}${systemd_unitdir}/system-sleep/
   install -m 0755 ${WORKDIR}/pre_hibernate.sh -D ${D}${systemd_unitdir}/system-sleep/pre_hibernate.sh
   install -m 0755 ${WORKDIR}/post_hibernate.sh -D ${D}${systemd_unitdir}/system-sleep/post_hibernate.sh

}
PACKAGES +="${PN}-coredump"
FILES_${PN} += "/etc/initscripts"
FILES_${PN}-coredump = "/etc/sysctl.d/core.conf /etc/security/limits.d/core.conf"

