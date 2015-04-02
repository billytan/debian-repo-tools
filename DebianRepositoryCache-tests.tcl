#
# DebianRepostioryCache-tests.tcl
#

source common.tcl

source DebianRepositoryCache.tcl

set cache_obj		[DebianRepositoryCache new "http://192.168.133.126/ppc64/debian" sid --arch ppc64 --components main ]

$cache_obj update

@file [$cache_obj apt-cache dumpavail] >> /tmp/Packages.txt

puts [$cache_obj get_Packages_files]




