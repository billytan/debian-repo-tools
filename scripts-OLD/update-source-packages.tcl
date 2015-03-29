#
# update-source-packages.tcl
# 
# Usage:
#    update-source-packages.tcl -b $REPO_DIR -M $MIRROR_DIR -L $LOG_FILE [ <list-file> ]
#

set PROGNAME		"update-source-packages"

set SCRIPT		[file dirname [info script]]

source $SCRIPT/common_util.tcl
source $SCRIPT/repo_util.tcl

#
# provided by shell script
#
array set my_args [check_args $argv "-b" "-M" "-L" ]

set repo_dir		[file normalize $my_args(-b)]
set mirror_dir		[file normalize $my_args(-M)]

set _log_file		[file normalize $my_args(-L)]

#
# just create a list of source pacakges to be updated;
#
set list_file		""

foreach list_file $my_args(argv) break

if {$list_file != "" } {
	set _log_file		$list_file
}

set ::LOG_FILE		[open $_log_file "w+"]

proc LOG { txt } {

	puts -nonewline $::LOG_FILE $txt
	flush $::LOG_FILE
}


#
# load the list of source packages
#
set pathname		"$mirror_dir/dists/jessie/main/source/Sources.gz" 

debug_log "loading $pathname ..."

set his(packages,list)		[load_source_packages his $pathname]

set count		[llength $his(packages,list) ]
debug_log "$count source packages loaded."


#
# to check against with those in local repo
#
set pathname		"$repo_dir/dists/jessie/main/source/Sources.gz" 

debug_log "loading $pathname ..."

set my(packages,list)		[load_source_packages my $pathname]

set count		[llength $my(packages,list) ]
debug_log "$count source packages loaded."


proc do_import_package { _name args } {
	
	log_package_update $_name

	if { $::list_file != "" } return
	
	array set pkg $::his($_name)

	foreach _line [split $pkg(Files) "\n"] {
	
		foreach {md5sum fsize fname} $_line break
		
		set _ext		[file extension $fname]	
		if {$_ext == ".dsc"} break
	}
	
	set pathname		[file join $::mirror_dir $pkg(Directory) $fname]
	
	if ![file exists $pathname] {
		return -code error "failed to find $pathname"
	}
	
	debug_log "importing $fname ..."
	
	LOG "IMPORT $fname \n"
	
	if [catch {
		exec /usr/bin/reprepro -V -b $::repo_dir includedsc jessie $pathname
	} errmsg] {
		LOG "$errmsg\n"
	}
	
	LOG "\n"
}

proc log_package_update { _name } {

	array set pkg $::his($_name)

	LOG "Package: $_name\n"
	LOG "Version: $pkg(Version)\n"

	if [info exists ::my($_name)] {
	
		array set _pkg $::my($_name)
	
		LOG "Version-original: $_pkg(Version)\n"
	}
	
	LOG "\n"
}

set count		0

foreach pkgname $his(packages,list) {

	# debug_log "checking $pkgname ..."

	unset -nocomplain pkg
	array set pkg $his($pkgname)

	if ![info exists my($pkgname) ] {
	
		do_import_package $pkgname
		
		incr count
		continue
	}
	
	#
	# skip it if found one with the same version
	#
	unset -nocomplain _pkg
	array set _pkg $my($pkgname)
	
	if { $pkg(Version) == $_pkg(Version) } {
		# debug_log "OK"
		
		continue
	}
	
	#
	# update it
	#
	do_import_package $pkgname
	
	incr count
}

debug_log "$count packages updated."


