#
# import-packages-from.tcl
#

#
# Use this script to import debian-ports PPC64 packages into Baixibao repo;
#
# Usage:  
#     import-packages-from.tcl -M <$mirror-url> -b <repo-dir> $options
#

set SCRIPT		[file dirname [info script]]

source $SCRIPT/common_util.tcl
source $SCRIPT/repo_util.tcl

#
# provided by shell script
#
array set my_args [check_args $argv "-b" "-M" "-L"]

set repo_dir		[file normalize $my_args(-b)]

set mirror_url		$my_args(-M)

	# set MIRROR		"http://192.168.133.126/ppc64/debian"

	#
	# use a local copy to speed up the build process
	#
	set MIRROR		"file///baixibao2/debian_mirror_ppc64/debian"


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
	
	# puts $result
	
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
	chdist create $mirror_url sid main
	
	chdist apt-get update
}


#
# find out those missing packages in local repo
#
catch {

	exec /usr/bin/reprepro -b $repo_dir list jessie
} result

set my(packages)	[list]

foreach _line [split $result "\n"] {
	
	foreach { _x _name _ver } [split $_line] break

	lappend my(packages) $_name $_ver $_x
}

proc do_install_package { _name args } {


	debug_log "do_install_package $_name $args"

}

#
# for each package in debian-ports, check if it is a new version
#
set result		[chdist apt-cache pkgnames]
set count		0

foreach _name [split $result "\n"] {

	#
	# Skip this line: 
	#    W: Forcing arch ppc64 for this command only.
	#
	if { [string first "W: " $_name] >= 0 } continue
	
	#
	# FOR DEBUG PURPOSE ONLY
	#
	if { $count > 3 } break

	set j		[lsearch $my(packages) $_name]
	
	if { $j < 0 } {
	
		do_install_package $_name
		
		# incr count
		continue
	}
		
	#
	# version check ...
	#
	set result		[chdist apt-cache show $_name]
	
	array set _pkg	[parse_package $result]
	
	puts [array get _pkg]
	
	incr j
	set _ver		[lindex $my(packages) $j]
	
	set retcode		[compare_version $_ver $_pkg(Version) ]
	
	debug_log "compare_version $_ver $_pkg(Version) , retcode = $retcode "
		
	if { $retcode == 0 } {
		
		do_install_package $_name -reinstall 1
		
		incr count
	}
}

