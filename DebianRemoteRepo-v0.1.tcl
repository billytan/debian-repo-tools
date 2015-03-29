#
# DebianRemoteRepo.tcl
#

package require oo

oo::class create DebianRemoteRepo {

	variable packages sources

	constructor { url args } {

		foreach url $args break
		
		
	}
	
	method load_packages { args } {
	
	
	
	}
	
	#
	# get a specified package
	#
	method download { args } {
	
	
	
	}
	
}


httc@vm_debian_httc:/disk4/baixibao2_repo_root$ cat scripts/my-apt-cache.sh
#!/bin/sh

#
# apt-cache, but against a local repo
#

MIRROR="http://192.168.133.126/baixibao2/debian"
SUITE=jessie


TMP_DIR=`mktemp -d -p /tmp apt-XXXXX`


mkdir -p $TMP_DIR/etc/apt

cat > $TMP_DIR/etc/apt/sources.list <<EOF

deb [arch=ppc64, trusted=yes]  $MIRROR $SUITE main

EOF

_dir=$TMP_DIR/var/lib/apt

mkdir -p $_dir/lists
mkdir -p $_dir/archives/partial

APT_CONFIG="-o Apt::Architecture=ppc64"

APT_CONFIG="$APT_CONFIG -o Apt::Get::Download-Only=true"
APT_CONFIG="$APT_CONFIG -o Apt::Install-Recommends=false"

APT_CONFIG="$APT_CONFIG -o Apt::Get::AllowUnauthenticated=true"

APT_CONFIG="$APT_CONFIG -o Dir::Etc=$TMP_DIR/etc/apt"
mkdir -p $TMP_DIR/etc/apt/preferences.d/

APT_CONFIG="$APT_CONFIG -o Dir::Etc::SourceList=$TMP_DIR/etc/apt/sources.list"
APT_CONFIG="$APT_CONFIG -o Dir::Etc::SourceParts=$TMP_DIR/etc/apt/sources.list.d"

APT_CONFIG="$APT_CONFIG -o Dir::State=$_dir"

APT_CONFIG="$APT_CONFIG -o Dir::State::Status=$TMP_DIR/var/lib/dpkg/status"
mkdir -p $TMP_DIR/var/lib/dpkg
touch $TMP_DIR/var/lib/dpkg/status

APT_CONFIG="$APT_CONFIG -o Dir::Cache=$_dir"

#
# download meta-data files ....
#
apt-get -y $APT_CONFIG update >/dev/null 2>&1

#
# check if the required package exists ...
#
pkg="$1"
test -z "$pkg" && exit

apt-cache $APT_CONFIG show $pkg

rm -fr $TMP_DIR



#
# Repository::init
#
proc repository_init { url args } {


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


}

proc repository_load_packages { args } {

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
	
	#
	# the source package
	#
	set source_pkg		$_name
	
	if [info exists _pkg(Source)] {
	
		set source_pkg		$_pkg(Source)
	}
	
	if [info exists mirror(src,$source_pkg)
}


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
	
	log $result
	
	return $result
}




