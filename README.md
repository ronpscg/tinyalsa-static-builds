# tiny-alsa static prebuilts (linked with glibc)

**Note:** I modified `tiny-alsa` in a hacky way so that I could build statically with GNU make. Other build systems may be used in the future, but not now.
Perhaps I will leave this as yet another exercise for an upcoming *Embedded Linux* course (after the students create the cross compilers for uclibc/bionic/musl/...)

## Context/Motivation:
Allow playing (and recording) audio in a busybox based ramdisk (or any other small one).

As opposed to the other repos, the build script comments and this README.md file are not updated or detailed.

## Building
You can speficy the `TUPLES` and `MORE_TUPLES` variables to specify your build tuples, or otherwise modify the code. You can provide `dontfetch` to avoid cloning the tool from git if you already built it at least once.
```bash
./build-tinyalsa.sh
```

## Build status
Known to build properly:
```
x86_64-linux-gnu aarch64-linux-gnu riscv64-linux-gnu arm-linux-gnueabi arm-linux-gnueabihf i686-linux-gnu loongarch64-linux-gnu
alpha-linux-gnu arc-linux-gnu m68k-linux-gnu mips64-linux-gnuabi64 mips64el-linux-gnuabi64 mips-linux-gnu mipsel-linux-gnu powerpc-linux-gnu powerpc64-linux-gnu powerpc64le-linux-gnu sh4-linux-gnu sparc64-linux-gnu s390x-linux-gnu
```

Known to not build properly:\
None at the moment

## Usage (very superficial)
You must have direct hardware access, and you must be aware that there is no hwplug so what the hardware supports, is what is supported. You could use `sox` to reencode,
if you cannot open some files.

Usage (but note the gotchas below):
```
# ./tinycap bla.wav
Capturing sample: 2 ch, 48000 hz, 16 bit
Captured 226353 frames
# ./tinyplay bla.wav 
playing 'bla.wav': 2 ch, 48000 hz, 16-bit signed PCM
Played 901360 bytes. Remains 0 bytes.
```

Gotchas:
If you just start up - it is very possible that your controls will be at volume zero. So you need to figure out what the controls are, and set them accordingly.
This is why I am reluctant to have all of the binaries statically - it is a huge waste in this particular case. But reducing the size of the initramfs (assuming it goes there), by 
using dynamic libraries is an important exercise in the Embedded Linux course, and it will not be spoiled at this point (although I am tempted.)
```
./tinymix contents # Check values on controls
# Playback
./tinymix set 'Master Playback Switch' 1
./tinymix set 'Master Playback Volume' 50

# Recording
./tinymix set 'Capture Switch' 1
./tinymix set 'Capture Volume' 50

Then you can capture and play, assuming of course you hardware works well (including your QEMU settings, if you look at them), your kernel is properly configured (don't worry you will get other errors, and not just noticable sounds).


```


## Test status:
`qemu-system-... -device intel-hda -audio pipewire,id=snd0 -device hda-duplex`
- x86-64 (intel-h
- i686
- Others should work, but I did not test them

`qemu-system-... virtio` - did not check yet - will do when I have some time
