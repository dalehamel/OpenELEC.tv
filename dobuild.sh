#!/bin/bash
[ -z $1 ] && echo "Must give a version number" && exit 1

version=$1
distroname="rasplex"
scriptdir=$(cd `dirname $0` && pwd)
prefix="$distroname"
outname="$distroname-$version.img"
tmpdir="$scriptdir/tmp"
outfile="$tmpdir/$outname"
archive="$outfile.gz"
targetdir="$scriptdir/target"

# set rasplex config
echo "
RASPLEX_VERSION=\"$version\"
DISTRONAME=\"$distroname\"
" > $scriptdir/config/rasplex

time PROJECT=RPi ARCH=arm make release || exit
mkdir -p $tmpdir
rm -rf $tmpdir/*
cp $targetdir/$prefix-RPi.arm-$version.tar.bz2 $tmpdir
echo "Extracting release tarball..."
tar -xpjf $tmpdir/$prefix-RPi.arm-$version.tar.bz2 -C $tmpdir
dd if=/dev/zero of=$outfile bs=1M count=910 


echo "Creating SD image"
cd $tmpdir/$prefix-RPi.arm-$version

if [ "`losetup -f`" != "/dev/loop0" ];then
    losetup -d /dev/loop0  || eval 'echo "It demands loop0 instead of first free loopback device... : (" ; exit 1'
fi

losetup -d /dev/loop0 || [ echo "It demands loop0 instead of first free device... : (" && exit 1 ]
loopback=`losetup -f`
./create_sdcard  $loopback $outfile

echo "Created SD image at $outfile"
gzip $outfile

if [ "$2" == "--dist" ];then
    echo "Copying archive to S3..."
    time cp $archive /mnt/plex-rpi
fi
