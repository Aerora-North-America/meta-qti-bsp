FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

INIT_RAMDISK = "${@d.getVar('MACHINE_SUPPORTS_INIT_RAMDISK') or "False"}"

SRC_URI += "\
            file://find-touchscreen.sh \
            file://usb.sh \
            file://mdev.conf \
            file://profile \
            file://fstab \
            file://inittab \
            file://rcS \
            file://no-console.cfg \
            file://login.cfg \
            file://mdev.cfg \
            file://base.cfg \
            ${@oe.utils.conditional('INIT_RAMDISK', 'True', 'file://init.cfg', '', d)} \
            file://syslog-startup.conf \
            file://busybox-syslog.service \
            file://busybox_klogd.patch;patchdir=.. \
            file://iio.sh \
            file://0001-Support-MTP-function.patch \
            file://fix-mdev-crash.patch \
            file://sensors.sh \
            file://add_lock_util.patch \
"
SRC_URI_append_apq8053 += "file://apq8053/mdev.conf"

# By default, we now split BusyBox into two binaries.
# One that is suid root for those components that need it.
# Another for the rest of the components.
BUSYBOX_SPLIT_SUID = "1"

FILES_${PN} += "/usr/bin/env"

VIRT_RM_BIN_LIST = "CONFIG_BRCTL \
             CONFIG_FDFORMAT \
             CONFIG_IPCRM \
             CONFIG_IPCS \
             CONFIG_READPROFILE \
             CONFIG_RTCWAKE \
             CONFIG_SCRIPT \
             CONFIG_SETSID"

do_configure_append() {

    ## virtualization will enable util-linux whose binaries will be partly same as busybox and
    ## lead to compilation issue. update-alternatives.bbclass may not be suitable for this case
    ## Delete items in .config to make sure those binary will not be generated by busybox
    if ${@bb.utils.contains('DISTRO_FEATURES', 'virtualization','true','false',d)}; then
        for var in ${VIRT_RM_BIN_LIST}
        do
            sed -i "s/$var=y/# $var is not set/g" ${S}/.config
        done
        cml1_do_configure
    fi
}

do_install_append() {
    # systemd is udev compatible.
    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${systemd_unitdir}/system/
        install -m 0644 ${WORKDIR}/busybox-syslog.service -D ${D}${systemd_unitdir}/system/busybox-syslog.service
        install -d ${D}${systemd_unitdir}/system/multi-user.target.wants/
        # enable the service for multi-user.target
        ln -sf ${systemd_unitdir}/system/busybox-syslog.service \
           ${D}${systemd_unitdir}/system/multi-user.target.wants/busybox-syslog.service
        install -d ${D}${sysconfdir}/initscripts
        install -m 0755 ${WORKDIR}/syslog ${D}${sysconfdir}/initscripts/syslog
        sed -i 's/syslogd -- -n/syslogd -n/' ${D}${sysconfdir}/initscripts/syslog
        sed -i 's/init.d/initscripts/g'  ${D}${systemd_unitdir}/system/busybox-syslog.service
    else
        install -d ${D}${sysconfdir}/mdev
        install -m 0755 ${WORKDIR}/find-touchscreen.sh ${D}${sysconfdir}/mdev/
        install -m 0755 ${WORKDIR}/usb.sh ${D}${sysconfdir}/mdev/
        install -m 0755 ${WORKDIR}/iio.sh ${D}${sysconfdir}/mdev/

        if [ ${BASEMACHINE} == "mdm9607" ];then
            install -m 0755 ${WORKDIR}/sensors.sh ${D}${sysconfdir}/mdev/
        elif [ ${BASEMACHINE} == "apq8053" ];then
            install -m 0644 ${WORKDIR}/apq8053/mdev.conf ${D}${sysconfdir}/
        elif [ "${BASEMACHINE}" == "sdxpoorwills" ] && [ "${DISTRO}" == "auto" ]; then
            install -m 0755 ${WORKDIR}/sensors.sh ${D}${sysconfdir}/mdev/
        fi

        chmod -R go-x ${D}${sysconfdir}/mdev/
    fi

    mkdir -p ${D}/usr/bin
    ln -s /bin/env ${D}/usr/bin/env
}

# util-linux installs dmesg with priority 80. Use higher priority than util-linux to get busybox dmesg installed.
ALTERNATIVE_PRIORITY[dmesg] = "100"

#FILES_${PN}-mdev += "${sysconfdir}/mdev/* "
