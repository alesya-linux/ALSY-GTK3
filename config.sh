#!/bin/bash
FLAGSET="X"
ETAP1_FLAG="X"          # This is Flag compile for file GKT+.md5
CHECK_MD5SUM_FLAG="X"
GTK3_PREFIX="/usr/src/tools/GTK+-3.24.24"
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
APKG_CONFIG_PATH="$XORG_PREFIX/lib64/pkgconfig:$GTK3_PREFIX/lib64/pkgconfig:$GTK3_PREFIX/lib/pkgconfig"
BPKG_CONFIG_PATH="$XORG_PREFIX/share/pkgconfig:$APKG_CONFIG_PATH"
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
as_root make install
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

if [ "$ETAP1_FLAG" == "X" ]; then
COMPILEFILE="$APP_LISTING/GKT+.md5"
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