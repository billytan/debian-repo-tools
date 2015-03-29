#
# DebianRemoteRepo-tests.tcl
#


source common.tcl

source DebianRemoteRepo.tcl


set repo_obj		[DebianRemoteRepo new "http://ftp.cn.debian.org/debian" jessie ]

$repo_obj load_packages

set count		0

$repo_obj foreach_package _pkg {

	puts "$_pkg(Package)"; puts "\t\t $_pkg(Filename)";

	incr count; if { $count > 10 } break;
}

$repo_obj destroy


