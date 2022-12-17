SUMMARY = "Generates Linux kernel signing keys"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

# Ensure PACKAGE_ARCH is set to all even when multilib is enabled.
PACKAGE_ARCH = "all"

inherit allarch nopackages

DEPENDS += "openssl-native"

SRC_URI = "file://x509.genkey"

S = "${WORKDIR}"

do_compile() {
    # generate pair of private/public keys for module signing
    openssl req -new -nodes -utf8 -sha256 -days 36500 -batch -x509 \
        -config x509.genkey -outform PEM -out signing_key.pem \
        -keyout signing_key.pem

    if "${@bb.utils.contains('DISTRO_FEATURES', 'dm-verity', 'true', 'false', d)}"; then
        # generate verity root hash signing keys
        openssl req -new -nodes -utf8 -newkey rsa:1024 -days 36500 -batch \
            -x509 -config x509.genkey -outform PEM -out verity_cert.pem \
            -keyout verity_key.pem
    fi
}

do_install() {
    install -d ${D}/kernel-certs
    install -m 0644 signing_key.pem ${D}/kernel-certs/
    if "${@bb.utils.contains('DISTRO_FEATURES', 'dm-verity', bb.utils.contains('MACHINE_FEATURES', 'dm-verity-initramfs', 'true', 'false', d), 'false', d)}"; then
        install -m 0644 verity_key.pem ${D}/kernel-certs/
        install -m 0644 verity_cert.pem ${D}/kernel-certs/
    fi
}

SYSROOT_DIRS += "/kernel-certs"
