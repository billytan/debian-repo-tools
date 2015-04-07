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

		if [getopt $args "-verbose"] { puts "loading $pathname ..." } 

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
	
	method load_packages { args } {
		variable	suite
		variable	ARCH
		
		set count		0
		
		foreach _s { main contrib non-free } {
			set pathname		[file join $repo_dir "dists/$suite/$_s/binary-$ARCH/Packages.gz" ]

			if [file exists $pathname] { 
				incr count [eval [list my load $pathname] $args]
			}
		}
		
		#
		# d-i packages
		#
		set pathname		[file join $repo_dir "dists/$suite/main/debian-installer/binary-$ARCH/Packages.gz" ]
		
		if [file exists $pathname] { 
			incr count [eval [list my load $pathname] $args ]
		}
		
		if [getopt $args "-verbose"] { puts "$count packages loaded." } 
	}
	
	#
	# In some cases, we need to remove all the related packages belong to a paticular source package
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


	#
	# ****** OVERLOAD ******
	#
	method source { _name args } {
		variable	sources
		
		if ![info exists sources($_name)] { return [list] }
		
		set _arr(name)		$_name
	
		foreach { pkg_name _ver } $sources($_name) { set _arr(Version) $_ver ; break }
		
		set _arr(packages)		$sources($_name)
		
		return [array get _arr]
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
			
			if { [string first "errors" $_out] > 0 } { return -code error $_out }
			
			return
		}
		
		#
		# just call "reprepro includedeb", without any further checks ...
		#
		if { $_ext == ".deb" } {
		
			catch {
				exec /usr/bin/reprepro -V --ignore=wrongdistribution -b $repo_dir includedeb $suite $pathname
			} _out
			
			puts $_out
			
			if { [string first "errors" $_out] > 0 } { return -code error $_out	}
			
			return
		}
	}

	#
	# return the list of packages removed
	#
	method remove { src_pkg args } {
		variable	suite
		variable	ARCH
		variable	sources
		
		# puts "CALL remove $src_pkg $args"
		
		if ![info exists sources($src_pkg)] {
		
			# puts "    $src_pkg NOT FOUND"
			
			return [list]
			
			# return -code error "invalid source package name '$src_pkg`"
		}
		
		foreach { pkg_name _ver } $sources($src_pkg) {

			puts "    remove $pkg_name $_ver"
			
			#
			# limit to the specified architecture
			#
			catch {	exec /usr/bin/reprepro -V -b $repo_dir -A $ARCH remove $suite $pkg_name } _out
	
			puts $_out
			
			if { [string first "Not removed as not found" $_out] > 0 } continue
		
			if { [string first "errors" $_out] > 0 } { return -code error $_out	}

			puts "$pkg_name $_ver removed."	
			
			lappend result $pkg_name $_ver
		}
		
		return $result
	}


	method remove_package { _name args } {



	}
	
	destructor {}

}


