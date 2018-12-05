FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://Disable-unused-mount-points.patch"
SRC_URI += "file://mountpartitions.rules"
SRC_URI += "file://systemd-udevd.service"
SRC_URI += "file://ffbm.target"
SRC_URI += "file://mtpserver.rules"
SRC_URI += "file://sysctl-core.conf"
SRC_URI += "file://limit-core.conf"
SRC_URI += "file://logind.conf"
SRC_URI += "file://ion.rules"

# Custom setup for PACKAGECONFIG to get a slimmer systemd.
# Removed following:
#   * timesyncd - Chronyd is being used instead for NTP timesync
#                 Also timesyncd was resulting in higher boot KPI.
#   * ldconfig  - configures dynamic linker run-time bindings.
#                 ldconfig  creates  the  necessary links and cache to the most
#                 recent shared libraries found in the directories specified on
#                 the command line, in the file /etc/ld.so.conf, and in the
#                 trusted directories (/lib and /usr/lib).  The cache (created
#                 at /etc/ld.so.cache) is used by the run-time linker ld-linux.so.
#                 system-ldconfig.service runs "ldconfig -X", but as / is RO
#                 cache may not be created. Disabling this may introduce app
#                 start time latency.
#   * backlight - Loads/Saves Screen Backlight Brightness, not required.
#   * localed   - systemd-localed is a system service that may be used as
#                 mechanism to change the system locale settings
#   * quotacheck  Not using Quota
#   * vconsole  - Not used
#   * hostname  - No need to change the system's hostname
#   * smack     - Not used
#   * utmp      - No back fill for SysV runlevel changes needed
#   * resolvd   - Use own network name resolution manager
PACKAGECONFIG = " \
    ${@bb.utils.filter('DISTRO_FEATURES', 'selinux', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'wifi', 'rfkill', '', d)} \
    binfmt \
    firstboot \
    hibernate \
    hostnamed \
    ima \
    logind \
    machined \
    networkd \
    polkit \
    randomseed \
    sysusers \
    timedated \
    xz \
"
EXTRA_OECONF += " --disable-efi"
EXTRA_OECONF += " --disable-hwdb"

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
   install -d ${D}${sysconfdir}/udev/rules.d/
   install -m 0644 ${WORKDIR}/ion.rules -D ${D}${sysconfdir}/udev/rules.d/ion.rules
}

RRECOMMENDS_${PN}_remove += "systemd-extra-utils"
PACKAGES_remove += "${PN}-extra-utils"

do_install_append_robot-som-ros () {
    rm ${D}/etc/sysctl.d/core.conf
}

PACKAGES +="${PN}-coredump"
FILES_${PN} += "/etc/initscripts \
                ${sysconfdir}/udev/rules.d "
FILES_${PN}-coredump = "/etc/sysctl.d/core.conf /etc/security/limits.d/core.conf"
