#
# DebianRemoteRepository.tcl
#


oo::class create DebianRemoteRepository {
	superclass DebianRepository
	
	variable	admin_dir
	variable	apt_config
	
	variable	is_updated
	
	constructor { _url _suite args } {
		variable	suite

		set suite		$_suite

		#
		# FIXME
		#    how to invoke baseclass constructor
		#
		next
		
		eval [list my __init $_url] $args
		
		set is_updated		0
	}
	
	method __init { _url args } {
		variable	ARCH
		variable	suite
		
		foreach url $args break

		array set _args [check_args $args "--arch" "--components"]
 
		if ![info exists _args(--arch)] {
		
			catch { exec /usr/bin/dpkg --print-architecture } result
			
			set _args(--arch)		$result
		}
		
		set ARCH		$_args(--arch)
		
		if ![info exists _args(--components)] {
		
			set _args(--components)			"main"
		} else {
		
			set _args(--components)			[join [split $_args(--components) ","]]
		}
		
		#
		# create a working directory for apt-get
		#
		catch { exec /bin/mktemp -d -p /tmp "debian-repo-XXX" } admin_dir
		
		#
		# FOR DEBUG PURPOSE
		#
		catch {
		
			# set admin_dir		"/tmp/topdir"
			
			# if [file exists $admin_dir ] return
		}
		
		my apt_setup $admin_dir
		
		@file "deb \[arch=$_args(--arch), trusted=yes\]  $_url $suite $_args(--components) " > $admin_dir/etc/apt/sources.list
		
		#
		# also source packages
		#
		if { [getopt $args "-source"] != "" } {
			@file "deb-src \[arch=$_args(--arch), trusted=yes\]  $_url $suite $_args(--components) " > $admin_dir/etc/apt/sources.list
		}
	}
	
	
	method apt_setup { top_dir args } {
		variable	ARCH
		
		file mkdir $top_dir/etc/apt
	
		file mkdir $top_dir/etc/apt/preferences.d/
	
		file mkdir $top_dir/var/lib/apt
		file mkdir $top_dir/var/lib/apt/lists
		file mkdir $top_dir/var/lib/apt/archives/partial

		file mkdir $top_dir/var/lib/dpkg
		
		exec /usr/bin/touch $top_dir/var/lib/dpkg/status
		
		set apt_config		"-o Apt::Architecture=$ARCH"
		
		append apt_config	"  -o Apt::Get::Download-Only=true"
		append apt_config	"  -o Apt::Install-Recommends=false"

		append apt_config	"  -o Apt::Get::AllowUnauthenticated=true"

		append apt_config	"  -o Dir::Etc=$admin_dir/etc/apt"

		append apt_config	"  -o Dir::Etc::SourceList=$admin_dir/etc/apt/sources.list"
		append apt_config	"  -o Dir::Etc::SourceParts=$admin_dir/etc/apt/sources.list.d"

		append apt_config	"  -o Dir::State=$admin_dir/var/lib/apt"

		append apt_config	"  -o Dir::State::Status=$admin_dir/var/lib/dpkg/status"

		append apt_config	"  -o Dir::Cache=$admin_dir/var/lib/apt"	
	}
	
	
	method __update { args } {
	
		# puts "/usr/bin/apt-get -y $apt_config update"
		
		catch {
			#
			# otherwise, you'll never notice the error message
			#
			# eval exec /usr/bin/apt-get -y $apt_config update 2>@1
			
			eval @ exec /usr/bin/apt-get -y $apt_config update
		} result
	
		#
		# FIXME
		#	check for error message ...
		#
		
		puts $result
	
		set is_updated		1
	}
	
	method load_packages { args } {
		variable packages

		if !is_updated { my __update }
		
		set packages		[list]

		# puts "/usr/bin/apt-cache $apt_config dumpavail"
		
		catch {
		
			eval exec /usr/bin/apt-cache $apt_config dumpavail
		} result
		
		# @file $result >> /tmp/Packages
		
		#
		# FIXME
		#   check if there is any error message
		#
			
		set count		0
		
		@ foreach _r $result << "\n\n" {
		
			lappend packages [my parse_package $_r]
	
			incr count
			
			if [getopt $args "-verbose"]  { show_progress "Loading packages %6d" $count }
			
			#
			# NOT SURE IF "break" will work ... IT WORKS WELL !!!
			#
			if { $count > 1000 } break
		}
		
		if [getopt $args "-verbose"]  { puts "$count packages loaded." }
	}

	#
	# no way to ask apt-cache to present a list of source packages .... so we choose to load from the cache !
	#
	method load_source_packages { args } {
		variable		sources
		
		if !$is_updated { my __update }

		set count		0
		
		foreach _pathname [glob -directory "$admin_dir/var/lib/apt/lists" -nocomplain "*_Sources" ] {
			
			@ read $_pathname << "\n\n" {

				#
				# there may exists multiple versions of a particular source package
				#
				
				#
				# untolerably slow as we are dealting with 20197 packages ...!!!
				#
				# my __add_source_package [my parse_package $_]
				lappend sources [my parse_package $_]
				
				incr count
				if [getopt $args "-verbose"] { show_progress "loading %6d" $count }
			}
		}
		
		if [getopt $args "-verbose"] { puts "$count packages loaded." }
	}
	
	
	#
	# get a specified package
	#
	method download { _pkgname args } {
	
		eval exec /usr/bin/apt-get $apt_config download $_pkgname 2>@1
		
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
	
	
	method get_source { _pkgname args } {
	
	
	
	}
	
	
	destructor {
	
		puts "removing $admin_dir ..."
		
		# file delete -force $admin_dir
	}
	
}




