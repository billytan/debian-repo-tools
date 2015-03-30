#
# DebianLocalRepository-tests.tcl
#

source common.tcl

source DebianLocalRepository.tcl

set REPO_DIR		"/baixibao2/baixibao_repo_root/debian"

set repo_obj		[DebianLocalRepository new $REPO_DIR ]

if 0 {
	$repo_obj load  "$REPO_DIR/dists/jessie/main/binary-ppc64/Packages.gz" -verbose

	set count		0

	$repo_obj foreach_package _pkg {

		puts "$_pkg(Package)"; puts "\t\t $_pkg(Filename)";

		incr count; if { $count > 10 } break;
	}
}

if 1 { 

	$repo_obj load  "$REPO_DIR/dists/jessie/main/source/Sources.gz" -verbose

	set count		0

	$repo_obj foreach_source_package _pkg {

		puts "$_pkg(Package) $_pkg(Version) "; 
		
		foreach _line [split $_pkg(Files) "\n"] { puts "      $_line" }
		
		incr count; if { $count > 10 } break;
	}

}

$repo_obj destroy