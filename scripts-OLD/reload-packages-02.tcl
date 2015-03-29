#
# reload-packages-02.tcl
#

set SCRIPT		[file dirname [info script]]

source $SCRIPT/common_util.tcl
source $SCRIPT/repo_util.tcl

array set my_args [check_args $argv "-b" "-l" "-r"]

set repo_dir		[file normalize $my_args(-b)]
set pool_dir		[file normalize $my_args(-r)]

set list_file		[file normalize $my_args(-l)]

set packages_file		[lindex $my_args(argv) 0]

#
# 读取 $list_file 中的 packages list
#
set result			[list]

foreach _line [load_file $list_file] {
	
	set RE		{^Package:\s(\S+)}
	
	if ![regexp $RE $_line x _name] continue
	
	lappend result $_name 
}


debug_log "loading $packages_file ... please wait"

set all_packages		[load_packages his $packages_file]

foreach _name $result {

	if ![info exists his($_name)] continue
	
	unset -nocomplain pkg
	array set pkg $his($_name)
	
	set pathname		[file join $::pool_dir $pkg(Filename)]
		
	set his($_name,deb)		$pathname
}

set _pathname			[file join $repo_dir "dists/jessie/main/binary-ppc64/Packages.gz"]

debug_log "loading $_pathname ... please wait"
load_packages my $_pathname

proc do_reload_package { pkgname deb_file args } {
	global my his

	unset -nocomplain pkg
	array set pkg $my($pkgname)

	set my_deb_file		[file join $::repo_dir $pkg(Filename)]
	
	#
	# 比较它们的 meta-data
	#
	set retcode		[ deb_diff $my_deb_file $deb_file ]
	
	puts [format "%-120s %s" $pkg(Filename) $retcode]
}


foreach _name $result {

	if ![info exists his($_name,deb)] {

		puts "ERROR: failed to find $_name ($_ver) package"
		continue
	}
	
	do_reload_package $_name $his($_name,deb)
}


