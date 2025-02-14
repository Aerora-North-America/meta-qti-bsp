inherit native autotools pkgconfig

DESCRIPTION = "DTBO image creation tool from Android"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"
HOMEPAGE = "http://developer.android.com/"

PROVIDES = "virtual/mkdtimg-native"

#DTC provide the libfdt.h
DEPENDS += " virtual/dtc-native"

PR = "r1"

SRC_URI = "${CLO_LA_GIT}/platform/system/libufdt.git;protocol=https;destsuffix=system/libufdt;branch=caf_migration/keystone/p-keystone-qcom-release \
           file://0001-libufdt-support-autoconf-compile.patch"

S = "${WORKDIR}/system/libufdt"
SRCREV = "${AUTOREV}"
