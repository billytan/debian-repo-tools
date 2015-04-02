#
# IncomingDirRepository.tcl
#

oo::class create IncomingDirRepository {
	superclass DebianRepository
	
	variable	incoming_dir
	
	variable	__changes
	
	constructor { _dir args } {
	
		#
		# invoke base class constructor
		#
		next
	
		set incoming_dir		$_dir
	}
	
	method load_packages { args } {
		
		set count		0
		
		foreach _pathname [glob -directory $incoming_dir -types {f} -nocomplain "*.changes"] {
		
			incr count; if [getopt $args "-verbose"] { show_progress "loading %5d" $count }
			
			#
			# NOTE THAT, "package" = "source package"
			#
			set _name		[my __add_package [my parse_changes_file $_pathname] ]
		
			# @file $_name > /tmp/changes.txt
			
			#
			# WE HAVE TO KEEP IT 
			#
			set __changes($_name)			[file tail $_pathname]
			
			# if { $count > 20 } break
		}
		
		if [getopt $args "-verbose"] { puts "$count packages loaded." }
	}
	
	
	#
	# OVERLOAD
	#
	#   add support of "-files" option
	#
	method package { _name args } {
		variable	packages

		# puts "CALL package $_name $args"
		
		if ![info exists packages($_name)] { return [list] }

		if [getopt $args "-changes"] { return $__changes($_name) }
	
		if ![getopt $args "-files"] { return $packages($_name) }
		
		#
		# return the list of binary packages
		#
		array set _pkg $packages($_name)
		
		@ foreach _line $_pkg(Files) {
		
			# puts "_line = $_line"
			
			regexp {(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)} $_line _x _md5sum _fsize _x _x _fname
			
			lappend result $_fname
			
			if [getopt $args -size] { lappend result $_fsize  }
		}
		
		return $result
	}
	
	#
	# dealing with .dsc files
	#
	method load_source_packages { args } {
	
	
	}
	

	
}

