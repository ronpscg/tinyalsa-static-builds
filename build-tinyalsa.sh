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
: ${TUPLES="x86_64-linux-gnu aarch64-linux-gnu riscv64-linux-gnu arm-linux-gnueabi arm-linux-gnueabihf i686-linux-gnu loongarch64-linux-gnu"}
: ${MORE_TUPLES="alpha-linux-gnu arc-linux-gnu m68k-linux-gnu mips64-linux-gnuabi64 mips64el-linux-gnuabi64 mips-linux-gnu mipsel-linux-gnu powerpc-linux-gnu powerpc64-linux-gnu powerpc64le-linux-gnu sh4-linux-gnu sparc64-linux-gnu s390x-linux-gnu"}
: ${SRC_PROJECT=$(readlink -f ./tinyalsa)}
: ${GIT_REF=master}

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
	make -C $SRC_PROJECT LDFLAGS=-static CROSS_COMPILE=$CROSS_COMPILE -j$(nproc) DESTDIR=$installdir install || { echo -e "\x1b[31mFailed to build/install for $installdir\x1b[0m" ; exit 1 ; }

	find $installdir/usr/local/bin -executable -not -type d | xargs ${CROSS_COMPILE}strip -s || { echo -e "\x1b[31mFailed to strip for $installdir\x1b[0m" ; exit 1 ; }


	make -C $SRC_PROJECT clean # no out of tree builds here
)


# This example builds for several tuples
# The function above can be used from outside a script, assuming that the CROSS_COMPILE variable is set
# It may however need more configuration if you do not build for gnulibc
build_for_several_tuples() {
	local failing_tuples=""
        for tuple in $TUPLES $MORE_TUPLES ; do
		echo -e "\x1b[35mConfiguring and building $tuple\x1b[0m"
		export CROSS_COMPILE=${tuple}- # we'll later strip it but CROSS_COMPILE is super standard, and autotools is "a little less standard"
		build_with_installing $tuple-build $tuple-install 2> err.$tuple || failing_tuples="$failing_tuples $tuple"
	done

	if [ -z "$failing_tuples" ] ; then
		echo -e "\x1b[32mDone\x1b[0m"
	else
		echo -e "\x1b[33mDone\x1b[0m You can see errors in $(for x in $failing_tuples ; do echo err.$x ; done)"
	fi
}

fetch() (
	[ "$1" = "dontfetch" ] && return
	#git clone https://github.com/alsa-project/alsa-utils.git
	# change to https:// ... this fork only has one change in src/Makefile over master
	git clone git@github.com:ronpscg/tinyalsa.git -b $GIT_REF
)

main() {
	fetch $@ || exit 1
	build_for_several_tuples
}

main $@
