#
# import-source-packages.tcl
# 
# Usage:
#     import-source-packages.tcl [ options ]  <Sources-file>
#
# -p <dir>
#     top directory for package pool;
#
# -r <dir>
#     repository directory, default to ./debian
#

set SCRIPT		[file dirname [info script]]
source $SCRIPT/debian_utils.tcl

array set my_args [check_args $argv "-p" "-r" ]

if [info exists my_args(-r)] {
	set repo_dir		[file normalize $my_args(-r)]
} else {
	set repo_dir		[file join [pwd] "debian"]
}

if [info exists my_args(-p)] {
	set pool_dir	[file normalize $my_args(-p)]
} else {
	set pool_dir	[pwd]
}

set packages_file		[lindex $my_args(argv) 0]

#
# if given a compressed file ...
#
set _ext		[file extension [file tail $packages_file]]

switch -exact $_ext {

".gz" { set _chan		[open "| /bin/zcat $packages_file" "r"] }

".xz" { set _chan		[open "| /usr/bin/xzcat $packages_file" "r"] }

".bz2" { set _chan		[open "| /bin/bzcat $packages_file" "r"] }

default { set _chan		[open $packages_file "r"] }

}

# fconfigure $_chan -translation cr
fconfigure $_chan -translation auto

proc get_next_package { chan } {

	unset -nocomplain _arr
	
	while {1} {
		set count		[gets $chan _line]

		if { $count < 0 } {
			return [list]
		}
			
		#
		# the first line MUST begin with "Package:"
		#
		if ![info exists _arr(Package)] {
		
			if { [string first "Package:" $_line] != 0 } {
				return -code error "invalid record found: $_line"
			}
		}
		
		if {$_line == ""} {
			return [array get _arr]
		}
		
		#
		# deal with multi-lines
		#
		if { [string index $_line 0] == " " } {
		
			append _arr($tagname) $_line "\n"
			continue
		}
		
		set j		[string first ":" $_line]
		
		set tagname	[string range $_line 0 [expr $j - 1]]
		
		incr j
		set _value	[string range $_line $j end]
		
		set _arr($tagname) [string trim $_value]
	}
	
	#
	# NEVER REACHED HERE
	#
}

proc check_package { rel_path } {

	set pathname		[file join $::repo_dir $rel_path]
	
	return [file exists $pathname]
}

proc do_import_package { record } {

	array set pkg $record
	
	foreach _line [split $pkg(Files) "\n"] {
	
		foreach {md5sum fsize fname} $_line break
		
		set _ext		[file extension $fname]	
		if {$_ext == ".dsc"} break
	}
	
	set pathname		[file join $::pool_dir $pkg(Directory) $fname]
	
	if ![file exists $pathname] {
		return -code error "failed to find $pathname"
	}
	
	#
	# check if this package is already imported ...
	#
	if [check_package "$pkg(Directory)/$fname"] {
	
		puts "$pkg(Package) already imported, skipped."
		return 0
	}
	
	#puts "exec /usr/bin/reprepro -V -b $::repo_dir includedsc jessie $pathname"
	
	puts "importing $pathname ..."
	
	if [catch {
		exec /usr/bin/reprepro -V -b $::repo_dir includedsc jessie $pathname
	} errmsg] {
		# puts $errmsg
	}
	
	return 1
}

#
# process the package one by one ...
#
set count		0

while {1} {

	set _record		[get_next_package $_chan]
		
	if [is_empty_list $_record] break
	
	#
	# FIXME: add it our local repository
	#
	incr count [do_import_package $_record]
	
	# if {$count > 110} break
}

puts "$count packages added."

#
#  ERROR: child killed: write on pipe with no readers
#
catch {
	close $_chan
}




