BASEMACHINE ?= "qcs40x"
require conf/machine/include/basemachine.inc

SOC_FAMILY ?= "qcs405"
include conf/machine/include/soc-family.inc

DEFAULTTUNE ?= "aarch64"
include conf/machine/include/arm/arch-armv8a.inc

PREFERRED_PROVIDER_virtual/kernel = "linux-msm"
PREFERRED_VERSION_linux-msm ?= "4.14"
PREFERRED_VERSION_linux-msm-headers ?= "4.14"

PAGE_SIZE ?= '4096'

EXTRA_IMAGECMD ?= "-N 2048"

MACHINE_MNT_POINTS = " \
    /bt_firmware \
    /dsp \
    /firmware \
    /overlay \
    /persist \
"

# Sizes for EXT4 (in bytes)
SYSTEM_SIZE_EXT4 ?= "681574400"
USERDATA_SIZE_EXT4 ?= "4831838208"

# Formats of root filesystem images
IMAGE_FSTYPES += "ext4"
