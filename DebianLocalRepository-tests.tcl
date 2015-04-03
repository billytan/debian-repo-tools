#
# DebianLocalRepository-tests.tcl
#

source common.tcl

source DebianRepository.tcl
source DebianLocalRepository.tcl



if 0 {

	set REPO_DIR		"/baixibao2/baixibao_repo_root/debian"

	set repo_obj		[DebianLocalRepository new $REPO_DIR ]

	$repo_obj load  "$REPO_DIR/dists/jessie/main/binary-ppc64/Packages.gz" -verbose

	set count		0

	$repo_obj foreach_package _pkg {

		puts "$_pkg(Package)"; puts "\t\t $_pkg(Filename)";

		incr count; if { $count > 10 } break;
	}
}

if 0 { 

	set REPO_DIR		"/baixibao2/baixibao_repo_root/debian"

	set repo_obj		[DebianLocalRepository new $REPO_DIR ]
	
	$repo_obj load  "$REPO_DIR/dists/jessie/main/source/Sources.gz" -verbose

	set count		0

	$repo_obj foreach_source_package _pkg {

		puts "$_pkg(Package) $_pkg(Version) "; 
		
		foreach _line [split $_pkg(Files) "\n"] { puts "      $_line" }
		
		incr count; if { $count > 10 } break;
	}

}

if 0 {

	set REPO_DIR	"/disk2/loongfox-linux-dev/rebootstrap-ppc64/repo"
	
	set repo_obj		[DebianLocalRepository new $REPO_DIR -suite "rebootstrap" ]
	
	$repo_obj load  "$REPO_DIR/dists/rebootstrap/main/debian-installer/binary-ppc64/Packages.gz" -verbose
	
	$repo_obj load  "$REPO_DIR/dists/rebootstrap/main/binary-ppc64/Packages.gz" -verbose
	
	set count		0

	$repo_obj foreach_package _pkg {
		
		puts "$_pkg(Package)"; puts "\t\t $_pkg(Filename)";
		
		incr count; 
	}
	
	puts "$count packages found."
}


if 0 {

	set REPO_DIR		"/baixibao2/baixibao_repo_root/debian"

	set repo_obj		[DebianLocalRepository new $REPO_DIR --arch ppc64 ]

	#
	# first, check if we can remove a package, and reprepro can re-sign the Packages.gz files 
	#
	# $repo_obj remove zzuf
	
	catch {
		$repo_obj install "/baixibao2/buildd_repo_root/Incoming/zzuf_0.13.svn20100215-4.1_ppc64.changes"
	} _out
	
	puts $_out
}

if 1 {

	set repo_dir		"/baixibao2/baixibao_repo_root/debian"
	
	#
	# we have to scan the local repository in the first place ...
	#
	set repo_obj		[DebianLocalRepository new $repo_dir --arch ppc64 ]

	$repo_obj load  "$repo_dir/dists/jessie/main/binary-ppc64/Packages.gz" -verbose
	
	puts "\n"
	
	#
	# MUST call this, in order to generate the list of "Sources"
	#
	$repo_obj scan_sources -verbose

	set src_pkg		"abiword"
	
	$repo_obj remove $src_pkg
}


$repo_obj destroy


