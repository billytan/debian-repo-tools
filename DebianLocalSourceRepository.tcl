#
# DebianLocalSourceRepository.tcl
#

#
# dedicated for the management of source packages
#

oo::class create DebianLocalRepository {
	superclass DebianRepository
	
	variable repo_dir
	
	constructor { _dir args } {
		variable	suite
		
		#
		# invoke base class constructor
		#
		next
		
		set repo_dir		$_dir

		set _s		[getopt $args "--suite=%s"]
		if { $_s != "" } { set suite $_s }
	}
	
	
	#
	# provided with Sources.gz
	#
	method load { pathname args } {
	
		set _chan		[my open_zipped_file $pathname]

		fconfigure $_chan -translation binary -encoding binary

		#
		# FIXME
		#    invoke load_big_file instead;
		#
		set _data		[read $_chan]
		
		close $_chan

		set count		0
		
		@ foreach _r $_data << "\n\n" {
		
			#
			# invole parse_package OR parse_source_package
			#
			my __add_source_package [my parse_package $_r ]

			incr count
			
			if [getopt $args "-verbose"] { show_progress "loading %6d" $count }
			
			#
			# FOR DEBUG PURPOSE
			#
			# if { $count > 1000 } break
		}

		return $count
	}
	
	#
	# Assume that being provided with a .dsc file for source package
	#
	method install { pathname args } {
		variable	suite
		
		set _ext		[file extension [file tail $pathname]]
	
		if { $_ext != ".dsc" } { return -code error "invalid source package $pathname" }


			if [catch {
				exec /usr/bin/reprepro -V -b $repo_dir includedsc $suite $pathname
				
			} errmsg] {
				# puts $errmsg
			}
			
			return
		}
		
	}
	
	destructor {
		#
		# FIXME
		#
	}

}
