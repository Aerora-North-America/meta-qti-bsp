DESCRIPTION = "Clang based toolchain to compile QTI kernel"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://NOTICE;md5=eeec5cfa0edfb54bfdba757236c7b531"

PR = "r0"

FILESPATH =+ "${WORKSPACE}/kernel-5.10/kernel_platform/prebuilts-master/clang/host/linux-x86/:${WORKSPACE}/kernel-5.10/kernel_platform/prebuilts/clang/host/linux-x86/:"
SRC_URI    = "file://clang-${PV}"
PV = "r416183b"


S = "${WORKDIR}/clang-${PV}"
INHIBIT_SYSROOT_STRIP = "1"
do_compile[noexec] = "1"
do_configure[noexec] = "1"

BBCLASSEXTEND = " native"

do_install() {
    install -d ${D}/${bindir}/clang/
    install -d ${D}/${bindir}/clang/bin/
    cp -rf ${S}/bin/* ${D}/${bindir}/clang/bin/
    install -d ${D}/${bindir}/clang/lib64/
    cp -rf ${S}/lib64/* ${D}/${bindir}/clang/lib64/
}
