#!/bin/bash
app="${PWD##*/}"
version="${app##*-}"
app="${app%-*}"
arch="tar.${ALSY_XORG_APP_CONFIG_ARCHIVE_TYPE}"
sapp="$app-$version"

if [ ! -f $sapp.$arch ]; then
  wget  https://archive.mozilla.org/pub/security/nss/releases/NSS_3_61_RTM/src/$sapp.$arch -O $sapp.$arch --no-check-certificate
fi

sed 's/@alsy.app.name/'$sapp'/g' "Makefile.am" > "Makefile"

if [ -d ../build/$sapp ]; then
 rm -rfd ../build/$sapp
 if [ $? -eq 0 ]; then
   echo "delete..[ ok ]"
 else
   exit 1
 fi
fi

mkdir -p ../build &&
tar -xf "$sapp"."$arch" -C ../build
if [ $? -eq 0 ]; then
  cd ../build/$sapp
  if [ $? -eq 0 ]; then         
    if [ ! -f nss-3.61-standalone-1.patch ]; then
      wget http://www.linuxfromscratch.org/patches/blfs/svn/nss-3.61-standalone-1.patch
    fi
    patch -Np1 -i ../nss-3.61-standalone-1.patch &&
    cd nss &&
    make -j1 BUILD_OPT=1                  \
      NSPR_INCLUDE_DIR=/usr/include/nspr  \
      USE_SYSTEM_ZLIB=1                   \
      ZLIB_LIBS=-lz                       \
      NSS_ENABLE_WERROR=0                 \
      $([ $(uname -m) = x86_64 ] && echo USE_64=1) \
      $([ -f /usr/include/sqlite3.h ] && echo NSS_USE_SYSTEM_SQLITE=1)
  fi
fi
