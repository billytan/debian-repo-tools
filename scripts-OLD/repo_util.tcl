#
# repo_util.tcl
#

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


#
# **** FIXME **** .... something wrong with this routine !!!
#
proc load_packages { arr pathname } {

	upvar $arr _arr
	
	set result		[list]
	
	set _chan		[open_zipped_file $pathname]
	
	while {1} {
	
		set _txt		[get_next_item $_chan]
		if {$_txt == ""} break
		
		# debug_log $_txt
		
		unset -nocomplain pkg
		
		array set pkg [parse_package $_txt]
		
		set _name		$pkg(Package)
		
		# debug_log "$_name $pkg(Version)"
		
		if [info exists _arr($_name)] {
		
			array set _old [set _arr($_name)]
			
			# debug_log "WARNING: duplicate package found : $_name $_old(Version) | $pkg(Version)"

			set retcode		[compare_version $pkg(Version) $_old(Version)]
		
			if {$retcode == 0} continue
		
			# debug_log "$_name UPDATE $pkg(Version)"
		}
		
		set _arr($_name) [array get pkg]
		lappend result $_name
	}
	
	#
	# FIXME
	#	child killed: write on pipe with no readers
	#
	close $_chan
	
	return $result
}



proc load_packages_NEW { arr pathname } {

	upvar $arr _arr
	
	set result		[list]
	
	set _chan		[open_zipped_file $pathname]

	while {1} {

		set record		[get_next_package $_chan]

		if [is_empty_list $record] break
		
		unset -nocomplain pkg
		
		array set pkg $record
		
		set _name		$pkg(Package)
	
		# debug_log "Package: $_name"
		
		if [info exists _arr($_name)] {
		
			array set _old [set _arr($_name)]
			
			# debug_log "WARNING: duplicate package found : $_name $_old(Version) | $pkg(Version)"

			set retcode		[compare_version $pkg(Version) $_old(Version)]
		
			if {$retcode == 0} continue
		
			# debug_log "$_name UPDATE $pkg(Version)"
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


proc parse_source_package { _txt args } {


	foreach _line [split $_txt "\n"] {

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
	
	return [array get _arr]
}

#
# 在 Sources.gz 中有多个不同版本的 glibc 软件包
#
proc load_source_packages { arr pathname args } {

	upvar $arr _arr

	set result		[list]
	
	set _chan		[open_zipped_file $pathname]
	
	while {1} {
	
		set _txt		[get_next_item $_chan]
		if {$_txt == ""} break
		
		# debug_log $_txt
		
		unset -nocomplain pkg
		
		array set pkg [parse_source_package $_txt]
		
		set _name		$pkg(Package)
		
		#
		# check if found a package with a different package ...
		#
		if [info exists _arr($_name)] {
		
			debug_log "WARNING: found a package \"$_name\" with multiple versions: $pkg(Version)"
		} else {
		
			lappend result $_name
		}
		
		#
		# NOTE: as we observed that, the last one is always the most updated one 
		#
		set _arr($_name)		[array get pkg]
		
		#
		# FOR DEBUG PURPOSE
		#
		# incr ::count
		# if { $::count > 3 } break
	}
	
	catch { close $_chan }
	
	return $result
}


proc deb_diff { deb_file old_file args } {
	
	array set pkg [get_deb_control $deb_file]
	array set _his [get_deb_control $old_file]

	set result		"OK"
	
	foreach _name { Depends Pre-Depends Breaks Provides Conflicts Multi-Arch Priority } {
	
		if ![info exists pkg($_name)] {
			if ![info exists _his($_name)] { 
				# append result " !$_name"
				continue
			}
			
			return $_name
		}
		
		if { $pkg($_name) == $_his($_name) } continue
		
		return $_name
	}

	return $result
}

proc deb_extract { deb_file _dir args } {
	
	exec /usr/bin/dpkg-deb -x $deb_file	$_dir
	
	set meta_dir		[file join $_dir "DEBIAN"]
	file mkdir $meta_dir
	
	exec /usr/bin/dpkg-deb -e $deb_file $meta_dir
	
	return $_dir
}

proc get_deb_control { deb_file args } {

	catch {
		exec /bin/mktemp -d -p /tmp "deb-XXXX"
	} tmp_dir
	
	deb_extract $deb_file $tmp_dir
	
	foreach _line [load_file "$tmp_dir/DEBIAN/control"] {
	
		set RE		{^([-\w]+):(.*)}
	
		if [regexp $RE $_line X _name _value] {
			set pkg($_name)		$_value
		}
	}
	
	file delete -force $tmp_dir
	
	return [array get pkg]
}



proc dcmd { meta_file cmd args } {

	set _dir			[file dirname $meta_file]
	
	set skip_line		1
	
	set _files			[list]
	
	foreach _line [load_file $meta_file] {

		if { $_line == "Files:" } {
			set skip_line	0
			continue
		}
		
		if $skip_line continue
		
		# puts "LINE: $_line"
		
		if ![regexp {\s(\S+)$} $_line x _fname] continue
		
		#
		# deal with this file ...
		#
		set _pathname		[file join $_dir $_fname]
		
		eval [list $cmd $_pathname ] $args
	}
	
	#
	# deal with the meta-file itself 
	#
	eval [list $cmd $meta_file] $args
	
	return
}



