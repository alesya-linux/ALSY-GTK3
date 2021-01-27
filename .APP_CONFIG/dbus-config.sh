#!/bin/bash
app="${PWD##*/}"
version="${app##*-}"
app="${app%-*}"
arch="tar.${ALSY_XORG_APP_CONFIG_ARCHIVE_TYPE}"
sapp="$app-$version"

if [ ! -f $app-$version.$arch ]; then  
  filedwnld="https://dbus.freedesktop.org/releases/dbus/$app-$version.$arch"
  wget $filedwnld -O "$app-$version".$arch --no-check-certificate
  if [ $? -ne 0 ]; then 
    filedwnld="https://dbus.freedesktop.org/releases/dbus/$app-$version.$arch"
    wget $filedwnld -O "$app-$version".$arch --no-check-certificate
  fi
fi

app="$app-$version"
sed 's/@alsy.app.name/'$app'/g' "Makefile.am" > "Makefile"

if [ -d ../build/$app ]; then
 rm -rfd ../build/$app
 if [ $? -eq 0 ]; then
   echo "clean .. [ ok ]"
 else
   exit 1
 fi
fi

PREFIX=$GTK3_PREFIX

mkdir -p ../build &&
tar -xf "$app"."$arch" -C ../build
if [ $? -eq 0 ]; then
  cd ../build/$app
  if [ $? -eq 0 ]; then
    ./configure --prefix=$PREFIX                                     \
                --sysconfdir=/etc                                    \
                --localstatedir=/var                                 \
                --enable-user-session                                \
                --disable-doxygen-docs                               \
                --disable-xml-docs                                   \
                --disable-static                                     \
                --with-systemduserunitdir=no                         \
                --with-systemdsystemunitdir=no                       \
                --docdir=$PREFIX/share/doc/$app-$version             \
                --with-console-auth-dir=/var/run/ConsoleKit          \
                --with-system-pid-file=/var/run/dbus/pid             \
                --with-system-socket=/var/run/dbus/system_bus_socket
  fi
fi
