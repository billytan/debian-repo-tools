#
# import-packages_NEW.tcl
# 
# Usage:
#     import-packages_NEW.tcl -r $POOL_DIR -b $REPO_DIR -f <installed-Packages-file> <Packages-file>
#

set SCRIPT		[file dirname [info script]]

source $SCRIPT/common_util.tcl
source $SCRIPT/repo_util.tcl

array set my_args [check_args $argv "-b" "-r" "-f"]

set repo_dir		[file normalize $my_args(-b)]
set pool_dir		[file normalize $my_args(-r)]

set pathname		[file normalize $my_args(-f)]

set packages_file		[lindex $my_args(argv) 0]


#
# first, get the list of packages already installed in our own repository
#
debug_log "loading packages $pathname .... please wait"

set result		[load_packages my $pathname]
set my(packages)	$result

set count		[llength $result]
puts "$count packages found in $pathname"

proc debug_log_XXX { line } {

	log_to_file "import-packages.log" $line
}


debug_log "loading packages $packages_file .... please wait"

set result		[load_packages his $packages_file]
set his(packages)	$result

set count		[llength $result]
puts "$count packages found in $packages_file"

proc do_import_package { pkgname args } {
	global his
	
	debug_log "do_import_package $pkgname $args"
		
	#
	# remove the old one if existed
	#
	if { [lsearch $args "-overwite"] >= 0 } {
	
		do_remove_package $pkgname
	}
	
	array set pkg $his($pkgname)
		
	set _ext		[file extension $pkg(Filename)]

	set _cmd		"includedeb"
	
	if {$_ext == ".udeb"} {
		set _cmd		"includeudeb"
	}
	
	catch {
		exec /usr/bin/reprepro -V -b $::repo_dir $_cmd jessie [file join $::pool_dir $pkg(Filename)]
	} errmsg
	
	debug_log "\n\n $errmsg \n\n"
	
	#
	# FIXME: check for errors
	#
	
	debug_log "$pkg(Filename) imported."
	
	incr ::count
	
	# puts [format "OK %50s %s" $pkgname $pkg(Version)]
	#
	# "$-50s" for left-aligned
	#
	puts [format "OK %-50s %s" $pkgname $pkg(Version)]
		
	#
	# FOR DEBUG PUROSE
	#
	# if { $::count > 3 } exit
}


proc do_remove_package { pkgname } {
	global  my
	
	debug_log "removing $pkgname ..."
	
	catch {
		exec /usr/bin/reprepro -V -b $::repo_dir remove jessie $pkgname
	} errmsg
	
	debug_log "\n\n $errmsg \n\n"
	
	debug_log "      $pkgname removed."
	
	incr my(updated)
}


#
# now, check if any new or updated packages 
#
set count		0

set my(updated)		0

foreach pkgname $his(packages) {
	
	if ![info exists my($pkgname)] {
		do_import_package $pkgname
		
		continue
	}
	
	#
	# compare version
	#
	unset -nocomplain pkg
	unset -nocomplain _his
	
	array set pkg [set my($pkgname)]

	array set _his [set his($pkgname)]
	
	if { $_his(Version) == $pkg(Version) } continue
	
	set retcode		[compare_version $_his(Version) $pkg(Version)]
	
	if { $retcode == 0 } continue
	
	do_import_package $pkgname -overwrite
}

puts "$count packages added."
puts "$my(updated) packages updated."


