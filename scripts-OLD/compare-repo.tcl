#
# compare-repo.tcl
#
#  比较 新的 baixibao 包库 和 Debian PPC64 mirror 之间的 packages，哪一些包发生变化 
#

set MIRROR_DIR		"/disk2/debian_mirror_ppc64/debian"

set REPO_DIR		"/disk4/baixibao_repo_root/debian"

set SCRIPT		[file dirname [info script]]

source $SCRIPT/common_util.tcl
source $SCRIPT/repo_util.tcl

set _log_file			"updated-packages-list.txt"

set ::LOG_FILE		[open $_log_file "w+"]

proc LOG { txt } {

	puts -nonewline $::LOG_FILE $txt
	flush $::LOG_FILE
}

#
# 读取 包库的 Packages.gz 文件
#

set my(Packages)		[file join $REPO_DIR "dists/jessie/main/binary-ppc64/Packages"]

set MIRROR(Packages)			[file join $MIRROR_DIR "dists/sid/main/binary-ppc64/Packages.gz"]

puts "loading $my(Packages) ... "

set my(packages,list)		[load_packages my $my(Packages)]

	set count		[llength $my(packages,list)]
	puts "$count packages found."


puts "loading $MIRROR(Packages) ... "

set MIRROR(packages,list)		[load_packages MIRROR $MIRROR(Packages)]

	set count		[llength $MIRROR(packages,list)]
	puts "$count packages found."


#
# check each package .... if any version changes
#
puts "checking for updated or removed packages ...\n"

foreach _name $my(packages,list) {

	unset -nocomplain pkg
	array set pkg $my($_name)

	#
	# in case of removed packages ...
	#
	if ![info exists MIRROR($_name)] {
		puts "REMOVED: $_name"
		continue
	}
	
	unset -nocomplain _pkg
	array set _pkg $MIRROR($_name)
	
	if { $pkg(Version) != $_pkg(Version) } {
	
		# puts "$_name $pkg(Version) --> $_pkg(Version)"
		
		LOG "Package: $_name\nVersion: $_pkg(Version)\nFilename: $_pkg(Filename)\n\n"
	}
}


close $::LOG_FILE

puts "\n\n$_log_file created."


