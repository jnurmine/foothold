# Foothold
# Copyright (c) 2018,2019 Jani Nurminen <slinky@iki.fi>
# MIT License, see LICENSE
# SPDX-License-Identifier: MIT
#
# A dual ARM A53 QEMU dev board for a kernel playground, built with Yocto.
#
# This is meant to be a Linux kernel exploration tool.
#
# Quickstart (check README for more):
#
# The kernel is in a Git repository, you can build your kernel manually on the
# side or within Yocto. The rootfs will be built as part of the final image.
#
# Simple usage:
#   make prepare
#   make image
#   make runqemu
#
# To debug the kernel from start, tell QEMU to wait for gdb connection at
# QEMU_GDB_PORT (default: 37777):
#   make runqemu-gdb
#   gdb -ex 'b start_kernel' -ex 'tar rem localhost:37777'
#
# To do maintenance tasks in full Bitbake environment, use:
#   make shell
#
# Use "exit" to get out of that shell.

ROOT_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

DISTRO = foothold
MACHINE = fharm64
IMAGE = foothold-image

# GDB port
QEMU_GDB_PORT ?= 37777

# The Linux kernel knobs
KERNEL_GIT_DIR ?= $(ROOT_DIR)/kernel
KERNEL_BRANCHOFF_VERSION ?= 5.4.1
KERNEL_BRANCH ?= dev/foothold

BUILD_DIR ?= $(ROOT_DIR)/build
POKY_DIR ?= $(ROOT_DIR)/poky
DL_DIR ?= $(ROOT_DIR)/downloads
TGZ_DIR ?= $(ROOT_DIR)/tgz

IMAGE ?= $(DISTRO)-image

LOCAL_CONF = $(BUILD_DIR)/conf/local.conf
SITE_CONF = $(BUILD_DIR)/conf/site.conf
BBLAYERS_CONF = $(BUILD_DIR)/conf/bblayers.conf
CONF_FILES = $(LOCAL_CONF) $(SITE_CONF) $(BBLAYERS_CONF)

BBLAYERS = $(POKY_DIR)/meta \
	   $(POKY_DIR)/meta-poky \
	   $(POKY_DIR)/meta-yocto-bsp \
	   $(ROOT_DIR)/meta-openembedded/meta-oe \
	   $(ROOT_DIR)/meta-foothold

define HELP
Usage: $(MAKE) [target] [variables ...]
Targets:
	prepare		One-time preparation to fetch the kernel sources
	image		Build the image (incl. kernel)
	runqemu		Run image under QEMU. Hit Ctrl-A X to exit
	runqemu-gdb	Run image under QEMU, wait for GDB to attach (port $(QEMU_GDB_PORT))
	shell		Bitbake shell. Use "exit" to exit
	kernel		Build the kernel only
	clean		Remove BUILD_DIR


Variables:
	DL_DIR		Alternative location for upstream downloads ($(DL_DIR))

	You can provide these as arguments to "make" or in a file "site.conf", for example:
	  DL_DIR = "/mnt/data/downloads"
endef
export HELP
help:
	@echo "$$HELP"

$(LOCAL_CONF):
	@mkdir -p $(dir $@) $(DL_DIR)
	@echo '' > $@
	@echo 'MACHINE ?= "$(MACHINE)"' >> $@
	@echo 'DISTRO ?= "$(DISTRO)"' >> $@
	@echo 'DL_DIR ?= "$(DL_DIR)"' >> $@
	@echo 'COMPATIBLE_MACHINE_$(MACHINE) = "$(MACHINE)"' >> $@
	@echo '' >> $@
	@echo '# All gits are local, http/https are to be in tarballs' >> $@
	@echo 'PREMIRRORS_prepend = "\ ' >> $@
	@echo 'git://.*/(.*) git://$(KERNEL_GIT_DIR)/\1 \' >> $@
	@echo 'http://.*/(.*) file://$(TGZ_DIR)/\1 \' >> $@
	@echo 'https://.*/(.*) file://$(TGZ_DIR)/\1 "' >> $@
	@echo '' >> $@
	@echo '# Use systemd for init' >> $@
	@echo 'DISTRO_FEATURES_append = " systemd"' >> $@
	@echo 'VIRTUAL-RUNTIME_init_manager = "systemd"' >> $@
	@echo 'DISTRO_FEATURES_BACKFILL_CONSIDERED = "sysvinit"' >> $@
	@echo 'VIRTUAL-RUNTIME_initscripts = ""' >> $@
	@echo '' >> $@
	@echo 'LINUX_VERSION = "$(KERNEL_BRANCHOFF_VERSION)"' >> $@
	@echo 'FH_KBRANCH = "$(KERNEL_BRANCH)"' >> $@
	@echo 'MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS += "kernel-modules"' >> $@
	@echo '' >> $@
	@echo '# PR server' >> $@
	@echo 'PRSERV_HOST = "localhost:0"' >> $@
	@echo '' >> $@
	@echo 'KERNEL_GIT_DIR = "$(KERNEL_GIT_DIR)"' >> $@
	@echo '' >> $@
	@echo 'OE_TERMINAL_CUSTOMCMD = "tmux"' >> $@
	@echo 'OE_TERMINAL = "xterm"' >> $@
	@echo '' >> $@


$(SITE_CONF): $(wildcard $(ROOT_DIR)/site.conf)
	@for f in $^; do cp $$f $@; done

$(BBLAYERS_CONF):
	@mkdir -p $(dir $@)
	@echo 'POKY_BBLAYERS_CONF_VERSION = "2"' > $@
	@echo 'BBPATH = "$${TOPDIR}"' >> $@
	@echo 'BBFILES ?= ""' >> $@
	@for L in $(BBLAYERS); do if [ -d "$$L" ]; then echo "BBLAYERS += \"$$L\"" >> $@; fi; done

prepare:
ifneq (,$(wildcard $(KERNEL_GIT_DIR)))
	@echo "Already prepared, remove $(KERNEL_GIT_DIR) and re-run"
	@exit 1
endif
	@echo "One-time preparation: cloning mainline kernel to $(KERNEL_GIT_DIR)/linux.git"
	@mkdir $(KERNEL_GIT_DIR)
	@git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git $(KERNEL_GIT_DIR)/linux.git
	@echo "Checking out $(KERNEL_BRANCHOFF_VERSION)"
	@git -C $(KERNEL_GIT_DIR)/linux.git checkout -b $(KERNEL_BRANCH) "v$(KERNEL_BRANCHOFF_VERSION)"
	@rm -f images
	@ln -s build/tmp/deploy/images/$(MACHINE) images
	@echo "One-time prepare done!"

define oe-init-build-env
OEROOT=$(POKY_DIR) . $(POKY_DIR)/oe-init-build-env $(BUILD_DIR)
endef

kernel: $(CONF_FILES)
	$(call oe-init-build-env); bitbake virtual/kernel

image: $(CONF_FILES)
	$(call oe-init-build-env); bitbake $(IMAGE)

runqemu: image
	$(call oe-init-build-env); runqemu nographic $(IMAGE)

runqemu-gdb: image
	$(call oe-init-build-env); runqemu nographic $(IMAGE) qemuparams="-gdb tcp::$(QEMU_GDB_PORT) -S"

shell:
	$(call oe-init-build-env); exec $(SHELL)

clean:
	-rm -rf $(BUILD_DIR)

.PHONY: prepare image runqemu runqemu-gdb kernel shell clean $(CONF_FILES)
