#
# DebianLocalRepository.tcl
#

#
# ... so you DO NOT need to call reprepro any more ...
#

oo::class create DebianLocalRepository {

	variable packages 
	variable sources

	variable ARCH

	variable repo_dir
	
	constructor { _dir args } {

		set repo_dir		$_dir
	}

	#
	# provided with Sources.gz or Packages.gz
	#
	method load { pathname args } {

		set _chan		[open_zipped_file $pathname]

		fconfigure $_chan -translation binary -encoding binary

		#
		# FIXME
		#    invoke load_big_file instead;
		#
		set _data		[read $_chan]
		
		close $_chan
		
		@ foreach _r $_data << "\n\n" {
		
			#
			# invole parse_package OR parse_source_package
			#
			
		}
		
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


	method parse_package { args } {
	
	
	
	}
	
	
	method parse_source_package { args } {
	
	
	
	}
	

	method foreach_package { arr_name script args } {
	
	
	
	
	}
	
	method install_deb { pathname args } {
	
	
	
	}
	
	method install_package { changes_file args } {
	
	
	
	}


	destructor {
	
		puts "destroy CALLED."
		return
	}

}


