#
# DebianRepository
#

#
# base class for Debian repository, consisting of a set of utility routines;
#
oo::class create DebianRepository {

	variable packages 
	variable sources

	variable ARCH
	variable suite
	
	
	constructor { args } {
		
		set suite			"jessie"

		set packages		[list]
		set sources			[list]
	}
	
	#
	# NOTE that, only for source packages, multi-line fields are available
	#
	method parse_package { _text args } {
		
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
		
		return [array get _pkg]	
	}
	

	method foreach_package { arr_name script args } {
		
		upvar $arr_name _pkg
		
		foreach _r $packages {
	
			unset -nocomplain _pkg
			array set _pkg $_r
			
			uplevel 1 $script
		}
	}
	
	method foreach_source_package { arr_name script args } {
	
		upvar $arr_name _pkg
		
		foreach _r $sources {
	
			unset -nocomplain _pkg
			array set _pkg $_r
			
			uplevel 1 $script
		}
	
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
	
		puts "$_output"
	
		array set _arr $_status
	
		if { $_arr(-code) == 0 } { return -1 }
		
		return 1
	}

}





