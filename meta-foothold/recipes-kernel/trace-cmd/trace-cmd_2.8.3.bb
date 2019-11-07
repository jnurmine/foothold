# Copyright (C) 2019 Slinky <slinky@iki.fi>
# Released under the MIT license (see COPYING.MIT for the terms)

SUMMARY = "Ftrace tool"
DESCRIPTION = "Tool to interact with Ftrace, Linux kernel internal tracer"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=873f48a813bded3de6ebc54e6880c4ac \
                    file://tracecmd/trace-cmd.c;beginline=1;endline=1;md5=50d2ba0afecd20f74c12a4bdbcfcfe61"

PR = "r0"
PV = "2.8.3-git${SRCPV}"

inherit pkgconfig

SRC_URI = "git://git.kernel.org/pub/scm/linux/kernel/git/rostedt/trace-cmd.git;protocol=git;branch=trace-cmd-stable-v2.8"
SRCREV = "138c70106835ee0f05879e7f2f46bca8dae7ca99"
S = "${WORKDIR}/git"

PROVIDES = "trace-cmd"

EXTRA_OEMAKE = "'prefix=${prefix}'"

do_install() {
	oe_runmake prefix="${prefix}" DESTDIR="${D}" install
}
