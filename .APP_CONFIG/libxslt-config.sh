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
  cd ../build/$sapp  
  if [ $? -eq 0 ]; then         
    sed -i s/3000/5000/ libxslt/transform.c doc/xsltproc.{1,xml} && 
    ./configure --prefix=$GTK3_PREFIX \
                --disable-static \
                --with-history   \
                --without-python
  fi
fi