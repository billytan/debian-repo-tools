#
# IncomingDirRepository.tcl
#

oo::class create IncomingDirRepository {
	superclass DebianRepository
	
	variable	incoming_dir
	
	constructor { _dir args } {
	
		next
	
		set incoming_dir		$_dir
	}
	
	method load_packages { args } {
		
		set count		0
		
		foreach _pathname [glob -directory $incoming_dir -types {f} -nocomplain "*.changes"] {
		
			#
			# NOTE THAT, "package" = "source package"
			#
			my __add_package [my parse_changes_file $_pathname]
		
			incr count; if { $count > 20 } break
		}
	}
	
	
	#
	# OVERLOAD
	#
	#   add support of "-files" option
	#
	proc package { _name args } {
	
		if ![info exists packages($_name)] { return [list] }
	
		if ![getopt $args "-files"] { return $packages($_name) }
		
		#
		# return the list of binary packages
		#
		array set _pkg $packages($_name)
		
		@ foreach _line $_pkg(Files) {
		
			puts "_line = $_line"
			
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
	
}

