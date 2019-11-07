# SPDX-License-Identifier: MIT

DESCRIPTION = "Rootfs image for foothold"
LICENSE = "GPLv2+"

require recipes-core/images/core-image-minimal.bb

PROVIDES = "${PV}"

IMAGE_FEATURES_append = " package-management"

EXTRA_IMAGE_FEATURES = "empty-root-password"
EXTRA_IMAGE_FEATURES_append = " allow-empty-password"
EXTRA_IMAGE_FEATURES_append = " ssh-server-dropbear"
EXTRA_IMAGE_FEATURES_append = " allow-root-login"
EXTRA_IMAGE_FEATURES_append = " dbg-pkgs"

IMAGE_INSTALL_append = " base-files"

IMAGE_INSTALL_append = " trace-cmd"
IMAGE_INSTALL_append = " pciutils"
IMAGE_INSTALL_append = " ethtool"
IMAGE_INSTALL_append = " strace"
IMAGE_INSTALL_append = " perf"
IMAGE_INSTALL_append = " ply"
IMAGE_INSTALL_append = " dtc"

# Don't include kernel in rootfs
RDEPENDS_kernel-base = ""

# If you want the kernel to be built every time when the image is built, use:
# DEPENDS_${PN} = "virtual/kernel"
# NOTE: it might not always make sense, e.g. if manually hacking in the
# off-tree kernel and then doing make runqemu, you'll not want the kernel to be
# re-built.

COMPATIBLE_MACHINE = "${MACHINE}"

