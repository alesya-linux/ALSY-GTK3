#!/bin/bash
app="${PWD##*/}"
version="${app##*-}"
app="${app%-*}"
arch="tar.${ALSY_XORG_APP_CONFIG_ARCHIVE_TYPE}"
sapp="$app-$version"

if [ ! -f $sapp.$arch ]; then
  wget ftp://ftp.acc.umu.se/pub/gnome/sources/gobject-introspection/1.66/$sapp.$arch -O $sapp.$arch --no-check-certificate
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
  rm -rfd ../gobj_build
  if [ $? -eq 0 ]; then    
    mkdir -p ../gobj_build &&
    meson --prefix=$GTK3_PREFIX \
          -Dman=true            \
          -Dselinux=disabled    \
    ../gobj_build
  fi
fi