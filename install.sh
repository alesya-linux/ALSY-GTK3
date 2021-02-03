GTK3_PREFIX=$1
if [ "$GTK3_PREFIX" == "" ]; then
 echo "Error: prefix not filled in !" 
 exit 1
fi
fileprofile="ALSY-GTK3.sh"
# Create an /etc/profile.d/ALSY-GTK3.sh configuration file containing these variables as the root user:
mkdir -p $GTK3_PREFIX/etc/profile.d/
cat > $GTK3_PREFIX/etc/profile.d/$fileprofile << EOF
GTK3_PREFIX="$GTK3_PREFIX"
export GTK3_PREFIX
ALSY_GTK3="1.0.1"
export ALSY_GTK3
EOF
chmod u=rwx,g=rx,o=x $GTK3_PREFIX/etc/profile.d/$fileprofile
