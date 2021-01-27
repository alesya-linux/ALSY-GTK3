#!/bin/bash
dapp="icu-release-68-2/icu4c"
sapp="source"

app="icu4c-68.2"
lapp="icu-release-68-2"
arch="tar.gz"

sed 's/@app.alsy.name/'$sapp'/g' "Makefile.am" > "Makefile"

if [ -d ../build/$dapp ]; then
 rm -rfd ../build
 if [ $? -eq 0 ]; then
   echo "delete..[ ok ]"
 else
   exit 1
 fi
fi

mkdir -p ../build &&
tar -xf "$lapp"."$arch" -C ../build
if [ $? -eq 0 ]; then
  cd ../build/$dapp
  if [ $? -eq 0 ]; then
    pushd $sapp
    export CC="/usr/bin/gcc"  &&
    export CXX="/usr/bin/g++" &&
    ./configure --prefix=$GTK3_PREFIX &&
    popd
  fi
fi