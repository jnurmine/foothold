```  
  _____              __  .__           .__       .___  
_/ ____\____   _____/  |_|  |__   ____ |  |    __| _/  
\   __\/  _ \ /  _ \   __\  |  \ /  _ \|  |   / __ |   
 |  | (  <_> |  <_> )  | |   Y  (  <_> )  |__/ /_/ |   
 |__|  \____/ \____/|__| |___|  /\____/|____/\____ |   
                              \/                  \/  
```
A dual ARM A53 QEMU dev board for a kernel playground, built with Yocto.

Copyright (c) 2018,2019 Jani Nurminen \<slinky at iki dot-goes-here fi\>
Licensed under the MIT License.


This is meant to be a Linux kernel exploration tool.

The kernel is in a separate Git repository. You can build your kernel manually
on the side or within Yocto. The rootfs will be built as part of the image.

The kernel is off-tree and the latest commit in the given branch gets picked
up. This way you can avoid making .patch files all the time, just hack in your
dev branch. If you need a patch, squash your commits when you are done.

The kernel is not a part of the image. This way it's easier to swap the rootfs
and use different kernel versions for comparison etc.

## Requirements

A host capable of running [Yocto](https://www.yoctoproject.org/). In practise
this is a function of your patience. SSD and a somewhat high-end CPU with
plenty of RAM are recommended. Expect to use 40-50 GiB of disk space.

## Installation

Download source code:
```
  git clone --recursive https://github.com/jnurmine/foothold.git
```

Then you should run `make prepare`. This checks out the stable kernel from
kernel.org and creates a branch which will be used later.

Note: by default 5.1.16 is used. This is specified by the
KERNEL_BRANCHOFF_VERSION in the Makefile.

## Simple Usage

```
   make prepare
   make image
   make runqemu
```

To debug the kernel from start, tell QEMU to wait for gdb connection at
QEMU_GDB_PORT (default: 37777):

```
  make runqemu-gdb
  gdb -ex 'b start_kernel' -ex 'tar rem localhost:37777'
```

To do maintenance tasks in full Bitbake environment, use:

```
  make shell
```

Then you can issue commands like `bitbake somepackage -c compile`.
Use "exit" to get out of that shell.

## (Some) Batteries Included

I originally made this to play with eBPF and kernel internals in general, so
the kernel is configured with eBPF enabled and some relevant tools are included
(e.g. ply, perf).

Here's one of the ply examples which aggregates the size of reads and quantizes
the results into the bins of an exponential histogram. While ply is running, run
some random reads in the background through an SSH connection to the guest (not
shown below):

```
root@foothold:~# ply 'kretprobe:__arm64_sys_read { @["size"] = quantize(retval); }'
ply: active
^Cply: deactivating

@:
{ size    }: 
                 < 0           6 ┤▎                               │
        [   0,    1]         187 ┤███████▍                        │
        [   2,    3]          15 ┤▋                               │
        [   4,    7]           4 ┤▏                               │
        [   8,   15]          99 ┤███▉                            │
        [  16,   31]          66 ┤██▋                             │
        [  32,   63]          66 ┤██▋                             │
        [  64,  127]         100 ┤████                            │
        [ 128,  255]         153 ┤██████▏                         │
        [ 256,  511]          46 ┤█▉                              │
        [ 512,   1k)          42 ┤█▋                              │
        [  1k,   2k)           1 ┤                                │
        [  2k,   4k)          21 ┤▉                               │

root@foothold:~#
```

For the full list of tools, see foothold-image.bb.

Note that the 64-bit ARM syscalls begin with __arm64_sys*.

KGDB is also configured, and you can hook up QEMU to gdb running on the host
side.

## More Detailed Usage

### make prepare

Run `make prepare` to download the kernel tree.
This clones the stable kernel into kernel/linux.git and creates a branch called
"dev/foothold" from the indicated starting point (branch or tag).

If you want to use your own kernel, please go ahead. The only requirement is
that the kernel git is in a branch defined by KERNEL_BRANCH, and that the
version is properly set. See the Makefile. By default the branch is
"dev/foothold".

The Linux license file contents changed at kernel version 4.16 and this is
auto-detected and set properly within the recipe. For this reason you need to
manually give the correct kernel version to use as a branch-off point.

The relevant variables in the Makefile are:
```
  KERNEL_BRANCHOFF_VERSION
  KERNEL_BRANCH
```

The KERNEL_BRANCHOFF_VERSION is the Kernel version from which the dev/foothold
is made off, by default it is 5.1.16.


### make image

Run "make image" to build the kernel image and the root file system. When you
kick this off, go for lunch or something, as it takes a while.


### make runqemu

This starts the QEMU with your kernel and rootfs. Note: the username is root
and there is no password.

CAUTION: an ssh server is enabled in the image!

Since configuring TAP networking is a privileged operation, you'll probably
have to type your password when running `make runqemu`.


### make runqemu-gdb

Run emulator, but wait until a debugger attaches. After the QEMU starts (no output), start gdb.
For example:

```
  gdb-multiarch `pwd`/images/vmlinux \
    -ex 'b start_kernel' \
    -ex 'tar rem localhost:37777'
```

Start with "cont", and you'll hit "start_kernel".
Make sure your "target remote localhost:xxxxx" matches the QEMU_DBG_GDB_PORT if
you changed it.

The relevant variables in the Makefile are:

```
   QEMU_GDB_PORT
```


### Running Your Kernel

If there's no fancy stuff, run:
```
  make runqemu
```

If your kernel is off-tree and you built it yourself:
```
  KERNEL=/path/to/Image.bin make runqemu
```

To override the DTB you can call something like:
```
  DEVICE_TREE=/path/to/mydtb.dtb make runqemu
```

NOTE: the paths to KERNEL and DEVICE_TREE must be absolute.

TIP: To run QEMU manually, you can manually re-run the same command which
results after "make runqemu".


## FAQ

**Q:** Why?  
**A:** I wanted to play with eBPF, to run gdb and investigate various new and old
things in the Linux kernel. Furthermore, I didn't want to run bleeding edge
stuff on my desktop machine and I didn't have a small HW like Raspberry Pi
handy. Earlier I had used a manual setup with QEMU and a basic rootfs built
with some scripts but that had become rather cumbersome. Then I thought "hey,
this is silly, why not automatize all this with Yocto", and lo and behodl, here
is the meta-foothold.

**Q:** How do I make and deploy kernel changes?  
**A:** Two examples follow:  

1. Just modify your kernel git repository and check in new things to the
KERNEL_BRANCH (dev/foothold). Then re-build your kernel with "make kernel".
2. Alternatively, cross-compile your off-tree kernel and deploy
it to QEMU using your rootfs, by overriding the KERNEL environment variable.
See below regarding the configuration. This way might be faster unless you want
to run bitbake commands directly.

For kernel modules, again, two examples:
1. Build under yocto with "make kernel" and "make image".
2. Cross-compile within the off-tree kernel, and just ssh them over. Yocto can
only include kernel modules in the rootfs if Yocto built the kernel. See below
regarding the configuration.

You can also provide the rootfs over NFS, etc.

**Q:** I want to cross-compile my off-tree kernel, what should I do with the kernel
configuration?  
**A:** Because the meta-foothold brings in various tools and debugging features,
the default kernel configuration needs to be changed. I don't want to maintain
my own kernel branch for just the defconfig, so the kernel configuration at:
```
  arch/arm64/configs/defconfig
```
is overridden by the recipe file:
```
  meta-foothold/linux-foothold/linux-foothold/defconfig
```
When the kernel configuration is changed, either copy the new defconfig over
the recipe defconfig file, or set up a symlink or something.
If you are cross-compiling, you'd want to start with the recipe defconfig, in
this case just copy the recipe defconfig over the kernel tree defconfig.
To update the defconfig in the recipe, overwrite it with:
```
   build/tmp/work-shared/fh-arm64/kernel-build-artifacts/.config
```
You should not need to modify linux-foothold.bb for this.

**Q:** I want to add some new tool.  
**A:** Great, add it to IMAGE_INSTALL_append in foothold-image.bb. If there's no
recipe for it, write your own and please submit a patch.
NOTE about kernel headers: you'll be using a non-Yocto kernel, and therefore
the kernel headers need to come from your kernel, and not the (presumably
older) kernel shipped with Yocto. This should be as easy as
```
  require conf/off-tree-headers.inc
```
See the ply_2.1.0.bb for example. That is a good example of a program which
does not work with e.g. 4.19 if built with the Yocto 4.15.7 kernel headers; for
the case of ply, if there's a header mismatch you will get -EINVAL from bpf(2)
when loading the eBPF program. You can see what ply thinks of the kernel
version with "ply -v".

**Q:** Where is the cross-compiler?  
**A:** Not here, no SDK yet, sorry. You'll have to get it from elsewhere.

**Q:** You are teh suck, there is a better way to do x, y and z.  
**A:** Please submit a patch! The way it is now works for me and my workflow.
