#
# DebianRemoteRepository.tcl
#


oo::class create DebianRemoteRepository {
	superclass DebianRepository
	
	variable admin_dir
	variable apt_config
	
	constructor { url args } {

		eval [list my __init $url] $args
	}
	
	method __init { url suite args } {
		variable	ARCH
		
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
		
		@file "deb \[arch=$_args(--arch), trusted=yes\]  $url $suite $_args(--components) " >> $admin_dir/etc/apt/sources.list
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

		append apt_config	"  -o Dir::State=$admin_dir/var/lib/dpkg"

		append apt_config	"  -o Dir::State::Status=$admin_dir/var/lib/dpkg/status"

		append apt_config	"  -o Dir::Cache=$admin_dir/var/lib/dpkg"	
		
		append apt_config	"  -o Dir::State::Lists=$admin_dir/var/lib/dpkg/lists"
	}
	
	
	method load_packages { args } {
		variable packages
		
		catch {
			puts "/usr/bin/apt-get -y $apt_config update"
		
			exec /usr/bin/apt-get -y $apt_config update 
		} result
		
		puts $result
		
		set packages		[list]

		catch {
			puts "/usr/bin/apt-cache $apt_config dumpavail"
			
			exec /usr/bin/apt-cache $apt_config dumpavail
		} result
		
		# @file $result >> /tmp/Packages
		
		set count		0
		
		@ foreach _r $result << "\n\n" {
		
			lappend packages [my parse_package $_r]
	
			incr count
			
			show_progress "Loading packages %6d" $count
			
			#
			# NOT SURE IF "break" will work ... IT WORKS WELL !!!
			#
			if { $count > 1000 } break
		}
		
		puts "$count packages loaded."
	}

	#
	# get a specified package
	#
	method download { args } {
	
	
	
	}
	
	
	destructor {
	
		puts "removing $admin_dir ..."
		
		# file delete -force $admin_dir
	}
	
}




