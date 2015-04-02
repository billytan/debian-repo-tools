#
# DebianRepositoryCache.tcl
#

oo::class create DebianRepositoryCache {

	variable	host_arch
	variable	suite
	
	variable	admin_dir
	variable	apt_config
	
	variable	is_updated


	constructor { _url _suite args } {

		set suite		$_suite
		set is_updated		0
		
		eval [list my __init $_url] $args
	}


	method __init { _url args } {

		set host_arch		[getopt $args "--arch=%s"]
		
		if { $host_arch == "" } { catch { exec /usr/bin/dpkg --print-architecture } host_arch }
		
		set _s		[getopt $args "--components=%s"]
		
		if { $_s == "" } { set _components "main contrib non-free" } else { set _components [join [split $_s ","]] }
	
		#
		# create a working directory for apt-get
		#
		catch { exec /bin/mktemp -d -p /tmp "debian-repo-XXX" } admin_dir
	
		my apt_setup $admin_dir
		
		#
		# also source packages
		#
		if [getopt $args "-source"] {
		
			@file "deb-src \[arch=$host_arch, trusted=yes\]  $_url $suite $_components " > $admin_dir/etc/apt/sources.list
		} else {
		
			@file "deb \[arch=$host_arch, trusted=yes\]  $_url $suite $_components " > $admin_dir/etc/apt/sources.list
		}
	}
	
	
	method apt_setup { top_dir args } {
		
		file mkdir $top_dir/etc/apt
	
		file mkdir $top_dir/etc/apt/preferences.d/
	
		file mkdir $top_dir/var/lib/apt
		file mkdir $top_dir/var/lib/apt/lists
		file mkdir $top_dir/var/lib/apt/archives/partial

		file mkdir $top_dir/var/lib/dpkg
		
		exec /usr/bin/touch $top_dir/var/lib/dpkg/status
		
		set apt_config		"-o Apt::Architecture=$host_arch"
		
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


	method update { args } {
	
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

	method apt-cache { args } {

		if !$is_updated { my update }

		# puts "/usr/bin/apt-cache $apt_config $args"
		
		catch {
			eval exec /usr/bin/apt-cache $apt_config $args
		} result
		
		return $result
	}

	method apt-get { args } {
	
		eval @ exec /usr/bin/apt-get -y $apt_config $args
	}
	
	method get_Packages_files { args } {
	
		if !$is_updated { my update }
		
		return [glob -directory "$admin_dir/var/lib/apt/lists" -nocomplain "*_Packages" ]
	}
	
	method get_Sources_files { args } {
	
		if !$is_updated { my update }

		return [glob -directory "$admin_dir/var/lib/apt/lists" -nocomplain "*_Sources" ]
	}
	
	destructor {
	
		puts "removing $admin_dir ..."
		
		# file delete -force $admin_dir
	}
}

