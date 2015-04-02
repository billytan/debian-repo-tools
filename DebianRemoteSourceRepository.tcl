#
# DebianRemoteSourceRepository.tcl
#

oo::class create DebianRemoteSourceRepository {
	superclass DebianRepository
	
	variable	cache_obj
	
	constructor { _url _suite args } {
	
		set cache_obj		[eval [list DebianRepositoryCache new $_url $_suite -source] $args]
	
		#
		# invoke baseclass constructor
		#
		next
	}
	
	
	#
	# no way to ask apt-cache to present a list of source packages .... so we choose to load from the cache !
	#
	method load_source_packages { args } {
		
		set count		0
		
		foreach _pathname [$cache_obj get_Sources_files ] {
			
			@ read $_pathname << "\n\n" {

				#
				# there may exists multiple versions of a particular source package
				#
				my __add_source_package [my parse_package $_]
				
				incr count
				if [getopt $args "-verbose"] { show_progress "loading %6d" $count }
			}
		}
		
		if [getopt $args "-verbose"] { puts "$count packages loaded." }
	}
	
	
	method get_source { _pkgname args } {
		
		$cache_obj apt-get --download-only source $_pkgname
		
		#
		# check if the list of files are downloaded
		#		
		foreach { _fname _fsize } [my source $_pkgname -files -size] {
		
			set _pathname		[file join [pwd] $_fname]
			
			if [file exists $_pathname] {
				#
				# if the file size is the same ...
				#
				if { $_fsize == [file size $_pathname] } { counter +downloaded_files ; continue }
			}
			
			puts stderr "ERROR: failed to download '$_pkgname' : $_fname"
			
			counter +failed_to_download
		}

		return
	}
	
	

	destructor {
	
		$cache_obj destroy
	}
	
}