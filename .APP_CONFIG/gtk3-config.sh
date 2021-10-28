#!/bin/bash
app="${PWD##*/}"
version="${app##*-}"
lversion="${version%.*}"
app="${app%-*}"
arch="tar.${ALSY_XORG_APP_CONFIG_ARCHIVE_TYPE}"
sapp="$app-$version"

if [ ! -f $sapp.$arch ]; then
  wget https://download.gnome.org/sources/$app/$lversion/$sapp.$arch -O $sapp.$arch --no-check-certificate
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
    ./configure --prefix=/                      \
                --sysconfdir=/etc               \
                --enable-broadway-backend       \
                --enable-x11-backend            \
                --enable-wayland-backend
  fi
fi