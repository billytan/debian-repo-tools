#
# DebianRepository
#

#
# base class for Debian repository, consisting of a set of utility routines;
#
oo::class create DebianRepository {

	variable packages 
	variable sources

	#
	# for those packages with multiple versions ...
	#
	variable x_sources
	variable x_packages
	
	variable ARCH
	variable suite
	
	
	constructor { args } {
		
		set suite			"jessie"

		set packages(*)			[list]
		set sources(*)			[list]
		
		puts "DebianRepository constructor called."
	}
	
	#
	# NOTE that, only for source packages, multi-line fields are available
	#
	method parse_package { _text args } {
		
		#
		# sanity check
		#
		if { [string trim $_text ] == "" } { return [list] }
		
		@ foreach _line $_text {
	
			#
			# deal with multi-lines
			#
			if [begin_with $_line " "] {

				append _pkg($tagname) $_line "\n"
				continue
			}
	
			set j		[string first ":" $_line]
		
			set tagname	[string range $_line 0 [expr $j - 1]]
		
			incr j
			set _value	[string range $_line $j end]
		
			set _pkg($tagname) [string trim $_value]
		}
		
		#
		# sanity check
		#
		if { ![info exists _pkg(Package)] && ![info exists _pkg(Source)] } {
		
			return -code error "invalid source package : $_text"
		}
		
		return [array get _pkg]	
	}
	
	method parse_changes_file { pathname args } {
	
		#
		# for those files signed by buildd, strip off "PGP SIGNED MESSAGE"
		#
		@ read $pathname << "\n\n" { 
	
			if { [string first "Source:" $_ ] > 0 } { set _text $_ ; break }
		}
		
		if ![info exists _text ] { return -code error "invalid .changes file $pathname" }
		
		return [my parse_package $_text ]
	}
	
	
	method foreach_package { arr_name script args } {
		
		upvar $arr_name _pkg
		
		foreach _name $packages(*) {
	
			unset -nocomplain _pkg
			array set _pkg $packages($_name)
			
			uplevel 1 $script
		}
	}
	
	method foreach_source_package { arr_name script args } {
	
		upvar $arr_name _pkg
		
		foreach _name $sources(*) {
	
			unset -nocomplain _pkg
			array set _pkg $sources($_name)
			
			uplevel 1 $script
		}
	
	}

	method package { _name args } {
	
		if ![info exists packages($_name)] { return [list] }
	
		return $packages($_name)
	}

	method source { _name args } {
	
		if ![info exists sources($_name)] { return [list] }
	
		if ![getopt $args "-files"] { return $sources($_name) }
		
		#
		# return the list of source files
		#
		array set _pkg $sources($_name)
		
		@ foreach _line $_pkg(Files) {
		
			regexp {(\S+)\s+(\S+)\s+(\S+)} $_line _x _md5sum _fsize _fname
			
			lappend result $_fname
			
			if [getopt $args -size] { lappend result $_fsize  }
		}
		
		return $result
	}

	
	method __remove_source_package { _name args } {

		unset -nocomplain sources($_name)
	
		set j		[lsearch -exact $sources(*) $_name]
		
		if { $j >= 0 } { set sources(*) [lreplace $sources(*) $j $j ] }	
	}
	
	#
	#  for the same version, return 0;
	#
	#  if $ver1 is "lower than" $ver2, return -1; otherwise return 1;
	#
	method compare_version { ver1 ver2 } {

		#
		# in the simplest case ...
		#
		if { $ver1 == $ver2 } { return 0 }
		
		catch {
			exec /usr/bin/dpkg --compare-versions $ver1 lt $ver2
		} _output _status
	
		#
		# check for error message
		#
		if { [string first "child process exited abnormally" $_output] >= 0 } {
			
			#
			# it is what exactly we are expecting ...
			#
			return 1
		}
	
		array set _arr $_status
	
		if { $_arr(-code) == 0 } { return -1 }
		
		return 1
	}


	#
	# if we call "compare_version" to check, untolerably slow as we are dealting with 20197 packages ...!!!
	#
	method __add_source_package { _r } {
	
		array set _pkg $_r
		
		set _name		$_pkg(Package)
		
		#
		# check if a different version exists ...
		#
		if ![info exists sources($_name)] { lappend sources(*) $_name ; set sources($_name) $_r ; return $_name }
		
		#
		# FOR DEBUG PURPOSE
		#
		# array set _arr $sources($_name)
		# puts "\n x_source $_arr(Package) $_arr(Version)\n"
		
		#
		# WE NOTICED THAT, the latest version is always the lastest one
		#
		lappend x_sources($_name) $sources($_name)
	
		set sources($_name) $_r
		return $_name
	}
	
	method __add_package { _r } {
	
		array set _pkg $_r
		
		#
		# add support for .changes file, as required by IncomingDirRepository
		#
		if [info exists _pkg(Package)] { set _name $_pkg(Package) } else { set _name $_pkg(Source) }
		
		if ![info exists packages($_name)] { lappend packages(*) $_name ; set packages($_name) $_r ; return $_name }
		
		puts "WARNING: found a package with multiple versions '$_name' "
		
		lappend x_packages($_name) $packages($_name)
	
		set packages($_name) $_r
		
		return $_name
	}
	
	
		#
	# [OPTIONAL]
	#
	# show a progress message, "loading 35% "
	#
	method load_big_file { _chan args } {
	
	
	
	}
	

	method open_zipped_file { pathname } {

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
	
}





