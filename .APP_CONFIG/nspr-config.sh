#!/bin/bash
app="${PWD##*/}"
version="${app##*-}"
app="${app%-*}"
arch="tar.${ALSY_XORG_APP_CONFIG_ARCHIVE_TYPE}"
sapp="$app-$version"

if [ ! -f $sapp.$arch ]; then
  wget https://archive.mozilla.org/pub/nspr/releases/v4.29/src/$sapp.$arch -O $sapp.$arch --no-check-certificate
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
    cd nspr                                                     &&
    sed -ri 's#^(RELEASE_BINS =).*#\1#' pr/src/misc/Makefile.in &&
    sed -i 's#$(LIBRARY) ##'            config/rules.mk         &&
    ./configure --prefix=/usr   \
                --with-mozilla  \
                --with-pthreads \
                $([ $(uname -m) = x86_64 ] && echo --enable-64bit)
  fi
fi
