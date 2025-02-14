FILESEXTRAPATHS_prepend_cinder := "${THISDIR}/files:"
FILESEXTRAPATHS_prepend_sdxlemur := "${THISDIR}/files:"
FILESEXTRAPATHS_prepend_sa2150p-nand := "${THISDIR}/files:"
FILESEXTRAPATHS_prepend_sa410m := "${THISDIR}/files:"
FILESEXTRAPATHS_prepend_sa525m := "${THISDIR}/files:"
FILESEXTRAPATHS_prepend_sa515m := "${THISDIR}/files:"
FILESEXTRAPATHS_prepend_sa415m := "${THISDIR}/files:"
FILESEXTRAPATHS_prepend_mdm9607 := "${THISDIR}/files:"

REQUIRED_DISTRO_FEATURES = ""
SRC_URI += "\
    ${@bb.utils.contains('MACHINE_MNT_POINTS', '/systemrw', 'file://mount-copybind', '', d)} \
    ${@bb.utils.contains('MACHINE_MNT_POINTS', '/systemrw', 'file://umount-copybind', '', d)} \
    ${@bb.utils.contains('MACHINE_MNT_POINTS', '/systemrw', 'file://volatile-binds.service.in', '', d)} \
"
do_install_append () {
    if ${@bb.utils.contains('MACHINE_MNT_POINTS', '/systemrw', 'true', 'false', d)}; then
        install -d ${D}${base_sbindir}
        install -m 0755 mount-copybind ${D}${base_sbindir}/
        if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
            install -d ${D}${systemd_unitdir}/system
            for service in ${SYSTEMD_SERVICE_${PN}}; do
                install -m 0644 $service ${D}${systemd_unitdir}/system/
                install -m 0755 umount-copybind ${D}${base_sbindir}/
            done
        fi
    fi
}

VOLATILE_BINDS_sdxlemur = "\
/systemrw/adb_devid  /etc/adb_devid\n\
/systemrw/build.prop /etc/build.prop\n\
/systemrw/data /etc/data/\n\
/systemrw/data/adpl /etc/data/adpl/\n\
/systemrw/data/usb /etc/data/usb/\n\
/systemrw/data/miniupnpd /etc/data/miniupnpd/\n\
/systemrw/data/ipa /etc/data/ipa/\n\
/systemrw/rt_tables /etc/data/iproute2/rt_tables\n\
/systemrw/boot_hsusb_comp /etc/usb/boot_hsusb_comp\n\
/systemrw/boot_hsic_comp /etc/usb/boot_hsic_comp\n\
/systemrw/misc/wifi /etc/misc/wifi/\n\
/systemrw/bluetooth /etc/bluetooth/\n\
/systemrw/allplay /etc/allplay/\n\
/var/volatile/lib /var/lib\n\
"
VOLATILE_BINDS_cinder_append = "\
/systemrw/rt_tables /etc/data/iproute2/rt_tables\n\
/systemrw/gpt_checker_properties.conf /etc/gpt_checker_properties.conf\n\
"

VOLATILE_BINDS_sa2150p-nand = "\
/systemrw/adb_devid  /etc/adb_devid\n\
/systemrw/build.prop /etc/build.prop\n\
/systemrw/data /etc/data/\n\
/systemrw/data/adpl /etc/data/adpl/\n\
/systemrw/data/usb /etc/data/usb/\n\
/systemrw/data/miniupnpd /etc/data/miniupnpd/\n\
/systemrw/data/ipa /etc/data/ipa/\n\
/systemrw/rt_tables /etc/data/iproute2/rt_tables\n\
/systemrw/boot_hsusb_comp /etc/usb/boot_hsusb_comp\n\
/systemrw/boot_hsic_comp /etc/usb/boot_hsic_comp\n\
/systemrw/misc/wifi /etc/misc/wifi/\n\
/systemrw/tel.conf /etc/tel.conf\n\
/systemrw/systemd/network/ethernet.network /etc/systemd/network/ethernet.network\n\
/systemrw/netmgrd/config /etc/netmgrd/config\n\
/systemrw/config.ini /etc/initscripts/config.ini\n\
/systemrw/modem-monitor-usb.conf /etc/modem-monitor-usb.conf\n\
/systemrw/modem-monitor-pcie.conf /etc/modem-monitor-pcie.conf\n\
/systemrw/modem-monitor-eth.conf /etc/modem-monitor-eth.conf\n\
/systemrw/power_state.conf /etc/power_state.conf\n\
/systemrw/enable /etc/cv2x/enable\n\
"
VOLATILE_BINDS_sa410m = "\
/systemrw/adb_devid  /etc/adb_devid\n\
/systemrw/data /etc/data/\n\
/systemrw/data/adpl /etc/data/adpl/\n\
/systemrw/data/usb /etc/data/usb/\n\
/systemrw/data/ipa /etc/data/ipa/\n\
/systemrw/rt_tables /etc/data/iproute2/rt_tables\n\
/systemrw/boot_hsusb_comp /etc/usb/boot_hsusb_comp\n\
/systemrw/boot_hsic_comp /etc/usb/boot_hsic_comp\n\
/systemrw/c2c /etc/c2c/\n\
/systemrw/tel.conf  /etc/tel.conf \n\
"

VOLATILE_BINDS_sa525m = "\
/systemrw/adb_devid  /etc/adb_devid\n\
/systemrw/data /etc/data/\n\
/systemrw/data/adpl /etc/data/adpl/\n\
/systemrw/data/usb /etc/data/usb/\n\
/systemrw/data/ipa /etc/data/ipa/\n\
/systemrw/boot_hsusb_comp /etc/usb/boot_hsusb_comp\n\
/systemrw/misc/wifi /etc/misc/wifi/\n\
/systemrw/c2c /etc/c2c/\n\
/systemrw/tel.conf /etc/tel.conf\n\
/systemrw/enable /etc/cv2x/enable\n\
/systemrw/ObeConfig.conf /etc/ObeConfig.conf\n\
"

VOLATILE_BINDS_sa525m-televm = "\
/systemrw/enable /etc/cv2x/enable\n\
/systemrw/data /etc/data/\n\
/systemrw/power_state.conf /etc/power_state.conf\n\
/systemrw/tel.conf /etc/tel.conf\n\
/systemrw/ObeConfig.conf /etc/ObeConfig.conf\n\
"

VOLATILE_BINDS_sa525m-fotavm = "\
/systemrw/power_state.conf /etc/power_state.conf\n\
/systemrw/tel.conf /etc/tel.conf\n\
"

VOLATILE_BINDS_sa515m = "\
/systemrw/adb_devid  /etc/adb_devid\n\
/systemrw/data /etc/data/\n\
/systemrw/data/adpl /etc/data/adpl/\n\
/systemrw/data/usb /etc/data/usb/\n\
/systemrw/data/ipa /etc/data/ipa/\n\
/systemrw/rt_tables /etc/data/iproute2/rt_tables\n\
/systemrw/boot_hsusb_comp /etc/usb/boot_hsusb_comp\n\
/systemrw/boot_hsic_comp /etc/usb/boot_hsic_comp\n\
/systemrw/c2c /etc/c2c/\n\
/systemrw/tel.conf /etc/tel.conf\n\
"

VOLATILE_BINDS_sa415m = "\
/systemrw/adb_devid  /etc/adb_devid\n\
/systemrw/data /etc/data/\n\
/systemrw/data/adpl /etc/data/adpl/\n\
/systemrw/data/usb /etc/data/usb/\n\
/systemrw/data/ipa /etc/data/ipa/\n\
/systemrw/rt_tables /etc/data/iproute2/rt_tables\n\
/systemrw/boot_hsusb_comp /etc/usb/boot_hsusb_comp\n\
/systemrw/boot_hsic_comp /etc/usb/boot_hsic_comp\n\
"

VOLATILE_BINDS_mdm9607 = "\
/systemrw/adb_devid /etc/adb_devid\n\
/systemrw/boot_hsusb_comp /etc/usb/boot_hsusb_comp\n\
/systemrw/boot_hsic_comp /etc/usb/boot_hsic_comp\n\
"
