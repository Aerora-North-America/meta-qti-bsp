inherit autotools-brokensep pkgconfig

DESCRIPTION = "Libselinux"
LICENSE = "PD"
LIC_FILES_CHKSUM = "file://NOTICE;md5=84b4d2c6ef954a2d4081e775a270d0d0"

DEPENDS = "libpcre libmincrypt liblog libcutils"

FILESPATH =+ "${WORKSPACE}/external/:"
SRC_URI = "file://libselinux/"

S = "${WORKDIR}/libselinux"

EXTRA_OECONF = " --with-pcre --with-core-includes=${WORKSPACE}/system/core/include"
