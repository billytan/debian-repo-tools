#
# import-packages-from.tcl
#

#
# Use this script to import debian-ports PPC64 packages into Baixibao repo;
#
# Usage:  
#     import-packages-from.tcl -M <$mirror-url> -b <repo-dir> -X <blacklist-file> $options
#

set SCRIPT		[file dirname [info script]]

source $SCRIPT/common_util.tcl
source $SCRIPT/repo_util.tcl

#
# provided by shell script
#
array set my_args [check_args $argv "-b" "-M" "-L" "-X"]

set repo_dir		[file normalize $my_args(-b)]

set mirror_url		$my_args(-M)

	# set MIRROR		"http://192.168.133.126/ppc64/debian"

	#
	# use a local copy to speed up the build process
	#
	set MIRROR		"file///baixibao2/debian_mirror_ppc64/debian"

set_logs_dir [file normalize $my_args(-L)]

proc check_stop { args } {

	if [file exists [file join [pwd] "STOP"]] {
		return 1
	}
	
	return 0
}

file delete [file join [pwd] "STOP"]

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
	
	log $result
	
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

log $result >> "/tmp/Packages.local" 

set my(packages)		[list]
set count				0

foreach _line [split $result "\n"] {
	
	foreach { _x _name _ver } [split $_line] break

	lappend my(packages) $_name $_ver $_x
	
	incr count
}

log "found $count packages in my repository" %info

#
# 要考虑包库更新会出现的问题 ...
#
#      reprepro 不能够单独删除一个 deb， 只能是完整删除一个 source package 对应的全部 deb
#
proc add_package { _name args } {
	global mirror my

	log "add_package $_name $args" %debug

	array set _pkg $mirror($_name)
	
	set source_pkg		$_name
	
	if [info exists _pkg(Source)] {
		set source_pkg		$_pkg(Source)
	}
	
	if { [lsearch $my(sources) $source_pkg] >= 0 } return
	
	#
	# add to the list of source packages which should be UPDATED ...
	#
	set j		[lsearch $args "-reinstall"]
	
	lappend my(sources) $source_pkg  $j
	
	log $source_pkg > sources.add
	
	counter +sources
}


#
# the list of source packages to be installed/upgraded ...
#
set my(sources)				[list]


proc do_remove_src { source_pkg args } {

	log "/usr/bin/reprepro -V -b $::repo_dir removesrc jessie $source_pkg" %reprepro

	catch {
		exec /usr/bin/reprepro -V -b $::repo_dir removesrc jessie $source_pkg 2>@1 
	} errmsg

	log "$errmsg\n\n\n" %reprepro
}

proc do_install_package { _name args } {



}

#
# for each package in debian-ports, check if it is a new version
#
set packages		[list]

set result		[chdist apt-cache dumpavail]

log $result >> "/tmp/Packages.mirror" 

foreach _record [split2 $result "\n\n"] {
	
	unset -nocomplain _pkg
	array set _pkg		[parse_package $_record]
	
	set _name			$_pkg(Package)

	log "Package: $_name $_pkg(Version)" %debug
	
	lappend packages $_name
	
	set mirror($_name)		[array get _pkg]
}

log "found [llength $packages] debian-ports packages." %info

foreach _name $packages {

	counter +packages
	
	show_progress "Packages %6d" [counter %packages]
	
	#
	# FOR DEBUG PURPOSE ONLY
	#
	# if { $count > 3 } break

	set j		[lsearch -exact $my(packages) $_name]
	
	if { $j < 0 } {
	
		add_package $_name
		
		log $_name > packages.new
		counter +new
		
		continue
	}

	#
	# version check ...
	#
	incr j
	set _ver		[lindex $my(packages) $j]

	unset -nocomplain _pkg
	array set _pkg	$mirror($_name)
	
	#
	# a quick check ...
	#
	if { $_ver == $_pkg(Version) } {
	
		log "$_name $_ver" > packages.same
		
		counter +sameAs
		continue
	}
	
	set retcode		[compare_version $_ver $_pkg(Version) ]
		
	if { $retcode == 0 } {
		
		add_package $_name -reinstall 1
		
		log "$_name $_ver $_pkg(Version)" > packages.upgrade
		
		counter +toUpgrade
		continue
	}
	
	log "$_name $_ver $_pkg(Version) retcode=$retcode" >packages.same
	counter +sameAs
}

counter show

#
# start to load packages ...
#
counter clear

foreach _name $packages {

	unset -nocomplain _pkg
	array set _pkg	$mirror($_name)

	set source_pkg		$_name
	
	if [info exists _pkg(Source)] {
		set source_pkg		$_pkg(Source)
	}
		
	set j			[lsearch -exact $my(sources) $source_pkg]
	
	if { $j < 0 } continue
	
	counter +sources
	show_progress "Install packages: %6d" [counter %sources]
	
	incr j
	set retcode		[lindex $my(sources) $j]
	
	if { $retcode >= 0 } {
		#
		# remove it from local repo at first ...
		#
		do_remove_src $source_pkg	
		
		set my(sources)			[lreplace $my(sources) $j $j -1]
			
		counter +replace
	}
	
	do_install_package $_name
	
	counter +installed
	
	if [check_stop] break
}

counter show


