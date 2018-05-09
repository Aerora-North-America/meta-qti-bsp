inherit autotools systemd update-rc.d qperf
DESCRIPTION = "Device specific config"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"
PR = "r3"

FILESPATH =+ "${WORKSPACE}:"
# Provide a baseline
SRC_URI = "file://mdm-init/"
SRC_URI += "file://wlan_daemon.service"

# Update for each machine
S = "${WORKDIR}/mdm-init/"

do_install_append_msm(){
  if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
      install -d ${D}/etc/initscripts
      cp ${D}/etc/init.d/wlan ${D}/etc/initscripts/wlan
      install -d ${D}/etc/systemd/system/
      install -d ${D}/etc/systemd/system/multi-user.target.wants/
    if ${@bb.utils.contains('BASEMACHINE', 'apq8009', bb.utils.contains('BASEPRODUCT', 'qsap', 'false', 'true', d), 'true', d)}; then
        install -m 0644 ${WORKDIR}/wlan_daemon.service -D ${D}/etc/systemd/system/wlan_daemon.service
        # enable the service for multi-user.target
        ln -sf /etc/systemd/system/wlan_daemon.service \
           ${D}/etc/systemd/system/multi-user.target.wants/wlan_daemon.service
    fi
  else
    if ${@bb.utils.contains('BASEMACHINE', 'apq8009', bb.utils.contains('BASEPRODUCT', 'qsap', 'false', 'true', d), 'true', d)}; then
        install -m 0755 ${S}/wlan_daemon -D ${D}${sysconfdir}/init.d/wlan_daemon
    fi
  fi
}

FILES_${PN} += "${userfsdatadir}/misc/wifi/*"
FILES_${PN} += "${base_libdir}/firmware/wlan/qca_cld/*"
FILES_${PN} += "${nonarch_base_libdir}/firmware/wlan/qca_cld/* ${sysconfdir}/init.d/* "

BASEPRODUCT = "${@d.getVar('PRODUCT', False)}"

EXTRA_OECONF += "${@bb.utils.contains('BASEMACHINE', 'mdm9607', '--enable-target-mdm9607=yes', '', d)}"
EXTRA_OECONF += "${@bb.utils.contains('BASEMACHINE', 'mdm9650', '--enable-target-mdm9650=yes', '', d)}"
EXTRA_OECONF += "${@bb.utils.contains('BASEMACHINE', 'apq8096', '--enable-target-apq8096=yes', '', d)}"
EXTRA_OECONF += "${@bb.utils.contains('BASEMACHINE', 'apq8098', '--enable-target-apq8098=yes', '', d)}"
EXTRA_OECONF += "${@bb.utils.contains('BASEMACHINE', 'apq8009', '--enable-target-apq8009=yes', '', d)}"
EXTRA_OECONF += "${@bb.utils.contains('BASEMACHINE', 'apq8017', '--enable-target-apq8017=yes', '', d)}"
EXTRA_OECONF += "${@bb.utils.contains('BASEMACHINE', 'sdx20', '--enable-target-sdx20=yes', '', d)}"
EXTRA_OECONF += "${@bb.utils.contains('BASEMACHINE', 'sdxpoorwills', '--enable-target-sdxpoorwills=yes', '', d)}"
EXTRA_OECONF += "${@bb.utils.contains('BASEMACHINE', 'sdxprairie', '--enable-target-sdxprairie=yes', '', d)}"

EXTRA_OECONF += "${@bb.utils.contains('BASEMACHINE', 'apq8009', '--enable-pronto-wlan=yes', '', d)}"
EXTRA_OECONF += "${@bb.utils.contains('BASEMACHINE', 'apq8053', '--enable-pronto-wlan=yes', '', d)}"
EXTRA_OECONF += "${@bb.utils.contains('BASEMACHINE', 'apq8017', '--enable-pronto-wlan=yes', '', d)}"

# Enable drone-wlan in place of pronto-wlan for Drones
EXTRA_OECONF_remove = "${@bb.utils.contains('BASEPRODUCT', 'drone', '--enable-pronto-wlan=yes', '', d)}"
EXTRA_OECONF += "${@bb.utils.contains('BASEPRODUCT', 'drone', '--enable-drone-wlan=yes', '', d)}"
EXTRA_OECONF_remove = "${@bb.utils.contains('BASEPRODUCT', 'qsap', '--enable-pronto-wlan=yes', '', d)}"
EXTRA_OECONF += "${@bb.utils.contains('BASEPRODUCT', 'qsap', '--enable-snap-wlan=yes', '', d)}"
EXTRA_OECONF += "${@bb.utils.contains('BASEPRODUCT', 'qsap', '--enable-qsap-wlan=yes', '', d)}"
EXTRA_OECONF_remove = "${@bb.utils.contains('PRODUCT', 'robot-rome', '--enable-pronto-wlan=yes', '', d)}"
EXTRA_OECONF += "${@bb.utils.contains('PRODUCT', 'robot-rome', '--enable-robot-wlan=yes', '', d)}"
EXTRA_OECONF += "${@bb.utils.contains('BASEPRODUCT', 'qsap', '--enable-naples-wlan=yes', '', d)}"

INITSCRIPT_NAME   = "wlan_daemon"
INITSCRIPT_PARAMS = "remove"
INITSCRIPT_PARAMS_apq8009 = "${@bb.utils.contains('BASEPRODUCT', 'drone', 'start 01 2 3 4 5 . stop 2 0 1 6 .', 'start 98 5 . stop 2 0 1 6 .', d)}"
INITSCRIPT_PARAMS_apq8053 = "start 98 5 . stop 2 0 1 6 ."
INITSCRIPT_PARAMS_apq8017 = "start 98 5 . stop 2 0 1 6 ."
INITSCRIPT_PARAMS_apq8096 = "${@bb.utils.contains('BASEPRODUCT', 'drone', 'start 01 2 3 4 5 . stop 2 0 1 6 .', 'start 98 5 . stop 2 0 1 6 .', d)}"
