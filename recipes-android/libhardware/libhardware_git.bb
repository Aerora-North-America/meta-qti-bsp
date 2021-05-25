inherit autotools pkgconfig

DESCRIPTION = "Android libhardware headers"
HOMEPAGE = "http://codeaurora.org/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"

FILESPATH =+ "${WORKSPACE}/hardware:"
SRC_URI   = "file://libhardware/"

S = "${WORKDIR}/libhardware"

PR = "r7"

DEPENDS += "libcutils libutils liblog system-core-headers"

PACKAGECONFIG ?= "audio camera display location sensors"

PACKAGECONFIG[audio]    = "--enable-audio, --disable-audio"
PACKAGECONFIG[camera]   = "--enable-camera, --disable-camera"
PACKAGECONFIG[display]  = "--enable-display, --disable-display"
PACKAGECONFIG[location] = "--enable-location, --disable-location"
PACKAGECONFIG[sensors]  = "--enable-sensors, --disable-sensors"

PACKAGE_ARCH = "${MACHINE_ARCH}"

# Specify the path to look for hals
EXTRA_OECONF_append = " --with-hal-path=${libdir}"
EXTRA_OECONF_append_kona = " BOARD_SUPPORTS_ANDROID_Q_AUDIO=true"
EXTRA_OECONF_append_sdxlemur = " BOARD_SUPPORTS_ANDROID_Q_AUDIO=true"
EXTRA_OECONF_append_qrbx210-rbx = " BOARD_SUPPORTS_ANDROID_Q_AUDIO=true"
