#
# import-packages.tcl
# 
# Usage:
#     import-packages.tcl [ options ]  <Packages-file>
#
# -p <dir>
#     top directory for package pool;
#
# -r <dir>
#     repository directory, default to ./debian
#
# -l <list-file>
#     list of the packages we have processed;
#

set SCRIPT		[file dirname [info script]]
source $SCRIPT/debian_utils.tcl

array set my_args [check_args $argv "-p" "-r" "-l" ]

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



proc load_list_file { pathname } {
	set _chan		[open $pathname "r"]
	
	foreach _line [split [read $_chan] "\n"] {
	
		lappend ::skip_them $_line
	}
	
	close $_chan
}

proc dump_list_file { pathname } {
	set _chan		[open $pathname "w"]
	
	foreach item $::skip_them {
		puts $_chan $item
	}
	
	close $_chan
}

set skip_them		[list]

if [info exists my_args(-l)] {
	load_list_file $my_args(-l)
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

	set result		[list]
	
	while {1} {
		set count		[gets $chan _line]

		if { $count < 0 } {
			return $result
		}
			
		#
		# the first line MUST begin with "Package:"
		#
		if [is_empty_list $result] {
		
			if { [string first "Package:" $_line] != 0 } {
				return -code error "invalid record found: $_line"
			}
		}
		
		if {$_line == ""} {
			return $result
		}
		
		set j		[string first ":" $_line]
		
		set _name	[string range $_line 0 [expr $j - 1]]
		
		incr j
		set _value	[string range $_line $j end]
		
		lappend result $_name [string trim $_value]
	}
	
	#
	# NEVER REACHED HERE
	#
}

proc check_package { record } {

	array set pkg $record

	set pathname		[file join $::repo_dir $pkg(Filename)]
	
	return [file exists $pathname]
}

proc do_import_package { record } {

	array set pkg $record
	
	#
	# sanity check
	#
	if ![info exists pkg(Package)] {
		puts "ERROR: invalid record: $record"
		return 0
	}
	
	if ![info exists pkg(Filename)] {
		puts "ERROR: invalid record: $record"
		return 0
	}
	
	# puts "$pkg(Package) : $pkg(Filename)"
	set pathname		[file join $::pool_dir $pkg(Filename)]
	
	if ![file exists $pathname] {
		return -code error "failed to find $pathname"
	}
	
	#
	# check if this package is already imported ...
	#
	if [check_package $record] {
		#puts "... $pkg(Package)"
		
		return 0
	}
	
	#
	# check if ever processed but failed to import ...
	#
	if { [lsearch $::skip_them $pkg(Filename)] >= 0 } {
		return 0
	}
	
	set _ext		[file extension $pkg(Filename)]

	set _cmd		"includedeb"
	
	if {$_ext == ".udeb"} {
		set _cmd		"includeudeb"
	}
	
	if [catch {
		exec /usr/bin/reprepro -V -b $::repo_dir $_cmd jessie $pathname
	} errmsg] {
		# puts $errmsg
	}
	
	#
	# check if imported successfully; if not, add it to Skip List ...
	#
	if ![check_package $record] {
		lappend ::skip_them $pkg(Filename)
		
		puts "--- $pkg(Package)"
		return 0
	}
	
	puts "OK $pkg(Filename)"
	
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
	
	# if {$count > 1000} break
}

puts "$count packages added."

#
#  ERROR: child killed: write on pipe with no readers
#
catch {
	close $_chan
}

if [info exists my_args(-l)] {
	dump_list_file $my_args(-l)
}

exit

