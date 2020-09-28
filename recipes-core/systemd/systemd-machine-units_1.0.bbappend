FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI = "${@bb.utils.contains('COMBINED_FEATURES','qti-ab-boot','file://set-slotsuffix.service','',d)}"
SRC_URI_append += " file://cache.mount"
SRC_URI_append += " file://data.mount"
SRC_URI_append += " file://firmware.mount"
SRC_URI_append += " file://firmware-mount.service"
SRC_URI_append += " file://dsp.mount"
SRC_URI_append += " file://dsp-mount.service"
SRC_URI_append += " file://media-card.mount"
SRC_URI_append += " file://media-ram.mount"
SRC_URI_append += " file://persist.mount"
SRC_URI_append += " file://var-volatile.mount"
SRC_URI_append += " file://proc-bus-usb.mount"
SRC_URI_append += " file://dash.mount"
SRC_URI_append += " file://cache-ubi.mount"
SRC_URI_append += " file://persist-ubi.mount"
SRC_URI_append += " file://data-ubi.mount"
SRC_URI_append += " file://firmware-ubi-mount.sh"
SRC_URI_append += " file://firmware-ubi-mount.service"
SRC_URI_append += " file://dsp-ubi-mount.sh"
SRC_URI_append += " file://dsp-ubi-mount.service"
SRC_URI_append += " file://bluetooth-ubi-mount.sh"
SRC_URI_append += " file://bt_firmware-ubi-mount.service"
SRC_URI_append += " file://bt_firmware.mount"
SRC_URI_append += " file://bt_firmware-mount.service"
SRC_URI_append += " file://non-hlos-squash.sh"
SRC_URI_append += " file://overlay.mount"
SRC_URI_append += " file://overlay-etc.mount"
SRC_URI_append += " file://overlay-data.mount"
SRC_URI_append += " file://overlay-cache.mount"
SRC_URI_append += " file://overlay-workdir.sh"
SRC_URI_append += " file://overlay-workdir.service"

SRC_URI_append_batcam += " file://pre_hibernate.sh"
SRC_URI_append_batcam += " file://post_hibernate.sh"

# Various mount related files assume selinux support by default.
# Explicitly remove sepolicy entries when selinux is not present.
fix_sepolicies () {
    sed -i "s#,context=system_u:object_r:firmware_t:s0##g" ${WORKDIR}/firmware.mount
    sed -i "s#,context=system_u:object_r:firmware_t:s0##g" ${WORKDIR}/firmware-mount.service
    sed -i "s#,context=system_u:object_r:firmware_t:s0##g" ${WORKDIR}/bt_firmware.mount
    sed -i "s#,context=system_u:object_r:firmware_t:s0##g" ${WORKDIR}/bt_firmware-mount.service
    sed -i "s#,context=system_u:object_r:adsprpcd_t:s0##g" ${WORKDIR}/dsp-mount.service
    sed -i "s#,rootcontext=system_u:object_r:var_t:s0##g"  ${WORKDIR}/var-volatile.mount
    sed -i "s#,rootcontext=system_u:object_r:data_t:s0##g" ${WORKDIR}/data.mount

    # TODO: figure out the selinux context for the overlays
    sed -i "s#,rootcontext=system_u:object_r:etc_t:s0##g" ${WORKDIR}/overlay-etc.mount
    sed -i "s#,rootcontext=system_u:object_r:data_t:s0##g" ${WORKDIR}/overlay-data.mount
    sed -i "s#,rootcontext=system_u:object_r:data_t:s0##g" ${WORKDIR}/overlay-cache.mount

    sed -i "s#,rootcontext=system_u:object_r:data_t:s0##g" ${WORKDIR}/data-ubi.mount
    sed -i "s#,rootcontext=system_u:object_r:persist_t:s0##g" ${WORKDIR}/persist-ubi.mount
}
do_install[prefuncs] += " ${@bb.utils.contains('DISTRO_FEATURES', 'selinux', '', 'fix_sepolicies', d)}"

# Install var-volatile.mount for tmpfs
do_install_append () {
    install -d 0644 ${D}${systemd_unitdir}/system
    install -d 0644 ${D}${systemd_unitdir}/system/local-fs.target.wants
    install -m 0644 ${WORKDIR}/var-volatile.mount \
            ${D}${systemd_unitdir}/system/var-volatile.mount

    ln -sf ${systemd_unitdir}/system/var-volatile.mount \
           ${D}${systemd_unitdir}/system/local-fs.target.wants/var-volatile.mount
}

# Install mount and service units for mounting hard parititions.
MNT_POINTS  = "${@d.getVar('MACHINE_MNT_POINTS') or ""}"

do_install_append () {
    install -d 0644 ${D}${sysconfdir}/initscripts
    install -d 0644 ${D}${systemd_unitdir}/system
    install -d 0644 ${D}${systemd_unitdir}/system/local-fs.target.requires
    install -d 0644 ${D}${systemd_unitdir}/system/local-fs.target.wants
    install -d 0644 ${D}${systemd_unitdir}/system/sysinit.target.wants
    install -d 0644 ${D}${systemd_unitdir}/system/multi-user.target.wants

    # If the AB boot feature is enabled, then instead of <partition>.mount,
    # a <partition-mount>.service invokes mounting the A/B partition as detected at the time of boot.
    for entry in ${MNT_POINTS}; do
        if [ "$entry" = "$userfsdatadir" ]; then
            if ${@bb.utils.contains('DISTRO_FEATURES','nand-boot','false','true',d)}; then
                install -m 0644 ${WORKDIR}/data.mount ${D}${systemd_unitdir}/system/data.mount

                # Run fsck at boot
                install -d 0644 ${D}${systemd_unitdir}/system/local-fs-pre.target.requires
                ln -sf ${systemd_unitdir}/system/systemd-fsck@.service \
                   ${D}${systemd_unitdir}/system/local-fs-pre.target.requires/systemd-fsck@dev-disk-by\\x2dpartlabel-userdata.service
            else
                install -m 0644 ${WORKDIR}/data-ubi.mount ${D}${systemd_unitdir}/system/data.mount
            fi
            ln -sf ${systemd_unitdir}/system/data.mount ${D}${systemd_unitdir}/system/local-fs.target.wants/data.mount
        fi

        if [ "$entry" = "/cache" ]; then
            if ${@bb.utils.contains('DISTRO_FEATURES','nand-boot','false','true',d)}; then
                install -m 0644 ${WORKDIR}/cache.mount ${D}${systemd_unitdir}/system/cache.mount
            else
                install -m 0644 ${WORKDIR}/cache-ubi.mount ${D}${systemd_unitdir}/system/cache.mount
            fi
            ln -sf ${systemd_unitdir}/system/cache.mount ${D}${systemd_unitdir}/system/multi-user.target.wants/cache.mount
        fi

        if [ "$entry" = "/persist" ]; then
            if ${@bb.utils.contains('DISTRO_FEATURES','nand-boot','false','true',d)}; then
                install -m 0644 ${WORKDIR}/persist.mount ${D}${systemd_unitdir}/system/persist.mount
            else
                if ${@bb.utils.contains('DISTRO_FEATURES','persist-volume','true','false',d)}; then
                    install -m 0644 ${WORKDIR}/persist-ubi.mount ${D}${systemd_unitdir}/system/persist.mount
                fi
            fi
            ln -sf ${systemd_unitdir}/system/persist.mount ${D}${systemd_unitdir}/system/sysinit.target.wants/persist.mount
        fi

        if [ "$entry" = "/firmware" ]; then
            if ${@bb.utils.contains('COMBINED_FEATURES','qti-ab-boot','true','false',d)}; then
                install -m 0644 ${WORKDIR}/firmware-mount.service ${D}${systemd_unitdir}/system/firmware-mount.service
                ln -sf ${systemd_unitdir}/system/firmware-mount.service \
                       ${D}${systemd_unitdir}/system/local-fs.target.requires/firmware-mount.service
            else
                if ${@bb.utils.contains('DISTRO_FEATURES','nand-boot','false','true',d)}; then
                    install -m 0644 ${WORKDIR}/firmware.mount ${D}${systemd_unitdir}/system/firmware.mount
                    ln -sf ${systemd_unitdir}/system/firmware.mount ${D}${systemd_unitdir}/system/local-fs.target.wants/firmware.mount
                else
                    if ${@bb.utils.contains('DISTRO_FEATURES','nand-squashfs','true','false',d)}; then
                        install -m 0744 ${WORKDIR}/non-hlos-squash.sh ${D}${sysconfdir}/initscripts/firmware-ubi-mount.sh
                    else
                        install -m 0744 ${WORKDIR}/firmware-ubi-mount.sh ${D}${sysconfdir}/initscripts/firmware-ubi-mount.sh
                    fi
                    install -m 0644 ${WORKDIR}/firmware-ubi-mount.service ${D}${systemd_unitdir}/system/firmware-mount.service
                    ln -sf ${systemd_unitdir}/system/firmware-mount.service \
                           ${D}${systemd_unitdir}/system/local-fs.target.requires/firmware-mount.service
                fi
            fi
        fi

        if [ "$entry" = "/dsp" ]; then
            if ${@bb.utils.contains('COMBINED_FEATURES','qti-ab-boot','true','false',d)}; then
                install -m 0644 ${WORKDIR}/dsp-mount.service ${D}${systemd_unitdir}/system/dsp-mount.service
                ln -sf ${systemd_unitdir}/system/dsp-mount.service ${D}${systemd_unitdir}/system/local-fs.target.requires/dsp-mount.service
            else
                if ${@bb.utils.contains('DISTRO_FEATURES','nand-boot','false','true',d)}; then
                    install -m 0644 ${WORKDIR}/dsp.mount ${D}${systemd_unitdir}/system/dsp.mount
                    ln -sf ${systemd_unitdir}/system/dsp.mount ${D}${systemd_unitdir}/system/local-fs.target.requires/dsp.mount
                else
                    install -m 0744 ${WORKDIR}/dsp-ubi-mount.sh ${D}${sysconfdir}/initscripts/dsp-ubi-mount.sh
                    install -m 0644 ${WORKDIR}/dsp-ubi-mount.service ${D}${systemd_unitdir}/system/dsp-mount.service
                    ln -sf ${systemd_unitdir}/system/dsp-mount.service ${D}${systemd_unitdir}/system/local-fs.target.requires/dsp-mount.service
                fi
            fi
        fi

        if [ "$entry" = "/bt_firmware" ]; then
            if ${@bb.utils.contains('COMBINED_FEATURES','qti-ab-boot','true','false',d)}; then
                install -m 0644 ${WORKDIR}/bt_firmware-mount.service ${D}${systemd_unitdir}/system/bt_firmware-mount.service
                ln -sf ${systemd_unitdir}/system/bt_firmware-mount.service \
                       ${D}${systemd_unitdir}/system/local-fs.target.requires/bt_firmware-mount.service
            else
                if ${@bb.utils.contains('DISTRO_FEATURES','nand-boot','false','true',d)}; then
                    install -m 0644 ${WORKDIR}/bt_firmware.mount ${D}${systemd_unitdir}/system/bt_firmware.mount
                    ln -sf ${systemd_unitdir}/system/bt_firmware.mount \
                           ${D}${systemd_unitdir}/system/local-fs.target.requires/bt_firmware.mount
                else
                    install -m 0744 ${WORKDIR}/bluetooth-ubi-mount.sh ${D}${sysconfdir}/initscripts/bluetooth-ubi-mount.sh
                    install -m 0644 ${WORKDIR}/bt_firmware-ubi-mount.service ${D}${systemd_unitdir}/system/bt_firmware-mount.service
                    ln -sf ${systemd_unitdir}/system/bt_firmware-mount.service \
                           ${D}${systemd_unitdir}/system/local-fs.target.requires/bt_firmware-mount.service
                fi
            fi
        fi

        if [ "$entry" = "/overlay" ]; then
            install -m 0644 ${WORKDIR}/overlay.mount ${D}${systemd_unitdir}/system/overlay.mount
            install -m 0644 ${WORKDIR}/overlay-etc.mount ${D}${systemd_unitdir}/system/etc.mount
            install -m 0644 ${WORKDIR}/overlay-data.mount ${D}${systemd_unitdir}/system/data.mount
            install -m 0644 ${WORKDIR}/overlay-cache.mount ${D}${systemd_unitdir}/system/cache.mount
            install -D -m 0755 ${WORKDIR}/overlay-workdir.sh ${D}${base_sbindir}/create-overlay-workdirs
            install -D -m 0644 ${WORKDIR}/overlay-workdir.service ${D}${systemd_unitdir}/system/overlay-workdir.service

            ln -sf ${systemd_unitdir}/system/overlay.mount ${D}${systemd_unitdir}/system/local-fs.target.wants/overlay.mount
            ln -sf ${systemd_unitdir}/system/etc.mount ${D}${systemd_unitdir}/system/local-fs.target.wants/etc.mount
            ln -sf ${systemd_unitdir}/system/data.mount ${D}${systemd_unitdir}/system/local-fs.target.wants/data.mount
            ln -sf ${systemd_unitdir}/system/cache.mount ${D}${systemd_unitdir}/system/local-fs.target.wants/cache.mount
            ln -sf ${systemd_unitdir}/system/overlay-workdir.service ${D}${systemd_unitdir}/system/local-fs.target.wants/overlay-workdir.service
        fi
    done
}

# Service for ab-boot support.
do_install_append() {
    install -d ${D}${systemd_unitdir}/system
    if ${@bb.utils.contains('COMBINED_FEATURES', 'qti-ab-boot', 'true', 'false', d)}; then
        install -m 0644 ${WORKDIR}/set-slotsuffix.service ${D}${systemd_unitdir}/system
    fi
}

# Scripts for pre and post hibernate functions
do_install_append_batcam () {
   install -d ${D}${systemd_unitdir}/system-sleep/
   install -m 0755 ${WORKDIR}/pre_hibernate.sh -D ${D}${systemd_unitdir}/system-sleep/pre_hibernate.sh
   install -m 0755 ${WORKDIR}/post_hibernate.sh -D ${D}${systemd_unitdir}/system-sleep/post_hibernate.sh
}

def get_mnt_services(d):
    services = []
    slist = d.getVar("MNT_POINTS").split()
    for s in slist:
        svc = s.replace("/", "")
        if os.path.exists(oe.path.join(d.getVar("D"), d.getVar("systemd_unitdir"), "system", svc + ".mount")):
            services.append("%s.mount" % svc)
        elif os.path.exists(oe.path.join(d.getVar("D"), d.getVar("sysconfdir"), "systemd", "system", svc + ".mount")):
            services.append("%s.mount" % svc)
        else:
            services.append("%s-mount.service" % svc)

    if "/overlay" in slist:
        services.append("overlay-workdir.service")

    return " ".join(services)

SYSTEMD_SERVICE_${PN} += "${@get_mnt_services(d)}"
SYSTEMD_SERVICE_${PN} += "${@bb.utils.contains('COMBINED_FEATURES','qti-ab-boot',' set-slotsuffix.service','',d)}"

FILES_${PN} += " ${systemd_unitdir}/*"
