inherit autotools pkgconfig

BBCLASSEXTEND += "native"

DESCRIPTION = "Verity utilites"
HOMEPAGE = "http://developer.android.com/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"

DEPENDS = "libgcc libmincrypt libsparse zlib openssl bouncycastle"

FILESPATH =+ "${WORKSPACE}/system/extras/:"
SRC_URI = "file://verity \
           file://ext4_utils \
           file://../core/include \
           file://../core/mkbootimg"

S = "${WORKDIR}/verity"

EXTRA_OECONF +=  "\
                --with-coreheader-includes=${WORKSPACE}/system/core/include \
                --with-mkbootimgheader-includes=${WORKSPACE}/system/core/mkbootimg \
                --with-ext4utils-includes=${WORKSPACE}/system/extras/ext4_utils \
"

editveritysigner () {
    sed -i -e '/^java/d' ${S}/verity_signer
    echo 'java -Xmx512M -jar ${STAGING_LIBDIR}/VeritSigner.jar "$@"' >> ${S}/verity_signer
}

do_install_append () {
    editveritysigner
    install -m 755 ${S}/verity_signer ${D}/${bindir}/verity_signer
    install -m 755 ${S}/build_verity_metadata.py ${D}/${bindir}/build_verity_metadata.py
    install -D -m 755 ${THISDIR}/verity.pk8 ${D}/${bindir}/verity.pk8
    install -D -m 755 ${THISDIR}/verity.x509.pem ${D}/${bindir}/verity.x509.pem
}

#NATIVE_INSTALL_WORKS="1"
