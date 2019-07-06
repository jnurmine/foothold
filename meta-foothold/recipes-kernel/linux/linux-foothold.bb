# SPDX-License-Identifier: MIT

# Foothold uses a kernel external to Yocto.
#
# This recipe also exports the headers for tools to use instead of the Yocto
# headers, since the chosen kernel might mismatch with whatever Yocto provides.
# To use the new headers, require conf/off-tree-headers.inc
#
# The latest commit in the given kernel branch is used.
#
# The defconfig used for configuration is part of this recipe. The base used
# was 4.19, but olddefconfig should work for newer kernels too.
#
# NOTE: The SRC_URI with AUTOREV does not work with PREMIRRORS and file:// used
# for the git-repo, so we have to have the absolute path to the repository.
# Everything before the first "/" after the protocol definition seems to be
# skipped, and PREMIRRORS won't be checked.
#

require recipes-kernel/linux/linux-yocto.inc

SECTION = "kernel"
DESCRIPTION = "Linux Kernel for Foothold"

# The license file changed at 4.16.
# Detect use of older versions of the kernel.
#
LICENSE = "GPLv2"

LIC_FILES_CHKSUM = "${@ \
    "file://COPYING;md5=bbea815ee2795b2f4230826c0c6b8814" if \
    ((int(d.getVar("LINUX_VERSION").split(".")[0]) == 4) and \
    (int(d.getVar("LINUX_VERSION").split(".")[1]) >= 16)) or \
    (int(d.getVar("LINUX_VERSION").split(".")[0]) >= 5) \
    else \
    "file://COPYING;md5=d7810fab7487fb0aad327b76f1be7cd7"}"

# External git setup
#
KBRANCH     = "${FH_KBRANCH}"
SRCREV_pn-linux-foothold = "${AUTOREV}"
KMACHINE    = "${MACHINE}"
PV          = "${LINUX_VERSION}+git${SRCPV}"
SRC_URI     = "git://${KERNEL_GIT_DIR}/linux.git;protocol=file;nocheckout=0;usehead=1;rebaseable=1;nobranch=1;branch=${KBRANCH}"

# Misc stuff
#
LINUX_VERSION_EXTENSION_append = "-fh"
COMPATIBLE_MACHINE = "${MACHINE}"
PROVIDES_${PN} += "virtual/kernel"

KBUILD_BUILD_USER = "root"
KBUILD_BUILD_HOST = "foothold"

PR = "r2"

# Devicetrees, also make sure QEMU can find our devicetree file
#
KERNEL_DEVICETREE += "arm/vexpress-v2f-1xv7-ca53x2.dtb"
DTB_FILE = "vexpress-v2f-1xv7-ca53x2.dtb"
QB_DTB = "${DTB_FILE}"
DEVICE_TREE = "${DTB_FILE}"

# Base kernel configuration, just copy over the config we have,
# and don't let Yocto inject ANY cleverness to the process.
#
# There are other ways to do this but this works.
#
KERNEL_CONFIG_COMMAND = "oe_runmake_call -C ${S} O=${B} olddefconfig"
KBUILD_DEFCONFIG = "defconfig"

do_configure_prepend () {
    cp -f ${THISDIR}/${PN}/defconfig ${B}/.config
}

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"
SRC_URI_append = " file://defconfig"

# We don't have this file, but do have printk in defconfig
KERNEL_FEATURES_remove = " features/debug/printk.scc"

# We don't want these fragments either
KERNEL_FEATURES_remove += " features/kernel-sample/kernel-sample.scc"

# We are completely overriding the kernel with a potentially newer one.
# This means the kernel headers will differ and if nothing is done, e.g.
# LINUX_VERSION_CODE will match that of Yocto, not our kernel. For some
# bleeding edge kernel tools this is meaningful. We can't use Yocto headers, so
# export our kernel headers here, each recipe must pull in the right header
# includes at the right time.
do_install_append() {
    make headers_install INSTALL_HDR_PATH="${D}/off-tree-headers"
}

sysroot_stage_all_append() {
    sysroot_stage_dir "${D}/off-tree-headers" "${SYSROOT_DESTDIR}/off-tree-headers"
}

INSANE_SKIP_${PN} += "installed-vs-shipped"
FILES_foothold-headers += "${D}/off-tree-headers"
PROVIDES += "foothold-headers"
