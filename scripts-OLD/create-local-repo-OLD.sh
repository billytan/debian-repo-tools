#!/bin/bash

XXX DO NOT USE THIS ONE

#
# Usage:
#   create-local-repo.sh $top_dir
#

TOPDIR="$1"
[ -d $TOPDIR ] || exit

#
# by default, all the packages marked as "unstable"
#
SUITE=unstable
CODENAME=sid

ARCH=amd64
ARCH2=ppc64

repo_origin=debian.httc.com.cn
repo_label=local_repository_for_testing_only

#
# create the directory tree ...
#
mkdir -p $TOPDIR/pool/main

mkdir -p $TOPDIR/dists/$SUITE/main/source

mkdir -p $TOPDIR/dists/$SUITE/main/binary-$ARCH
mkdir -p $TOPDIR/dists/$SUITE/main/binary-$ARCH2

#
# create "Release" file
#
cat > $TOPDIR/dists/$SUITE/main/source/Release <<EOF
Archive: $SUITE
Version: 4.0
Component: main
Origin: $repo_origin
Label: $repo_label
Architecture: source
EOF

for a in $ARCH $ARCH2 ; do

cat > $TOPDIR/dists/$SUITE/main/binary-$a/Release <<EOF
Archive: $SUITE
Version: 4.0
Component: main
Origin: $repo_origin
Label: $repo_label
Architecture: $a
EOF

done

#
# config files for apt-ftparchive
#
cat >$TOPDIR/aptftp.conf <<EOF

APT::FTPArchive::Release {
	Origin "$repo_origin";
	Label "$repo_label";
	Suite "$SUITE";
	Codename "$CODENAME";
	Architecture "amd64";
	Components "main";
	Description "local repository for testing only";
}

EOF

cat >$TOPDIR/aptgenerate.conf <<EOF
Dir::ArchiveDir ".";
Dir::CacheDir ".";
TreeDefault::Directory "pool/";
TreeDefault::SrcDirectory "pool/";

Default::Packages::Extensions ".deb";
Default::Packages::Compress ". gzip bzip2";
Default::Sources::Compress "gzip bzip2";
Default::Contents::Compress "gzip bzip2";

BinDirectory "dists/$SUITE/main/binary-$ARCH" {
  Packages "dists/$SUITE/main/binary-$ARCH/Packages";
  Contents "dists/$SUITE/Contents-$ARCH";
  SrcPackages "dists/$SUITE/main/source/Sources";
};

BinDirectory "dists/$SUITE/main/binary-$ARCH2" {
  Packages "dists/$SUITE/main/binary-$ARCH2/Packages";
  Contents "dists/$SUITE/Contents-$ARCH2";
  SrcPackages "dists/$SUITE/main/source/Sources";
};

Tree "dists/$SUITE" {
  Sections "main";
  Architectures "$ARCH $ARCH2 source";
};

EOF




