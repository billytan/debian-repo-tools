#
# docbase_util.tcl
#

proc debug_log { line } {

	puts $line
	flush stdout
}

proc log_to_file { log_file args } {

	set _chan		[open $log_file "a+"]

	puts $_chan [join $args " "]
	close $_chan
}


proc is_empty_list { _v } {

	if { [llength $_v] == 0 } {
		return 1
	}
	
	return 0
}

proc begin_with { line _name } {

	if { [string first $_name $line] == 0 } {
		return 1
	}
	
	return 0
}



#
# unwilling to introduce a dependency on Tcllib
#
proc check_args { _args args } {
	
	set j	-1
	
	while {1} {
		incr j
		
		if { $j < [llength $_args] } {
			set _v		[lindex $_args $j]
	
			#
			# check if this is a pre-defined option
			#
			if { [lsearch -exact $args $_v] >= 0 } {
				incr j
				set _arr($_v)			[lindex $_args $j]
			
				continue
			}
		}
		
		set _arr(argv)		[lrange $_args $j end]
		break
	}
	
	set _arr(argc)		[llength $_arr(argv)]
	
	return [array get _arr]
}


proc open_zipped_file { pathname } {

	#
	# if given a compressed file ...
	#
	set _ext		[file extension [file tail $pathname]]

	switch -exact $_ext {

	".gz" { set _chan		[open "| /bin/zcat $pathname" "r"] }

	".xz" { set _chan		[open "| /usr/bin/xzcat $pathname" "r"] }

	".bz2" { set _chan		[open "| /bin/bzcat $pathname" "r"] }

	default { set _chan		[open $pathname "r"] }

	}

	# fconfigure $_chan -translation cr
	fconfigure $_chan -translation auto

	return $_chan
}

#
# ... like Perl paragraph mode 
#
proc get_next_item { chan } {

	set _lines			[list]

	while {1} {
		set count		[gets $chan _line]

		if { $count < 0 } {
			if [is_empty_list $_lines] {
				return ""
			}
			
			return [join $_lines "\n"]
		}
		
		if {$_line == ""} {
			return [join $_lines "\n"]
		}

		lappend _lines $_line
	}

	#
	# NEVER REACHED HERE
	#	
}

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


proc parse_package { record } {

	set result		[list]
	
	foreach _line [split $record "\n"] {

		set j		[string first ":" $_line]
		
		set _name	[string range $_line 0 [expr $j - 1]]
		
		incr j
		set _value	[string range $_line $j end]
		
		lappend result $_name [string trim $_value]
	}
	
	return $result
}

proc load_packages_file { pathname } {

	set _chan		[open_zipped_file $pathname]

	set result		[list]
	
	while {1} {
	
		set _txt		[get_next_item $_chan]
		if {$_txt == ""} break
		
		lappend result [parse_package $_txt]
	}
	
	close $_chan
	
	return $result
}


proc compare_version { ver1 ver2 } {

	catch {
		exec /usr/bin/dpkg --compare-versions $ver1 lt $ver2
	} _output _status
	
	array set status $_status
	
	return $status(-code)
}

proc load_packages { arr pathname } {

	upvar $arr _arr
	
	set result		[list]
	
	set _chan		[open_zipped_file $pathname]
	
	while {1} {
	
		set _txt		[get_next_item $_chan]
		if {$_txt == ""} break
		
		unset -nocomplain pkg
		
		array set pkg [parse_package $_txt]
		
		set _name		$pkg(Package)
		
		if [info exists _arr($_name)] {
		
			array set _old [set _arr($_name)]
			
			debug_log "WARNING: duplicate package found : $_name $_old(Version) | $pkg(Version)"

			set retcode		[compare_version $pkg(Version) $_old(Version)]
		
			if {$retcode == 0} continue
		
			debug_log "$_name UPDATE $pkg(Version)"
		}
		
		set _arr($_name) [array get pkg]
		lappend result $_name
	}
	
	close $_chan
	
	return $result
}


proc get_next_source_package { chan } {

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

