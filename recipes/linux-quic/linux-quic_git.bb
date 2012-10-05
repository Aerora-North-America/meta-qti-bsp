inherit linux-kernel-base localgit

DESCRIPTION = "QuIC Linux Kernel"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=d7810fab7487fb0aad327b76f1be7cd7"
COMPATIBLE_MACHINE = "(9615-cdp|mdm9625)"

# Moved to here from the distro.conf file because it really kind of belongs
# here and we're moving more to being a BSP with the MSM linux distro...
KERNEL_IMAGETYPE = "${@base_conditional('MACHINE', '9615-cdp', 'Image', 'zImage', d)}"

PACKAGE_ARCH = "${MACHINE_ARCH}"
KDIR = "/kernel"
SRC_DIR = "${WORKSPACE}/kernel"
PV = "git-${GITSHA}"
PR = "r4"

PROVIDES += "virtual/kernel"
DEPENDS = "virtual/${TARGET_PREFIX}gcc"

INHIBIT_DEFAULT_DEPS = "1"
# Until usr/src/linux/scripts can be correctly processed
PACKAGE_STRIP = "no"
INHIBIT_PACKAGE_STRIP = "1"

PACKAGES = "kernel kernel-base kernel-module-bridge \
  kernel-module-ip-tables \
  kernel-module-iptable-nat \
  kernel-module-iptable-filter \
  kernel-module-ipt-masquerade \
  kernel-module-x-tables \
  kernel-module-nf-defrag-ipv4 \
  kernel-module-nf-conntrack \
  kernel-module-nf-conntrack-ipv4 \
  kernel-module-nf-nat"

PACKAGES =+ "kernel-image"
FILES_kernel-image = "/boot/${KERNEL_IMAGETYPE}*"

PACKAGES =+ "kernel-dev"
FILES_kernel-dev = "/boot/System.map* /boot/Module.symvers* /boot/config*"

PACKAGES =+ "kernel-vmlinux"
FILES_kernel-vmlinux = "/boot/vmlinux*"

PACKAGES =+ "kernel-headers"
FILES_kernel-headers = "${KDIR}/usr/include"

PACKAGES =+ "kernel-modbuild"
FILES_kernel-modbuild = "${KDIR}"
INSANE_SKIP_kernel-modbuild = "arch"

PACKAGES =+ "kernel-modules"
FILES_kernel-modules = "/lib/modules"

# The kernel makefiles do not like extra flags being given to make.
EXTRA_OEMAKE_pn-${PN} = ""
CFLAGS_pn-${PN} = ""
CPPFLAGS_pn-${PN} = ""
CXXFLAGS_pn-${PN} = ""
LDFLAGS_pn-${PN} = ""

export ARCH = "${TARGET_ARCH}"
export CROSS_COMPILE = "${TARGET_PREFIX}"

uses_modules () {
	grep -q -i -e '^CONFIG_MODULES=y$' "${O}/.config"
}

do_configure () {
	mkdir -p ${STAGING_KERNEL_DIR}
	rm -rf ${STAGING_KERNEL_DIR}/*
	rm -f ${O}
	ln -s ${STAGING_KERNEL_DIR} ${O}
	__do_clean_make
	oe_runmake ${KERNEL_DEFCONFIG} O=${O}
}

do_menuconfig() {
        export TERMWINDOWTITLE="${PN} Configuration"
        export SHELLCMDS="make ARCH=${ARCH} menuconfig O=${O}"
        ${TERMCMDRUN}
        if [ $? -ne 0 ]; then
                oefatal "'${TERMCMD}' not found. Check TERMCMD variable."
        fi
}

do_menuconfig[nostamp] = "1"
addtask menuconfig after do_configure

do_savedefconfig() {
	oe_runmake savedefconfig O=${O}
	mv ${O}/defconfig ${S}/arch/${ARCH}/configs/${KERNEL_DEFCONFIG}
}

addtask savedefconfig after do_configure

do_compile () {
	oe_runmake ${KERNEL_IMAGETYPE} O=${O}
	uses_modules && oe_runmake modules O=${O}
}

__do_clean_make () {
	[ -d ${O} ] && oe_runmake mrproper O=${O}
	oe_runmake mrproper
}

KERNEL_VERSION = "${@get_kernelversion('${O}')}"
do_install () {	
	# Files destined for the target
	install -d ${D}/boot
	for f in System.map Module.symvers vmlinux; do
		install -m 0644 ${O}/${f} ${D}/boot/${f}-${KERNEL_VERSION}
	done
	install -m 0644 ${O}/arch/${TARGET_ARCH}/boot/${KERNEL_IMAGETYPE} \
		${D}/boot/${KERNEL_IMAGETYPE}-${KERNEL_VERSION}
	install -m 0644 ${O}/.config ${D}/boot/config-${KERNEL_VERSION}
	uses_modules && oe_runmake modules_install O=${O} INSTALL_MOD_PATH=${D}

	# Files needed for staging
	install -d ${D}${KDIR}/usr
	oe_runmake headers_install O=${D}${KDIR}
	oe_runmake ${KERNEL_DEFCONFIG} O=${D}${KDIR}
	uses_modules && oe_runmake modules_prepare O=${D}${KDIR}
    	cp -rf ${D}/* ${STAGING_DIR_TARGET}
}


