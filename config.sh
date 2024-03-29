#!/bin/bash
FLAGSET="X"
ETAP1_FLAG="X"          # This is Flag compile for file GTK+.md5
CHECK_MD5SUM_FLAG="X"
GTK3_PREFIX="/usr/src/tools/ALSY-GTK3"
if [ "$( echo $1 | sed 's/--prefix=//' )" != ""  ]; then
  export GTK3_PREFIX="$( echo $1 | sed 's/--prefix=//' )"  
fi

prefix=$(echo $GTK3_PREFIX | sed 's/\//\\\//g' )
cp -a Makefile.in Makefile.am
sed -i 's/\${PREFIX}/'$prefix'/' Makefile.am

INSTALL_DIR=$GTK3_PREFIX
l1="$(expr length $INSTALL_DIR)"
INSTALL_DIR="${GTK3_PREFIX%/*}"
if [ "$INSTALL_DIR" != "" ]; then
  l2="$(expr length $INSTALL_DIR)"  
fi
let r1=l1-1
if [ "$r1" == "$l2" ]; then
  INSTALL_DIR="${INSTALL_DIR%/*}"
fi
if [ "$INSTALL_DIR" == "" ]; then
  echo "Error: invalid prefix"
  exit 1
fi
INSTALLDIR=$(echo $INSTALL_DIR | sed 's/\//\\\//g' )
sed 's/\${INSTALLDIR}/'$INSTALLDIR'/' Makefile.am > Makefile

SAVEPATH="$PATH"
APKG_CONFIG_PATH="$XORG_PREFIX/lib64/pkgconfig:$GTK3_PREFIX/lib64/pkgconfig:$GTK3_PREFIX/lib/pkgconfig:$GTK3_PREFIX/share/pkgconfig"
BPKG_CONFIG_PATH="$XORG_PREFIX/share/pkgconfig:$APKG_CONFIG_PATH:$GTK3_PREFIX/usr/lib/pkgconfig:$GTK3_PREFIX/usr/lib64/pkgconfig"
export PKG_CONFIG_PATH="$XORG_PREFIX/lib/pkgconfig:$BPKG_CONFIG_PATH" 
export PATH="$GTK3_PREFIX/bin:$PATH"

LIBRARY_PATH=""
C_INCLUDE_PATH=""
CPLUS_INCLUDE_PATH="$C_INCLUDE_PATH"
LIBRARY_PATH="$XORG_PREFIX/lib:$GTK3_PREFIX/lib"
C_INCLUDE_PATH="$XORG_PREFIX/include:$GTK3_PREFIX/include"
CPLUS_INCLUDE_PATH="$XORG_PREFIX/include:$GTK3_PREFIX/include"
ACLOCAL="aclocal -I $GTK3_PREFIX/share/aclocal"
export ACLOCAL
export LIBRARY_PATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH
export GTK3_PREFIX
export LD_LIBRARY_PATH="$GTK3_PREFIX/usr/lib:$GTK3_PREFIX/lib:$GTK3_PREFIX/usr/lib64:$GTK3_PREFIX/lib64"

if [ "${ALSY_XORG}" == "" ]; then
  echo "Error ALSY-XORG-7 version 1.0.6 or newer not found!"
  exit 1
fi

MD5SUMFILE=""
APPLICATION_SITE=""
INSTALL_APPLICATION=""

APP_LISTING=".APP_LISTING"
APP_CONFIG=".APP_CONFIG"
APP_MAKEFILE=".APP_MAKEFILE"
APP_COMPILE="build/compile"
APP_PACKAGE="APP_PACKAGE"
APP_PATCHES="APP_PATCHES"

echo "Installation Log File: $(date)" > install_log.txt

Add_Log()
{
  echo "$INSTALL_APPLICATION: $MD5SUMFILE" >> $APPLICATION_SITE/install_log.txt
}

check_last()
{
  if [ $? -ne 0 ]; then    
    echo "Error $*"
    exit 1    
  fi
}

as_root()
{
  if   [ $EUID = 0 ];        then $*
  elif [ -x /usr/bin/sudo ]; then sudo $*
  else                            su -c \\"$*\\"
  fi
}

make_install()
{
LASTPATH="$PATH"
PATH="$SAVEPATH"
as_root make GTK3_PREFIX=${GTK3_PREFIX} install
check_last "make install"
# Add Log
Add_Log
PATH="$LASTPATH"
}

compile()
{
APPLICATION_SITE="$PWD"
INSTALL_APPLICATION="$packagedir"
 
pushd $packagedir
if [ -f install.sh ]; then
  chmod u+x install.sh
fi
chmod u+x config.sh
./config.sh
check_last "config"
if [ -f $APPLICATION_SITE/$packagedir/$package ]; then
  MD5SUMFILE=$( md5sum $APPLICATION_SITE/$packagedir/$package | cut -d" " -f1 )
fi
if [ "$CHECK_MD5SUM_FLAG" == "X" ]; then  
  if [ "$MD5SUMFILE" != "$CURRMD5SUM" ]; then
    echo "Error check md5sum for file: $APPLICATION_SITE/$packagedir/$package"
    echo "$CURRMD5SUM"
    echo "$MD5SUMFILE"
    exit 1
  else
    MD5SUMFILE="$(md5sum $APPLICATION_SITE/$packagedir/$package)"
  fi
fi
make      
check_last "make"
make_install
popd
}

install_python_modules="false"
if [ "$install_python_modules" == "true" ]; then
  ln -sfv /home/alesya/Public/python python_modules &&
  pushd python_modules/setuptools-58.0.4  &&
    python3 setup.py build                &&
    sudo python3 setup.py install --optimize=1 &&
  popd                                    &&
  
  pushd python_modules/pip-21.2.4         &&
    python3 setup.py build                &&
    sudo  python3 setup.py install --optimize=1 &&
  popd                                    &&
  
  pushd python_modules/meson-0.59.1       &&
    python3 setup.py build                &&
    sudo python3 setup.py install --optimize=1 &&
  popd 
  
  pushd python_modules/ninja-1.10.2       &&
  ./compile.sh                            && 
  popd
  btrue=true
  sed -i 's/install_python_modules="'$btrue'"/install_python_modules="false"/' config.sh
fi

if [ "$ETAP1_FLAG" == "X" ]; then
COMPILEFILE="$APP_LISTING/GTK+.md5"
for package in $(grep -v '^#' $COMPILEFILE | awk '{print $2}')
do  
  packagedir=${package%.tar.*}
  typearchive=${package#*.tar.*}
  CURRMD5SUM=$(grep -v '^#' $COMPILEFILE | grep $package | cut -d" " -f1)
  
export ALSY_XORG_APP_CONFIG_ARCHIVE_TYPE="$typearchive"
if [ ! -d $APP_COMPILE/$packagedir ]; then
  mkdir -p $APP_COMPILE/$packagedir
fi  

if [ -f $APP_PACKAGE/$package ]; then
  cp -rfv $APP_PACKAGE/$package $APP_COMPILE/$packagedir
fi

cp $APP_MAKEFILE/proto-Makefile.am $APP_COMPILE/$packagedir/Makefile.am
case $packagedir in
  libunistring* )
    cp -r $APP_CONFIG/libunistring-config.sh $APP_COMPILE/$packagedir/config.sh  
    cp -r $APP_MAKEFILE/libunistring-Makefile.am $APP_COMPILE/$packagedir/Makefile.am
  ;;
  harfbuzz* )
    cp -r $APP_CONFIG/harfbuzz-config.sh $APP_COMPILE/$packagedir/config.sh  
  ;;  
  libepoxy* )
    cp -r $APP_CONFIG/libepoxy-config.sh $APP_COMPILE/$packagedir/config.sh
    cp -r $APP_MAKEFILE/meson-Makefile.am $APP_COMPILE/$packagedir/Makefile.am
  ;;  
  Python* )
    cp $APP_CONFIG/python-config.sh $APP_COMPILE/$packagedir/config.sh
  ;;
  zlib* )
    cp $APP_CONFIG/zlib-config.sh $APP_COMPILE/$packagedir/config.sh
  ;;
  icu* )
    cp $APP_CONFIG/icu-config.sh $APP_COMPILE/$packagedir/config.sh
    cp $APP_MAKEFILE/icu-Makefile.am $APP_COMPILE/$packagedir/Makefile.am
  ;;
  dbus* )
    cp $APP_CONFIG/dbus-config.sh $APP_COMPILE/$packagedir/config.sh
    cp $APP_CONFIG/rc.messagebus $APP_COMPILE/$packagedir/rc.messagebus
    cp $APP_MAKEFILE/dbus-Makefile.am $APP_COMPILE/$packagedir/Makefile.am
  ;;
  expat* )
    cp $APP_CONFIG/expat-config.sh $APP_COMPILE/$packagedir/config.sh    
    cp $APP_MAKEFILE/expat-Makefile.am $APP_COMPILE/$packagedir/Makefile.am
  ;;
  libxml2* )
    cp $APP_CONFIG/libxml2-config.sh $APP_COMPILE/$packagedir/config.sh    
    cp $APP_MAKEFILE/libxml2-Makefile.am $APP_COMPILE/$packagedir/Makefile.am
    if [ -f $APP_PATCHES/libxml2-2.9.10-security_fixes-1.patch ]; then
      cp $APP_PATCHES/libxml2-2.9.10-security_fixes-1.patch $APP_COMPILE/$packagedir
    fi
  ;;
  libxslt* )
    cp $APP_CONFIG/libxslt-config.sh $APP_COMPILE/$packagedir/config.sh    
    cp $APP_MAKEFILE/libxslt-Makefile.am $APP_COMPILE/$packagedir/Makefile.am
    cp $APP_CONFIG/libxslt-install.sh $APP_COMPILE/$packagedir/install.sh
  ;;
  glib* )
    cp $APP_CONFIG/glib-config.sh $APP_COMPILE/$packagedir/config.sh    
    cp $APP_MAKEFILE/glib-Makefile.am $APP_COMPILE/$packagedir/Makefile.am
    if [ -f $APP_PATCHES/glib-2.66.4-skip_warnings-1.patch ]; then
      cp $APP_PATCHES/glib-2.66.4-skip_warnings-1.patch $APP_COMPILE/$packagedir
    fi    
  ;;
  gobject* )
    cp $APP_CONFIG/gobject-config.sh $APP_COMPILE/$packagedir/config.sh    
    cp $APP_MAKEFILE/gobject-Makefile.am $APP_COMPILE/$packagedir/Makefile.am    
  ;;
  atk* )
    cp $APP_CONFIG/atk-config.sh $APP_COMPILE/$packagedir/config.sh    
    cp -r $APP_MAKEFILE/atk-Makefile.am $APP_COMPILE/$packagedir/Makefile.am
  ;;
  at*spi2* )
    cp $APP_CONFIG/at-spi2-config.sh $APP_COMPILE/$packagedir/config.sh    
    cp -r $APP_MAKEFILE/at-spi2-Makefile.am $APP_COMPILE/$packagedir/Makefile.am
  ;;
  shared*mime*info* )
    cp -r $APP_CONFIG/shminfo-config.sh $APP_COMPILE/$packagedir/config.sh
    cp -r $APP_MAKEFILE/shminfo-Makefile.am $APP_COMPILE/$packagedir/Makefile.am  
  ;;
  tiff* )
    cp -r $APP_CONFIG/libtiff-config.sh $APP_COMPILE/$packagedir/config.sh
    cp -r $APP_MAKEFILE/libtiff-Makefile.am $APP_COMPILE/$packagedir/Makefile.am  
  ;;
  gdk*pixbuf* )
    cp -r $APP_CONFIG/gdkpixbuf-config.sh $APP_COMPILE/$packagedir/config.sh
    cp -r $APP_MAKEFILE/gdkpixbuf-Makefile.am $APP_COMPILE/$packagedir/Makefile.am  
  ;;
  wayland* )
    cp -r $APP_CONFIG/wayland-config.sh $APP_COMPILE/$packagedir/config.sh
    cp -r $APP_MAKEFILE/wayland-Makefile.am $APP_COMPILE/$packagedir/Makefile.am  
  ;;
  libxkbcommon* )
    cp -r $APP_CONFIG/libxkbcommon-config.sh $APP_COMPILE/$packagedir/config.sh
    cp -r $APP_MAKEFILE/libxkbcommon-Makefile.am $APP_COMPILE/$packagedir/Makefile.am  
  ;;
  gtk+-2* )
    cp -r $APP_CONFIG/gtk2-config.sh $APP_COMPILE/$packagedir/config.sh
    cp -r $APP_MAKEFILE/gtk2-Makefile.am $APP_COMPILE/$packagedir/Makefile.am  
  ;;
  gtk* )
    cp -r $APP_CONFIG/gtk3-config.sh $APP_COMPILE/$packagedir/config.sh
    cp -r $APP_MAKEFILE/gtk3-Makefile.am $APP_COMPILE/$packagedir/Makefile.am  
  ;;
  cairo* )
    cp -r $APP_CONFIG/cairo-config.sh $APP_COMPILE/$packagedir/config.sh
    cp -r $APP_MAKEFILE/cairo-Makefile.am $APP_COMPILE/$packagedir/Makefile.am  
  ;;
  pango* )
    cp -r $APP_CONFIG/pango-config.sh $APP_COMPILE/$packagedir/config.sh
    cp -r $APP_MAKEFILE/pango-Makefile.am $APP_COMPILE/$packagedir/Makefile.am  
  ;;
  xmlto* )
    cp -r $APP_CONFIG/xmlto-config.sh $APP_COMPILE/$packagedir/config.sh
    cp -r $APP_MAKEFILE/xmlto-Makefile.am $APP_COMPILE/$packagedir/Makefile.am  
  ;;
  itstool* )
    cp -r $APP_CONFIG/itstool-config.sh $APP_COMPILE/$packagedir/config.sh
    cp -r $APP_MAKEFILE/itstool-Makefile.am $APP_COMPILE/$packagedir/Makefile.am  
  ;;
  libuv* )
    cp -r $APP_CONFIG/libuv-config.sh $APP_COMPILE/$packagedir/config.sh
    cp -r $APP_MAKEFILE/libuv-Makefile.am $APP_COMPILE/$packagedir/Makefile.am  
  ;;
  libjpeg*turbo* )
    cp -r $APP_CONFIG/libjpegturbo-config.sh $APP_COMPILE/$packagedir/config.sh    
    cp -r $APP_MAKEFILE/libjpegturbo-Makefile.am $APP_COMPILE/$packagedir/Makefile.am  
  ;;
  libssh2* )
    cp -r $APP_CONFIG/libssh2-config.sh $APP_COMPILE/$packagedir/config.sh    
    cp -r $APP_MAKEFILE/libssh2-Makefile.am $APP_COMPILE/$packagedir/Makefile.am  
  ;;
  nspr* )
    cp -r $APP_CONFIG/nspr-config.sh $APP_COMPILE/$packagedir/config.sh    
    cp -r $APP_MAKEFILE/nspr-Makefile.am $APP_COMPILE/$packagedir/Makefile.am  
  ;;
  nss* )
    cp -r $APP_CONFIG/nss-config.sh $APP_COMPILE/$packagedir/config.sh    
    cp -r $APP_MAKEFILE/nss-Makefile.am $APP_COMPILE/$packagedir/Makefile.am  
  ;;
  cmake* )
    cp -r $APP_CONFIG/cmake-config.sh $APP_COMPILE/$packagedir/config.sh    
    cp -r $APP_MAKEFILE/cmake-Makefile.am $APP_COMPILE/$packagedir/Makefile.am  
  ;;
esac


if [ -d $APP_COMPILE/$packagedir ]; then
 pushd $APP_COMPILE
 compile
 popd
fi
done
# Снимаем флаг
sed -i 's/ETAP1_FLAG="'$FLAGSET'"/ETAP1_FLAG=" "/' config.sh
fi
