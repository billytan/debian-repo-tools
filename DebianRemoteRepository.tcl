#
# DebianRemoteRepository.tcl
#

oo::class create DebianRemoteRepository {
	superclass DebianRepository
	
	variable	cache_obj
	
	constructor { _url _suite args } {
		variable		suite
		variable		ARCH
		
		set cache_obj		[eval [list DebianRepositoryCache new $_url $_suite] $args]
	
		#
		# invoke baseclass constructor
		#
		next

		set suite		$_suite
		
		set _s		[getopt $args "--arch=%s"]
		if { $_s != "" } { set ARCH $_s }
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
			#
			# FOR DEBUG PURPOSE
			#
			set _limit		[getopt $args "--limit=%s" ]
			
			if { $_limit != "" } { if { $count > $_limit } break }
		}
		
		if [getopt $args "-verbose"]  { puts "$count packages loaded." }
	}
	
	#
	# for each source package, we have to make sure that all the related binary packages 
	# are available in this repository
	#
	method scan_sources { args } {
		variable	packages
		variable	sources
		
		set count		0
		
		my foreach_package _pkg {
		
			set _name		$_pkg(Package)
			
			if [info exists _pkg(Source)] { set _name $_pkg(Source) }
		
			if ![info exists sources($_name)] {
				lappend sources(*) $_name
				
				set sources($_name)		[list $_pkg(Package) $_pkg(Version) ]
				
				incr count
				if [getopt $args "-verbose"] { show_progress "Sources %5d" $count }
				
			} else {
				lappend sources($_name) $_pkg(Package) $_pkg(Version)
			}
		}
		
		if [getopt $args "-verbose"] { puts "$count source packages found." }
	}
	
	method foreach_package_src { arr_name script args } {
		variable	sources
		
		upvar $arr_name _r
		
		foreach _name $sources(*) {
	
			set _r(name)			$_name
			set _r(packages)		$sources($_name)
			
			uplevel 1 $script
		}
	
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
		# set _fname			[file tail $_pkg(Filename)]

		set _fname		[join [list $_pkg(Package) $_pkg(Version) $_pkg(Architecture) ] "_" ]
		append _fname ".deb"

		#
		# 9base_1%3a6-6_amd64.deb
		#
		regsub -all {\:} $_fname "%3a" _fname
		
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




