#!/bin/bash
#
# An example of how to create tiny-alsa statically for different architectures
# At the time of writing, it uses a quick workaround in the forked git@github.com:ronpscg/tinyalsa.git  project, rather than adding a patch here.
# That workaround prevents building non-static builds.
#
# If I get to it later, I will show builds with all supported build-systems (except for the AOSP, but maybe I can use it as a nice out of tree NDK demonstration...) So far, for whatever reason, cross-building with Meson statically did not work.
#
# Used to accompany The PSCG's training/Ron Munitz's talks
#
# Notes: I did not update any of the comments, I started this project as a copy of the kexec-tools static build project. You are welcome to udpate the comments and send a Pull Request
# 	 I did remove the multilib stuff I had in the other builds to make the code here shorter
#
: ${SRC_PROJECT=$(readlink -f ./tinyalsa)}

# ./configure vs. make:
# Could use --prefix in configure, but it's working with another folder, and we don't really want the entire set of tools here.
# In addition the install-strip target does not seem to be implemented, and even with --prefix it tries to do some udev stuff which is wrong
# so there is no point in it
#
# Instead, in this particular case,  # make -j16 DESTDIR=... install-strip does the job, without the --prefix in configure.
# It does suffer from the same errors, but at least you don't need to go thorugh an additional stripping phase
# We present two versions for you to experiment with. The one with the find could be more accurate, as some of the executables are
# shell script, so obviously they are not to be stripped.
#
# More notes (the project started as a copying of the e2fsprogs and dosfstools repos I made, do it may apply to them as well) (the lines above are ontouched copying of them)
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# I built on an Ubuntu 25.04, as where I built the previous versions of dosfstool and e2fsprogs  on an earlier version. Since I only care about the binaries,
# I don't put too much work into it, and I didn not check what is the build status of the other projects.  What I noticed for now, in this project is:
# - i386-...- toolchain is not available, but rather i686 (It is very possible that for the other projects I built on non x86_64 host and/or installed my own toolchains
# - make install-strip target does not work here. Maybe it applies for the rest as well
#     
#
# More configure and make flags - kexec-tools specific:
# ----------------------------------------------
#
# Building statically with the default flags results in an zstd linkage error. 
#    "/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/14/../../../x86_64-linux-gnu/libzstd.a(zstd_decompress.o): in function ZSTD_isFrame': (.text+0x1430): multiple definition of ZSTD_isFrame';"
# Therefore, zstd is not allowed in this version (could resolve it, it doesn't really matter so won't do it. If you see it you are willing to fix it and submit the patch)
#
# install-strip does not work. I didn't look into the makefiles. Didn't bother more
: ${MORE_CONFIGURE_FLAGS=" --without-zstd "}
: ${MORE_TUPPLES=""} 

#
# $1: build directory
#
build_without_installing() (
	mkdir $1
	cd $1
	make -C $SRC_PROJECT LDFLAGS=-static -j$(nproc) || exit 1
	find . -executable -not -type d | xargs ${CROSS_COMPILE}strip -s
)


#
# $1: build directory
# $2: install directory
#
# Builds with make
#
build_with_installing() (
	set -euo pipefail # will only apply to this subshell
	make -C $SRC_PROJECT clean # no out of tree builds here
	installdir=$(readlink -f $2)
	#mkdir $1 # You must create the build and install directories. make will not do that for you
	#cd $1
	make -C $SRC_PROJECT LDFLAGS=-static CROSS_COMPILE=$CROSS_COMPILE -j$(nproc) DESTDIR=$installdir install 

	find $installdir/usr/local/bin -executable -not -type d | xargs ${CROSS_COMPILE}strip -s


	make -C $SRC_PROJECT clean # no out of tree builds here
)


# This example builds for several tuples
# The function above can be used from outside a script, assuming that the CROSS_COMPILE variable is set
# It may however need more configuration if you do not build for gnulibc
build_for_several_tuples() {
	local failing_tuples=""
	for tuple in x86_64-linux-gnu aarch64-linux-gnu riscv64-linux-gnu arm-linux-gnueabi arm-linux-gnueabihf i686-linux-gnu loongarch64-linux-gnu $MORE_TUPPLES ; do
	#for tuple in i686-linux-gnu $MORE_TUPPLES ; do
	#for tuple in $MORE_TUPPLES aarch64-linux-gnu ; do
		echo -e "\x1b[35mConfiguring and building $tuple\x1b[0m"
		export CROSS_COMPILE=${tuple}- # we'll later strip it but CROSS_COMPILE is super standard, and autotools is "a little less standard"
		build_with_installing $tuple-build $tuple-install 2> err.$tuple || failing_tuples="$failing_tuples $tuple"
	done

	if [ -z "$failing_tuples" ] ; then
		echo -e "\x1b[32mDone\x1b[0m"
	else
		echo "\x1b[33mDone\x1b[0m You can see errors in $(for x in $failing_tuples ; do echo err.$x ; done)"
	fi
}

fetch() (
	# riscv64: important: the latest tag as per the time of writing it, v2.0.31" DOES NOT SUPPORT building for riscv64.
	# the last time this was updated, master was at commit 8322826fa7b04a5c0f023eda78d69dd1413a1412 
	# it is not explicitly mentioned, because it could be rebased
	: ${CHECKOUT_COMMIT=""} # -b v2.0.31 

	#git clone https://github.com/alsa-project/alsa-utils.git
	# change to https:// ... this fork only has one change in src/Makfile over master
	git clone git@github.com:ronpscg/tinyalsa.git
)

main() {
	fetch || exit 1
	build_for_several_tuples
}

main $@
