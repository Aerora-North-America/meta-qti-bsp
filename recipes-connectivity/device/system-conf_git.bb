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
    if ${@base_conditional('BASEMACHINE', 'apq8009', base_conditional('BASEPRODUCT', 'qsap', 'false', 'true', d), 'true', d)}; then
        install -m 0644 ${WORKDIR}/wlan_daemon.service -D ${D}/etc/systemd/system/wlan_daemon.service
        # enable the service for multi-user.target
        ln -sf /etc/systemd/system/wlan_daemon.service \
           ${D}/etc/systemd/system/multi-user.target.wants/wlan_daemon.service
    fi
  else
    if ${@base_conditional('BASEMACHINE', 'apq8009', base_conditional('BASEPRODUCT', 'qsap', 'false', 'true', d), 'true', d)}; then
        install -m 0755 ${S}/wlan_daemon -D ${D}${sysconfdir}/init.d/wlan_daemon
    fi
  fi
}

FILES_${PN} += "${userfsdatadir}/misc/wifi/*"
FILES_${PN} += "${base_libdir}/firmware/wlan/qca_cld/*"
FILES_${PN} += "/lib/firmware/wlan/qca_cld/* ${sysconfdir}/init.d/* "

BASEPRODUCT = "${@d.getVar('PRODUCT', False)}"

EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'mdm9607', '--enable-target-mdm9607=yes', '', d)}"
EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'mdm9650', '--enable-target-mdm9650=yes', '', d)}"
EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'apq8096', '--enable-target-apq8096=yes', '', d)}"
EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'apq8098', '--enable-target-apq8098=yes', '', d)}"
EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'apq8009', '--enable-target-apq8009=yes', '', d)}"
EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'apq8017', '--enable-target-apq8017=yes', '', d)}"
EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'sdx20', '--enable-target-sdx20=yes', '', d)}"
EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'sdxpoorwills', '--enable-target-sdxpoorwills=yes', '', d)}"
EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'qcs40x', '--enable-target-qcs405-som1=yes', '', d)}"
EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'qcs605', '--enable-target-qcs605=yes', '', d)}"
EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'sdmsteppe', '--enable-target-sdmsteppe=yes', '', d)}"

EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'apq8053', '--enable-pronto-wlan=yes', '', d)}"
EXTRA_OECONF += "${@base_conditional('BASEMACHINE', 'apq8017', '--enable-pronto-wlan=yes', '', d)}"

# Enable qsap-wlan in place of pronto-wlan for Drones
EXTRA_OECONF_append_qsap += "--enable-snap-wlan=yes --enable-qsap-wlan=yes --enable-naples-wlan=yes"

# Enable drone-wlan in place of pronto-wlan for Drones
EXTRA_OECONF_append_drone += "'--enable-drone-wlan=yes"

# Enable robot-wlan according to variants
EXTRA_OECONF_append_robot-som += "--enable-robot-som-wlan=yes"
EXTRA_OECONF_remove_robot-rome += "--enable-robot-som-wlan=yes"
EXTRA_OECONF_append_robot-rome += "--enable-robot-wlan=yes"
EXTRA_OECONF_remove_robot-pronto += "--enable-robot-som-wlan=yes"
EXTRA_OECONF_append_robot-pronto += "--enable-pronto-wlan=yes"

INITSCRIPT_NAME   = "wlan_daemon"
INITSCRIPT_PARAMS = "remove"
INITSCRIPT_PARAMS_apq8009 = "${@base_conditional('BASEPRODUCT', 'drone', 'start 01 2 3 4 5 . stop 2 0 1 6 .', 'start 98 5 . stop 2 0 1 6 .', d)}"
INITSCRIPT_PARAMS_apq8053 = "start 98 5 . stop 2 0 1 6 ."
INITSCRIPT_PARAMS_apq8017 = "start 98 5 . stop 2 0 1 6 ."
INITSCRIPT_PARAMS_apq8096 = "${@base_conditional('BASEPRODUCT', 'drone', 'start 01 2 3 4 5 . stop 2 0 1 6 .', 'start 98 5 . stop 2 0 1 6 .', d)}"
