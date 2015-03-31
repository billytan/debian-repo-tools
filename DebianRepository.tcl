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
			
				#
				# Sanity check: any record MUST begin with a line of "Package:"
				#
				if ![info exists _pkg(Package)] {
					return -code error "invalid source package : $_text"
				}
				
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
		if ![info exists _pkg(Package) ] {
		
			return -code error "invalid source package : $_text"
		}
		
		return [array get _pkg]	
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
	
		return $sources($_name)
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
		if ![info exists sources($_name)] { lappend sources(*) $_name ; set sources($_name) $_r ; return }
		
		#
		# WE NOTICED THAT, the latest version is always the lastest one
		#
		lappend x_sources($_name) $sources($_name)
	
		set sources($_name) $_r
		return
	}
	
	method __add_package { _r } {
	
		array set _pkg $_r
		
		set _name		$_pkg(Package)
		
		if ![info exists packages($_name)] { lappend packages(*) $_name ; set packages($_name) $_r ; return }
		
		puts "WARNING: found a package with multiple versions '$_name' "
		
		lappend x_packages($_name) $packages($_name)
	
		set packages($_name) $_r
	}
}





