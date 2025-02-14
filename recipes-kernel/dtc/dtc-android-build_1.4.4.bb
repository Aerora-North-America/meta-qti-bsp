require dtc.inc

LIC_FILES_CHKSUM = "file://GPL;md5=94d55d512a9ba36caa9b7df079bae19f \
		    file://libfdt/libfdt.h;beginline=3;endline=52;md5=fb360963151f8ec2d6c06b055bcbb68c"

SRCREV = "bb8b81602c1d27e0fda0e5139b502010a624e447"

S = "${WORKDIR}/git"

BBCLASSEXTEND = "native nativesdk"

# libfdt has version as part of name like lbfdt-<version>.so instead of
# .so.<version>, so reorder and repackage to avoid QA issues.
FILES_${PN} += "${libdir}/*-${PV}.so"
FILES_SOLIBSDEV = "${libdir}/libdft.so"
