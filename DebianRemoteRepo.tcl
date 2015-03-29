#
# DebianRemoteRepo.tcl
#


oo::class create DebianRemoteRepo {

	variable packages 
	variable sources

	variable ARCH
	
	variable admin_dir
	variable apt_config
	
	constructor { url args } {

		eval [list my __init $url] $args
	}
	
	method __init { url suite args } {
	
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
		
			set admin_dir		"/tmp/topdir"
			
			if [file exists $admin_dir ] return
		}
		
		my apt_setup $admin_dir
		
		@file "deb \[arch=$_args(--arch), trusted=yes\]  $url $suite $_args(--components) " >> $admin_dir/etc/apt/sources.list
	}
	
	
	method apt_setup { top_dir args } {
	
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
	}
	
	
	method load_packages { args } {
		
		catch {
			exec /usr/bin/apt-get -y $apt_config update 
		} result
		
		puts $result
		
		set packages		[list]

		catch {
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
	
	method foreach_package { arr_name script } {
	
		upvar $arr_name _pkg
		
		foreach _r $packages {
	
			unset -nocomplain _pkg
			array set _pkg $_r
			
			uplevel 1 $script
		}
	}
	
	#
	# get a specified package
	#
	method download { args } {
	
	
	
	}
	
	method parse_package { _text args } {
	
		set result		[list]
	
		@ foreach _line $_text {
		
			set j		[string first ":" $_line]
		
			set _name	[string range $_line 0 [expr $j - 1]]
		
			incr j
			set _value	[string range $_line $j end]
		
			lappend result $_name [string trim $_value]
		}
		
		return $result
	}
	
	#
	#  for the same version, return 0;
	#
	#  if $ver1 is "lower than" $ver2, return -1; otherwise return 1;
	#
	method compare_version { ver1 ver2 } {

		#
		# in the simplest case ...
		#
		if { $ver1 == $ver2 } { return 0 }
		
		catch {
			exec /usr/bin/dpkg --compare-versions $ver1 lt $ver2
		} _output _status
	
		puts "$_output"
	
		array set _arr $_status
	
		if { $_arr(-code) == 0 } { return -1 }
		
		return 1
	}
	
	
	destructor {
	
		puts "removing $admin_dir ..."
		
		# file delete -force $admin_dir
	}
	
}




