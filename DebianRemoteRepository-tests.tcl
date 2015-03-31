#
# DebianRemoteRepo-tests.tcl
#


source common.tcl

source DebianRepository.tcl
source DebianRemoteRepository.tcl

# set repo_obj		[DebianRemoteRepository new "http://ftp.cn.debian.org/debian" jessie -source 1 ]
# set repo_obj		[DebianRemoteRepository new "http://ftp.de.debian.org/debian-ports" sid --arch ppc64 ]
# set repo_obj		[DebianRemoteRepository new "http://192.168.133.126/ppc64/debian" sid --arch ppc64 ]

# set repo_obj		[DebianRemoteRepository new "http://192.168.133.126/baixibao/debian" jessie -source 1 ]
set repo_obj		[DebianRemoteRepository new "http://192.168.133.88/baixibao/debian" jessie -source 1 ]

if 0 {

	$repo_obj load_packages

	set count		0

	$repo_obj foreach_package _pkg {

		puts "$_pkg(Package)"; puts "\t\t $_pkg(Filename)";

		incr count; if { $count > 10 } break;
	}
	
	cd /tmp
	$repo_obj download alien
}

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


