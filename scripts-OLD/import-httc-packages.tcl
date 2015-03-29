#
# import-httc-packages.tcl
#
# Usage:
#     import-httc-packages.tcl -b $REPO_DIR -L <log-file> { <incoming-dir> | *.deb }
#

set SCRIPT		[file dirname [info script]]

source $SCRIPT/common_util.tcl
source $SCRIPT/repo_util.tcl

#
# provided by shell script
#
array set my_args [check_args $argv "-b" "-L"]

set repo_dir		[file normalize $my_args(-b)]

set _log_file		[file normalize $my_args(-L)]

set ::LOG_FILE		[open $_log_file "w+"]

proc LOG { txt } {

	puts -nonewline $::LOG_FILE $txt
	flush $::LOG_FILE
}

proc debug_log { msg args } {

	LOG "$msg\n"
	
	puts $msg
}


# ---------------------------- incoming process -------------------------

proc process_incoming_dir { _dir args }  {


	#
	# .changes 的文件列表中，包括 source code files; 必须先处理 ...
	#
	foreach changes_file [glob -dir $_dir -type f -nocomplain "*.changes"] {
	
		import_package $changes_file
		
		#
		# move to "backup/"
		#
		do_backup_package $changes_file	-remove
	}

	return
	
	#
	# 先处理 source packages ...
	#
	foreach dsc_file [glob -dir $_dir -type f -nocomplain "*.dsc"] {

		import_source_package $dsc_file
		
		#
		# move to "backup/"
		#
		do_backup_package $dsc_file -remove
	}
	
	#
	# finally,deal with standalone .deb files
	#
	import_debs [glob -dir $_dir -type f -nocomplain "*.deb"] -remove
	
	import_debs [glob -dir $_dir -type f -nocomplain "*.udeb"] -remove
}


proc import_debs { deb_files args } {

	debug_log "import_debs $deb_files $args"
	
	foreach deb_file $deb_files {

		set _cmd		"includedeb"
		set _ext		[file extension $deb_file]
		
		if { $_ext == ".udeb" } {
			set _cmd		"includeudeb"
		}
		
		if [catch {
			exec /usr/bin/reprepro -V -b $::repo_dir $_cmd jessie $deb_file
		} errmsg] {
			debug_log $errmsg
		}
	
		eval [list do_backup_file $deb_file] $args
	}
}


proc check_reprepro_errmsg { errmsg } {


	if { [string first "errors" $errmsg] < 0 } return
	
	return -code error $errmsg
}

proc import_package { changes_file args } {

	debug_log "import_package $changes_file $args"
	
	#
	# the existing one MUST be removed at first ...
	#
	array set pkg [parse_package $changes_file]
	
	catch {
	
		exec /usr/bin/reprepro -V -b $::repo_dir remove $pkg(Source)
	} errmsg
	
	check_reprepro_errmsg $errmsg
	
	#
	# possibly, got a package built for unstable
	#
	if [catch {
		exec /usr/bin/reprepro -V --ignore=wrongdistribution -b $::repo_dir include jessie $changes_file
	} errmsg] {
		debug_log $errmsg
	}

	check_reprepro_errmsg $errmsg
}

proc import_source_package { dsc_file args } {

	debug_log "import_source_package $dsc_file $args"

	if [catch {
		exec /usr/bin/reprepro -V --ignore=wrongdistribution -b $::repo_dir includedsc jessie $dsc_file
	} errmsg] {
		debug_log $errmsg
	}

}


proc do_backup_package { pathname args } {


	eval [list dcmd $pathname do_backup_file] $args

}

proc do_backup_file { pathname args } {

	return
	
	set _fname		[file tail $pathname]

	set target_file		[file join $::repo_dir "backup" $_fname]
	
	#
	# overwite the old file if exists
	#
	file copy -force $pathname $target_file
	
	if { [lsearch $args -remove] >= 0 } {
		file delete $pathname
	}
}


# ------------------------------ main part -------------------------------


#
# first, loading the list of (source) packages in our repository
#

if 0 {
set my(Packages)		[file join $repo_dir "dists/jessie/main/binary-ppc64/Packages"]

puts "loading $my(Packages) ... "

set my(packages,list)		[load_packages my $my(Packages)]

	set count		[llength $my(packages,list)]
	puts "$count packages found."

set my(Sources)			[file join $repo_dir "dists/jessie/main/source/Sources.gz"]

set count			0

set my(sources,list)		[load_source_packages my $my(Sources) ]

	set count		[llength $my(sources,list)]
	puts "$count source packages found."
}

#
# kick off the core processing ...
#

foreach p $my_args(argv)  {

	if [file isdirectory $p ] {
		process_incoming_dir		$p
		break
	}

	#
	# if provided with multiple .deb files ...
	#
	import_debs $my_args(argv)
	
	break
}



