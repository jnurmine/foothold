# SPDX-License-Identifier: MIT

python foothold_off_tree_headers() {
    # Use our kernel headers instead of the Yocto ones for tools which need
    # kernel headers
    depends_on_kernel = "virtual/kernel" in d.getVar("DEPENDS")
    if not depends_on_kernel:
        return

    d.appendVarFlag('do_configure', 'depends', " virtual/kernel:do_populate_sysroot")
    d.appendVar("TOOLCHAIN_OPTIONS",
        " -I${COMPONENTS_DIR}/${MACHINE_ARCH}/${PREFERRED_PROVIDER_virtual/kernel}/off-tree-headers/include")
    d.appendVar("DEPENDS", " foothold-headers")

    bb.debug(2, "using off-tree-headers")
}

addhandler foothold_off_tree_headers
foothold_off_tree_headers[eventmask] = "bb.event.RecipePreFinalise"

