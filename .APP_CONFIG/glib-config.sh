#!/bin/bash
app="${PWD##*/}"
version="${app##*-}"
app="${app%-*}"
arch="tar.${ALSY_XORG_APP_CONFIG_ARCHIVE_TYPE}"
sapp="$app-$version"

if [ ! -f $sapp.$arch ]; then
  wget https://download.gnome.org/sources/$app/2.66/$sapp.$arch -O $sapp.$arch --no-check-certificate
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
  if [ -f glib-2.66.4-skip_warnings-1.patch ]; then
    cp glib-2.66.4-skip_warnings-1.patch ../build
  fi
  cd ../build/$sapp  
  rm -rfd ../glib_build
  if [ $? -eq 0 ]; then        
    patch -Np1 -i ../glib-2.66.4-skip_warnings-1.patch &&
    mkdir -p ../glib_build &&
    meson --prefix=$GTK3_PREFIX \
          -Dman=true            \
          -Dselinux=disabled    \
    ../glib_build
  fi
fi