#
# repo-util-tests.tcl
#

set SCRIPT		[file dirname [info script]]

source $SCRIPT/common_util.tcl
source $SCRIPT/repo_util.tcl


if 0 {
	set pathname	[lindex $argv 0]

	set result		[load_packages my $pathname]
}


proc stat_file { pathname args } {

	file stat [file join $::repo_dir $pathname] _arr

	puts "\n$pathname"
	parray _arr
}

if 1 { 

	set pathname	[lindex $argv 0]

	set ::repo_dir		[file dirname $pathname]
	
	dcmd $pathname stat_file
}
