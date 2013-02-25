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

sed s/SET_RASPLEXVERSION/"$version"/g $scriptdir/config/version.in > $scriptdir/config/version
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
    umount /dev/loop0
    losetup -d /dev/loop0  || eval 'echo "It demands loop0 instead of first free loopback device... : (" ; exit 1'
fi

losetup -d /dev/loop0 || [ echo "It demands loop0 instead of first free device... : (" && exit 1 ]
loopback=`losetup -f`
./create_sdcard  $loopback $outfile

echo "Created SD image at $outfile"

if [ "$2" == "--dist" ];then
    gzip $outfile
    echo "Distributing $prefix-RPi.arm-$version"
    

    echo "Distributing update image to sourceforge mirror"
    time scp  $tmpdir/$prefix-RPi.arm-$version.tar.bz2  dalehamel@frs.sourceforge.net:/home/frs/project/rasplex/autoupdate/rasplex/

    echo "Setting latest on sourceforge mirror"
    echo "$prefix-RPi.arm-$version" > latest
    time scp latest dalehamel@frs.sourceforge.net:/home/frs/project/rasplex/autoupdate/rasplex/


    echo "Distributing install image to sourceforge mirror"
    time scp $archive dalehamel@frs.sourceforge.net:/home/frs/project/rasplex/release/

    echo "Setting bleeding on sourceforge mirror"
    echo "http://sourceforge.net/projects/rasplex/files/release/$outname.gz/download" >bleeding
    time scp bleeding dalehamel@frs.sourceforge.net:/home/frs/project/rasplex/release

    echo "Copying install archive to S3..."
    time cp $archive /mnt/plex-rpi
    

fi
