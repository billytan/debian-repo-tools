#
# DebianLocalRepository.tcl
#

#
# ... so you DO NOT need to call reprepro any more ...
#

oo::class create DebianLocalRepository {
	superclass DebianRepository
	
	variable repo_dir
	
	constructor { _dir args } {
		variable	suite
		variable	ARCH
		
		#
		# invoke base class constructor
		#
		next
		
		set repo_dir		$_dir

		set _s		[getopt $args "--suite=%s"]
		if { $_s != "" } { set suite $_s }
		
		set _s		[getopt $args "--arch=%s"]
		if { $_s != "" } { set ARCH $_s }
	}

	#
	# provided with Packages.gz
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
			my __add_package [my parse_package $_r ]

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
	# provided with a .changes file for a compiled package, or a single .deb file
	#
	method install { pathname args } {
		variable	suite
		
		set _ext		[file extension [file tail $pathname]]
	
		if { $_ext == ".changes" } {
		
			array set src_pkg [my parse_changes_file $pathname ]
		
			#
			# if exists, remove it at first ...
			#
			my remove $src_pkg(Source)
			
			#
			# possibly, got a package built for unstable
			#
			catch {
				exec /usr/bin/reprepro -V --ignore=wrongdistribution -b $repo_dir include $suite $pathname
			} _out
			
			# puts $_out
			
			if { [string first "errors" $_out] > 0 } {
				return -code error $_out
			}
			
			return
		}
		
		if { $_ext == ".deb" } {
		
		
		}
	}


	method remove { src_pkg args } {
		variable	suite
		variable	ARCH
		
		puts "CALL remove $src_pkg $args"
		
		#
		# limit to the specified architecture
		#
		catch {
			exec /usr/bin/reprepro -V -b $repo_dir -A $ARCH remove $suite $src_pkg

		} _out
	
		if { [string first "Not removed as not found" $_out] > 0 } return
		
		puts $_out
		
		if { [string first "errors" $_out] > 0 } {
			return -code error $_out
		}
	}

	destructor {
	
		puts "destroy CALLED."
		return
	}

}


