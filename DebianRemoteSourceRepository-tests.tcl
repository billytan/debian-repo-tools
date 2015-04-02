#
# DebianRemoteSourceRepository-tests.tcl
#

source common.tcl

source DebianRepository.tcl
source DebianRepositoryCache.tcl
source DebianRemoteSourceRepository.tcl

# set repo_obj		[DebianRemoteSourceRepository new "http://ftp.cn.debian.org/debian" jessie ]

set repo_obj		[DebianRemoteSourceRepository new "http://192.168.133.126/amd64/debian" jessie --components main ]

# set repo_obj		[DebianRemoteSourceRepository new "http://192.168.133.126/baixibao/debian" jessie  ]




if 1 {

	$repo_obj load_source_packages -verbose

	set count		0

	$repo_obj foreach_source_package _pkg {

		puts "$_pkg(Package)"
		
		foreach _line [split $_pkg(Files) "\n"] { puts "    $_line" }

		incr count; if { $count > 10 } break;
	}

}

$repo_obj destroy