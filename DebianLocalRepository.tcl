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
		
		set repo_dir		$_dir
		set suite			"jessie"

		set packages		[list]
	}

	#
	# provided with Sources.gz or Packages.gz
	#
	method load { pathname args } {
	
		#
		# MUST-HAVE: for reference to the data of superclass
		#
		variable  sources
		variable  packages
		
		if { [string first "Sources" $pathname] >= 0 } { set is_source  1 } else { set is_source 0 }
		
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
			set result			[my parse_package $_r ]
			
			if $is_source { lappend sources $result } else { lappend packages $result }

			incr count
			
			if [getopt $args "-verbose"] { show_progress "loading %6d" $count }
			
			#
			# FOR DEBUG PURPOSE
			#
			if { $count > 1000 } break
		}

		return $count
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

	
	#
	# provided with a .dsc file for source package, or .changes file for a compiled package, or a single .deb file
	#
	method install { pathname args } {
	
		set _ext		[file extension [file tail $pathname]]
	
		if { $_ext == ".changes" } {
		
		}
		
		if { $_ext == ".dsc" } {


			if [catch {
				exec /usr/bin/reprepro -V -b $repo_dir includedsc $suite $pathname
				
			} errmsg] {
				# puts $errmsg
			}
			
			return
		}
		
		if { $_ext == ".deb" } {
		
		
		}
	}


	destructor {
	
		puts "destroy CALLED."
		return
	}

}


