inherit autotools-brokensep

DESCRIPTION = "Safe integer operation library for C"

LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

FILESPATH =+ "${WORKSPACE}/external:"

SRC_URI   = "file://safe-iop"
SRC_URI  += "file://autotools.patch"

S = "${WORKDIR}/safe-iop"
