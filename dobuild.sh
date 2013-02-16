#!/bin/bash
[ -z $1 ] && echo "Must give a version number" && exit 1

version=$1
scriptdir=$(cd `dirname $0` && pwd)
prefix="rasplex"
loopback=`losetup -f`
outname="rasplex-$version.img"
tmpdir="$scriptdir/tmp"
outfile="$tmpdir/$outname"
archive="$outfile.gz"
targetdir="$scriptdir/target"

time PROJECT=RPi ARCH=arm make release
mkdir -p $tmpdir
rm -rf $tmpdir/*
mv $targetdir/$prefix*.tar.bz2 $tmpdir
echo "Extracting release tarball..."
tar -xpjf $tmpdir/$prefix*.tar.bz2 -C $tmpdir
dd if=/dev/zero of=$outfile bs=1M count=910 


echo "Creating SD image"
cd $tmpdir/$prefix*
./create_sdcard  $loopback $outfile

echo "Created SD image at $outfile"
gzip $outfile

if [ "$2" == "--dist" ];then
    echo "Copying archive to S3..."
    time cp $archive /mnt/plex-rpi
fi
