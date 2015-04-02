#
# DebianRemoteRepository.tcl
#

oo::class create DebianRemoteRepository {
	superclass DebianRepository
	
	variable	cache_obj
	
	constructor { _url _suite args } {
	
		set cache_obj		[eval [list DebianRepositoryCache new $_url $_suite] $args]
	
		#
		# invoke baseclass constructor
		#
		next

	}
	
	method load_packages { args } {

		#
		# get a detailed list of packages available in the target respository
		#
		set result		[$cache_obj apt-cache dumpavail]
		
		set count		0
		
		@ foreach _r $result << "\n\n" {
		
			my __add_package [my parse_package $_r]
	
			incr count
			
			if [getopt $args "-verbose"]  { show_progress "Loading packages %6d" $count }
			
			#
			# NOT SURE IF "break" will work ... IT WORKS WELL !!!
			#
			# if { $count > 1000 } break
		}
		
		if [getopt $args "-verbose"]  { puts "$count packages loaded." }
	}
	
	#
	# get a specified package
	#
	method download { _pkgname args } {
	
		$cache_obj apt-get download $_pkgname
		
		#
		# FIXME:
		#   check if any error message ...
		#
		array set _pkg [my package $_pkgname ]
		
		# parray _pkg
		# Filename: pool/main/a/alien/alien_8.93_all.deb
		#
		set _fname			[file tail $_pkg(Filename)]
		
		set pathname		[file join [pwd] $_fname ]
		
		if ![file exists $pathname] {
			return -code error "failed to download $_pkg(Filename) "
		}
		
		return $pathname
	}
	
	destructor {
		$cache_obj destroy
	}
	
}




