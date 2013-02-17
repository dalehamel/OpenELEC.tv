#!/bin/bash
[ -z $1 ] && echo "Must give a version number" && exit 1

version=$1
scriptdir=$(cd `dirname $0` && pwd)
prefix="rasplex"
outname="rasplex-$version.img"
tmpdir="$scriptdir/tmp"
outfile="$tmpdir/$outname"
archive="$outfile.gz"
targetdir="$scriptdir/target"

time PROJECT=RPi ARCH=arm make release || exit
mkdir -p $tmpdir
rm -rf $tmpdir/*
mv $targetdir/$prefix*.tar.bz2 $tmpdir
echo "Extracting release tarball..."
tar -xpjf $tmpdir/$prefix*.tar.bz2 -C $tmpdir
dd if=/dev/zero of=$outfile bs=1M count=910 


echo "Creating SD image"
cd $tmpdir/$prefix-RPi.arm-2.99.2

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
