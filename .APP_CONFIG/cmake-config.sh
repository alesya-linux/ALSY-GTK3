#!/bin/bash
app="${PWD##*/}"
version="${app##*-}"
app="${app%-*}"
arch="tar.${ALSY_XORG_APP_CONFIG_ARCHIVE_TYPE}"
sapp="$app-$version"

if [ ! -f $sapp.$arch ]; then
  wget https://cmake.org/files/v3.19/$sapp.$arch -O $sapp.$arch --no-check-certificate
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
    sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake &&
    ./bootstrap --prefix=/usr        \
                --system-libs        \
                --mandir=/share/man  \
                --no-system-jsoncpp  \
                --no-system-librhash \
                --docdir=/share/doc/cmake-3.19.3
  fi
fi
