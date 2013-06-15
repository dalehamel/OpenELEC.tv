#!/bin/bash

# options
version=""
devbuild=0
testing=0
sourceforge=0
force_pht_rebuild=0
force_pht_update=0

#read default settings
settingsfile=~/.rasplex
[ -f "$settingsfile" ] && source "$settingsfile"

function usage {
    echo "$0 usage:
    [-h | --help]             : print this usage info
     -v | --version <version> : set the rasplex version
  [ [-d | --devbuild] |       : create a developer build
    [-t | --testing]  ]       : create a testing build
    [-s | --sourceforge]      : upload the image to sourceforge
    [--user <user>]           : the sourceforge user to use
    
optional build options:
    --force-pht-rebuild       : will force a pht rebuild 
    --force-pht-update        : will force a pht to download the latest code
                                and will force a rebuild

default options can be set via $settingsfile and will be evaluated first.
";
}

[ $# -eq 0 ] && usage && exit 1

while true; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--version)
            shift
            if [ -z $1 ]; then
                echo "version parameter missing!"
                exit 1
            fi
            version="$1"
            ;;
        -d|--devbuild)
            devbuild=1
            ;;
        -t|--testing)
            testing=1
            ;;
        -s|--sourceforge)
            sourceforge=1
            ;;
        --user)
            shift
            if [ -z $1 ]; then
                echo "user parameter missing!"
                exit 1
            fi
            user="$1"
            ;;
        --force-pht-rebuild)
            force_pht_rebuild=1
            ;;
        --force-pht-update)
            force_pht_update=1
            ;;
        --)
            shift; break;;
        *)
            shift; break;;
    esac
    shift
done

# validate settings
[ $devbuild -eq 1 -a $testing -eq 1 ] && echo "--debug and --testing can't used together" && exit 1
[ -z "$version" ] && echo "Missing version number" && usage && exit 1

# setup variables
distroname="rasplex"
devtools="no"
if [ $devbuild -eq 1 ];then
    distroname="rasplexdev"
    devtools="yes"
    echo "This is a development build!"
fi

scriptdir=$(cd `dirname $0` && pwd)
outfilename="$distroname-RPi.arm-$version"
tmpdir="$scriptdir/tmp"
outimagename="$distroname-$version.img"
outimagefile="$tmpdir/$outimagename"
targetdir="$scriptdir/target"

# set rasplex config
echo "
RASPLEX_VERSION=\"$version\"
DISTRONAME=\"$distroname\"
" > $scriptdir/config/rasplex

sed s/SET_RASPLEXVERSION/"$version"/g $scriptdir/config/version.in > $scriptdir/config/version


# build
function build {
    echo "Building rasplex"

    source $scriptdir/config/version
    if [ $force_pht_update -eq 1 ]; then
        rm -r "sources/plexht"
        rm -r "$scriptdir/build.rasplex-RPi.arm-$OPENELEC_VERSION/.stamps/plexht"
    elif [ $force_pht_rebuild -eq 1 ]; then
        rm "$scriptdir/build.rasplex-RPi.arm-$OPENELEC_VERSION/.stamps/plexht/build"
    fi

    time DEVTOOLS="$devtools" PROJECT=RPi ARCH=arm make release || exit 2
}

# create image file
function create_image {
    echo "Creating SD image"
    mkdir -p $tmpdir
    rm -rf $tmpdir/*
    cp $targetdir/$outfilename.tar.bz2 $tmpdir
    
    echo "  Extracting release tarball..."
    tar -xpjf $tmpdir/$outfilename.tar.bz2 -C $tmpdir
    
    echo "  Setup loopback device..."
    if [ "`losetup -f`" != "/dev/loop0" ];then
        umount /dev/loop0
        losetup -d /dev/loop0  || eval 'echo "It demands loop0 instead of first free loopback device... : (" ; exit 1'
    fi
    
    losetup -d /dev/loop0 || [ echo "It demands loop0 instead of first free device... : (" && exit 1 ]
    loopback=`losetup -f`
    
    echo "  Prepare image file..."
    dd if=/dev/zero of=$outimagefile bs=1M count=1500
    
    echo "  Write data to image..."
    cd $tmpdir/$outfilename
    ./create_sdcard  $loopback $outimagefile
    
    echo "Created SD image at $outimagefile"
}


function upload_sourceforge {
    projectdir="/home/frs/project/rasplex"
    projectdlbase="http://sourceforge.net/projects/rasplex/files"
    [ -z "$user" ] && user=`whoami`
    
    echo "Distributing build"
    
    cd "$tmpdir"

    echo "  compressing image..."
    gzip "$outimagefile"
    
    echo "  uploading autoupdate package"
    time scp "$outfilename.tar.bz2" "$user@frs.sourceforge.net:$projectdir/autoupdate/$distroname/"
    
    # enable auto-update for none-testing builds    
    if [ $testing -eq 0 ]; then
        echo "  setting latest version..."
        echo "$outfilename" > latest
        time scp latest "$user@frs.sourceforge.net:$projectdir/autoupdate/$distroname/"
        rm latest
    fi
    
    echo "  uploading install image"
    if [ $devbuild -eq 1 ];then
        releasedir="development"
    else
        releasedir="release"
    fi
    time scp "$outimagefile.gz" "$user@frs.sourceforge.net:$projectdir/$releasedir/"
    

    if [ $devbuild -eq 0 ]; then
        # update current stable release info
        if [ $testing -eq 0 ]; then
            echo "  setting current version info"
            echo "$projectdlbase/$releasedir/$outimagename.gz/download" >current
            time scp current "$user@frs.sourceforge.net:$projectdir/$releasedir/"
            rm current
        fi
    
        # update bleeding release info
        ## update bleeding info on newer stable release too
        bleedingurl="$projectdlbase/$releasedir/$outimagename.gz/download"
        bleedingcurrent=`wget -q -O - "$projectdlbase/$releasedir/bleeding/download"`
        if [ $testing -eq 1 -o "$bleedingurl" \> "$bleedingcurrent" ]; then
            echo "  setting bleeding version info"
            echo "$bleedingurl" >bleeding
            time scp bleeding "$user@frs.sourceforge.net:$projectdir/$releasedir/"
            rm bleeding
        fi
    fi
    
}

# main

build
create_image

if [ $sourceforge -eq 1 ]; then
    upload_sourceforge
fi

echo "done."


