#!/bin/bash
#
# Usage:
#   create-local-repo.sh <topdir>
#

REPO_DIR="$1"
[ -d $REPO_DIR ] || exit

SUITE=unstable
CODENAME=sid

#
# create the required directory tree
#
mkdir -p $REPO_DIR/conf
mkdir -p $REPO_DIR/dists
mkdir -p $REPO_DIR/pool

mkdir -p $REPO_DIR/indices
mkdir -p $REPO_DIR/incoming
mkdir -p $REPO_DIR/project

#
# FIXME: no package signing ...
#
# removed: "SignWith: yes"
#
cat > $REPO_DIR/conf/distributions <<EOF

Origin: debian.httc.com.cn
Label: local_repository_for_testing_only
Codename: $CODENAME
Architectures: amd64 mips64el ppc64el ppc64 powerpc source
Components: main,main/debian-installer
Description: local package repository of CEC Linux

EOF

cat > $REPO_DIR/conf/incoming <<EOF

Name: default
IncomingDir: incoming
TempDir: /tmp
Allow: $CODENAME
Cleanup: on_deny on_error

EOF

cat > $REPO_DIR/conf/options <<EOF

verbose
ask-passphrase
basedir .

EOF

cat > $REPO_DIR/conf/uploaders <<EOF

allow * by unsigned

EOF

#
# FIXME: we really need this ?
#
cd $REPO_DIR/indices

touch override.${CODENAME}.main
touch override.${CODENAME}.main.debian-installer
touch override.${CODENAME}.main.src

#
# now prepare the base directory tree ...
#
/usr/bin/reprepro -v -b $REPO_DIR export
