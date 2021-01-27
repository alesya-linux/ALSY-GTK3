#!/bin/bash
app="${PWD##*/}"
version="${app##*-}"
app="${app%-*}"
arch="tar.${ALSY_XORG_APP_CONFIG_ARCHIVE_TYPE}"
sapp="$app-$version"

if [ ! -f $sapp.$arch ]; then
  wget http://xmlsoft.org/sources/$sapp.$arch -O $sapp.$arch --no-check-certificate
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
  if [ -f libxml2-2.9.10-security_fixes-1.patch ]; then
    cp libxml2-2.9.10-security_fixes-1.patch ../build
  fi
  cd ../build/$sapp
  patch -p1 -i ../libxml2-2.9.10-security_fixes-1.patch
  if [ $? -eq 0 ]; then         
    sed -i '/if Py/{s/Py/(Py/;s/)/))/}' python/{types.c,libxml.c} &&
    sed -i 's/test.test/#&/' python/tests/tstLastError.py && 
    sed -i 's/ TRUE/ true/' encoding.c && 
    ./configure --prefix=$GTK3_PREFIX \
                --disable-static \
                --with-history   \
                --with-python=/usr/bin/python3
  fi
fi