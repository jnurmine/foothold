# SPDX-License-Identifier: MIT

# Use our kernel headers instead of the Yocto ones for tools which need
# kernel headers
do_configure[depends] += "virtual/kernel:do_populate_sysroot"
TOOLCHAIN_OPTIONS_append = " -I${COMPONENTS_DIR}/${MACHINE_ARCH}/${PREFERRED_PROVIDER_virtual/kernel}/off-tree-headers/include"

