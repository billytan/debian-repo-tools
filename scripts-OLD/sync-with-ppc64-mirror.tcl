#
# sync-with-ppc64-mirror.tcl
#
#
# Usage:
#     sync-with-ppc64-mirror.tcl -b $REPO_DIR -M $MIRROR_DIR -L <log-file>
#

set PROGNAME		"sync-with-ppc64-mirror"

set SCRIPT		[file dirname [info script]]

source $SCRIPT/common_util.tcl
source $SCRIPT/repo_util.tcl

#
# provided by shell script
#
array set my_args [check_args $argv "-b" "-M" "-L"]

set repo_dir		[file normalize $my_args(-b)]
set mirror_dir		[file normalize $my_args(-M)]

set _log_file		[file normalize $my_args(-L)]


set ::LOG_FILE		[open $_log_file "w+"]

proc LOG { txt } {

	puts -nonewline $::LOG_FILE $txt
	flush $::LOG_FILE
}

proc debug_log { msg args } {

	LOG "$msg\n"
	
	puts $msg
	flush stdout
}

#
# 读取 包库的 Packages.gz 文件
#

set my(Packages)		[file join $repo_dir "dists/jessie/main/binary-ppc64/Packages"]

set MIRROR(Packages)			[file join $mirror_dir "dists/sid/main/binary-ppc64/Packages.gz"]

debug_log "loading $my(Packages) ... "

set my(packages,list)		[load_packages my $my(Packages)]

	set count		[llength $my(packages,list)]
	debug_log "$count packages found."


debug_log "loading $MIRROR(Packages) ... "

set MIRROR(packages,list)		[load_packages MIRROR $MIRROR(Packages)]

	set count		[llength $MIRROR(packages,list)]
	debug_log "$count packages found."


#
# check each package .... if any version changes
#
debug_log "checking for removed packages ...\n"

foreach _name $my(packages,list) {

	#
	# in case of removed packages ...
	#
	if [info exists MIRROR($_name)] continue
	
	LOG "Package: $_name\nAction: removed\n\n"
		
	#
	# TODO:
	#   move it to "outdated/"
	#
	
}

proc do_remove_package { _name args } {
	global my
	
	debug_log "do_remove_package $_name $args"

	array set pkg $my($_name)
	
	#
	# first, save a copy of this package in "outdated/"
	#
	set _pathname		[file join $::repo_dir $pkg(Filename)]
	
	set _fname			[file tail $_pathname]
	
	set saved_file		[file join $::repo_dir "outdated" $_fname]
	
	if ![file exists $saved_file] {
	
		file copy $_pathname $saved_file
		
		debug_log "$saved_file copied."
		
		incr ::count
	}
	
	#
	# then, remove it from baixibao repo
	#
	catch {
		exec /usr/bin/reprepro -V -b $::repo_dir remove jessie $_name
	} errmsg
}


#
# 重新导入一个包 ...
#
proc do_import_package { _name args } {
	global MIRROR
	
	debug_log "do_import_package $_name $args"

	array set pkg $MIRROR($_name)
		
	set _ext		[file extension $pkg(Filename)]

	set _cmd		"includedeb"
	
	if {$_ext == ".udeb"} {
		set _cmd		"includeudeb"
	}
	
	catch {
		exec /usr/bin/reprepro -V -b $::repo_dir $_cmd jessie [file join $::mirror_dir $pkg(Filename)]
	} errmsg
	
	debug_log "\n\n $errmsg \n\n"
	
	#
	# FIXME: check for errors
	#
	
	debug_log "$pkg(Filename) imported."

	incr ::count
}


puts "checking for updated packages ...\n"

set count		0

foreach _name $MIRROR(packages,list) {

	unset -nocomplain _pkg
	array set _pkg $MIRROR($_name)

	if [info exists my($_name)] {
	
		unset -nocomplain pkg
		array set pkg $my($_name)
	
		if { $pkg(Version) == $_pkg(Version) } continue
		
		#
		# remove the old one if existed
		#
		do_remove_package $_name
	}
	
	do_import_package $_name

	#
	# FOR DEBUG PURPOSE
	#
	# if { $count > 3 } break
}


close $::LOG_FILE

puts "\n\n$_log_file created."


