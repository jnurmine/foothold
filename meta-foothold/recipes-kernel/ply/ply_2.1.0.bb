# SPDX-License-Identifier: MIT

SUMMARY = "Light-weight dynamic tracer using eBPF"
HOMEPAGE = "https://wkz.github.io/ply"
DESCRIPTION = "A light-weight dynamic tracer for Linux that leverages the kernel's BPF VM in concert with kprobes and tracepoints to attach probes to arbitrary points in the kernel"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

SRC_URI = "git://github.com/wkz/ply"
SRCREV = "4fca51618bf8648320965f1b4b44dd84274e5626"

inherit autotools

# Build straight in the S, or bison can't find the grammar.y...
S = "${WORKDIR}/git"
B = "${S}"

DEPENDS = "bison-native flex-native foothold-headers virtual/kernel"

PROVIDES = "ply"

SRC_URI += "file://0001-Don-t-build-man-pages.patch"

require conf/off-tree-headers.inc
