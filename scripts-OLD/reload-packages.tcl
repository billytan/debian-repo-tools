#
# reload-packages.tcl
#
#     从 Debian mirror 中拷贝一组 packages，到 baixibao 库；
#
# Usage:
#	reload-packages.tcl -b $REPO_DIR -l <list-file> -r $POOL_DIR <Packages-file>
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

	set RE		{\s(\S+)\s(\S+)$}

	if { [string first "Retrieving" $_line] < 0 } continue
	
	if ![regexp $RE $_line x _name _ver] continue
	
	lappend result $_name $_ver

}


debug_log "loading $packages_file ... please wait"

set all_packages		[load_packages his $packages_file]

foreach {_name _ver} $result {

	# puts "checking $_name $_ver ..."

	if ![info exists his($_name)] continue
	
	unset -nocomplain pkg
	array set pkg $his($_name)
	
	if {$pkg(Version) != $_ver } continue
	
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


foreach {_name _ver} $result {

	if ![info exists his($_name,deb)] {

		puts "ERROR: failed to find $_name ($_ver) package"
		continue
	}
	
	do_reload_package $_name $his($_name,deb)
}


