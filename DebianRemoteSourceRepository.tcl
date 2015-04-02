#
# DebianRemoteSourceRepository.tcl
#


oo::class create DebianRemoteRepository {
	superclass DebianRepository
	
	variable	is_updated
	
	constructor { _url _suite args } {
		variable	suite

		#
		# FIXME
		#    how to invoke baseclass constructor
		#
		next

		set suite		$_suite
		set is_updated		0
		
		eval [list my __init $_url] $args
	}
	
	method get_source { _pkgname args } {
	
		eval exec /usr/bin/apt-get $apt_config --download-only source $_pkgname 2>@1
	
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
	
		#puts "removing $admin_dir ..."
		
		file delete -force $admin_dir
	}
	
}