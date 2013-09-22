################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
#      Copyright (C) 2011 Anthony Nash (nash.ant@gmail.com)
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with OpenELEC.tv; see the file COPYING.  If not, write to
#  the Free Software Foundation, 51 Franklin Street, Suite 500, Boston, MA 02110, USA.
#  http://www.gnu.org/copyleft/gpl.html
################################################################################

PKG_NAME="open-vm-tools"
PKG_VERSION="9.2.3-1031360"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://open-vm-tools.sourceforge.net"
PKG_URL="$SOURCEFORGE_SRC/project/open-vm-tools/open-vm-tools/stable-9.2.x/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS="glib"
PKG_BUILD_DEPENDS_TARGET="toolchain glib"
PKG_PRIORITY="optional"
PKG_SECTION="virtualization"
PKG_SHORTDESC="open-vm-tools: open source implementation of VMware Tools"
PKG_LONGDESC="open-vm-tools: open source implementation of VMware Tools"

PKG_IS_ADDON="no"
PKG_AUTORECONF="yes"

OPENVMTOOLS_KERNEL_VER=$(basename $(ls -d $ROOT/$BUILD/linux-[0-9]*)| sed 's|linux-||g')

PKG_CONFIGURE_OPTS_TARGET="--disable-docs \
                           --disable-tests \
                           --without-pam \
                           --without-gtk2 \
                           --without-gtkmm \
                           --without-dnet \
                           --without-x \
                           --without-icu \
                           --without-procps \
                           --with-kernel-release=$OPENVMTOOLS_KERNEL_VER \
                           --with-linuxdir=$(ls -d $ROOT/$BUILD/linux-*)"

PKG_MAKE_OPTS_TARGET="CFLAGS+=-DG_DISABLE_DEPRECATED"

makeinstall_target() {
  mkdir -p $INSTALL/lib/modules/$OPENVMTOOLS_KERNEL_VER/open-vm-tools
    cp -PR ../modules/linux/vmxnet/vmxnet.ko $INSTALL/lib/modules/$ISCSI_KERNEL_VER/open-vm-tools

  mkdir -p $INSTALL/usr/lib
    cp -PR libvmtools/.libs/libvmtools.so* $INSTALL/usr/lib

  mkdir -p $INSTALL/usr/bin
    cp -PR services/vmtoolsd/.libs/vmtoolsd $INSTALL/usr/bin
    cp -PR checkvm/.libs/vmware-checkvm $INSTALL/usr/bin
}
