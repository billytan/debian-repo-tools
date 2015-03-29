#
# compare-repo.tcl
#
# Usage:  
#     compare-repo.tcl -M <$mirror-url> -b <repo-dir> $options
#
# FIXME
#      ******* choose the right suite and components *******
#

set SCRIPT		[file dirname [info script]]

source $SCRIPT/common_util.tcl
source $SCRIPT/repo_util.tcl

#
# provided by shell script
#
array set my_args [check_args $argv "-b" "-M" "-L"]

set repo_dir		[file normalize $my_args(-b)]
set mirror_dir		$my_args(-M)

set _log_file		[file normalize $my_args(-L)]

set ::LOG_FILE		[open $_log_file "w+"]

proc LOG { txt } {

	puts -nonewline $::LOG_FILE $txt
	flush $::LOG_FILE
}

proc debug_log { msg args } {

	LOG "$msg\n"
	
	puts $msg
	flush stdout
}

#
# similiar to "chdist" tool in devscripts package
#
proc chdist { cmd args } {

	#
	# chdist.pl must be located in the directory
	#
	set _dir		[file normalize [file dirname [info script]]]
	set chdist_cmd	[file join $_dir "chdist.pl"]

	if { $cmd == "config" } {
	
		foreach { _name _value } $args {
	
			regexp -- {--(.*)} $_name _x _name
			
			set ::chdist(config,$_name)		$_value
		}
		
		return
	}
	
	foreach _s { data-dir name } {
		if ![info exists ::chdist(config,$_s)] {
			return -code error "no config data for '$_s' available"
		}
	}
	
	if ![info exists ::chdist(config,arch)] {
	
		catch { exec /usr/bin/dpkg --print-architecture} result
		
		set ::chdist(config,arch)	$result
	}
	
	catch {

		eval [list exec $chdist_cmd --data-dir $::chdist(config,data-dir) -a $::chdist(config,arch) $cmd $::chdist(config,name)] $args
	} result
	
	puts $result
	
	return $result
}


#
# initialize chdist 
#
set chdist_dir		"/tmp/chdist"

chdist config --name "debian-ports-ppc64" --arch ppc64 --data-dir $chdist_dir
	
if ![file exists $chdist_dir] {

	file mkdir $chdist_dir
	
	#
	# FIXME
	#      choose the right suite and components
	#
	chdist create $mirror_dir sid main
	
	chdist apt-get update
}

#
# find out those missing packages in local repo
#
catch {

	exec /usr/bin/reprepro -b $repo_dir --list-format="${package}\n" list jessie
} result

set _packages	[split $result "\n"]

set result		[chdist apt-cache pkgnames]
set count		0

foreach _name [split $result "\n"] {


	if { [lsearch $_packages $_name] >= 0 } continue
	
	puts "TODO: $_name"
	
	incr count
}

puts "$count packages to install."

