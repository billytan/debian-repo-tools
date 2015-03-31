#!/bin/sh

#
# apt-cache, but against a local repo
#

MIRROR="http://192.168.133.126/ppc64/debian"
SUITE=sid


TMP_DIR=`mktemp -d -p /tmp apt-XXXXX`


mkdir -p $TMP_DIR/etc/apt

cat > $TMP_DIR/etc/apt/sources.list <<EOF

deb [arch=ppc64, trusted=yes]  $MIRROR $SUITE main

EOF

_dir=$TMP_DIR/var/lib/apt

mkdir -p $_dir/lists
mkdir -p $_dir/archives/partial

APT_CONFIG="-o Apt::Architecture=ppc64"

APT_CONFIG="$APT_CONFIG -o Apt::Get::Download-Only=true"
APT_CONFIG="$APT_CONFIG -o Apt::Install-Recommends=false"

APT_CONFIG="$APT_CONFIG -o Apt::Get::AllowUnauthenticated=true"

APT_CONFIG="$APT_CONFIG -o Dir::Etc=$TMP_DIR/etc/apt"
mkdir -p $TMP_DIR/etc/apt/preferences.d/ 

APT_CONFIG="$APT_CONFIG -o Dir::Etc::SourceList=$TMP_DIR/etc/apt/sources.list"
APT_CONFIG="$APT_CONFIG -o Dir::Etc::SourceParts=$TMP_DIR/etc/apt/sources.list.d"

APT_CONFIG="$APT_CONFIG -o Dir::State=$_dir"

APT_CONFIG="$APT_CONFIG -o Dir::State::Status=$TMP_DIR/var/lib/dpkg/status"
mkdir -p $TMP_DIR/var/lib/dpkg
touch $TMP_DIR/var/lib/dpkg/status

APT_CONFIG="$APT_CONFIG -o Dir::Cache=$_dir"

#
# download meta-data files ....
#
apt-get -y $APT_CONFIG update >/dev/null 2>&1

#
# check if the required package exists ...
#
pkg="$1"
test -z "$pkg" && exit

apt-cache $APT_CONFIG show $pkg 

# rm -fr $TMP_DIR

