#
# do-query-packages.tcl  <Packages.gz> $ACTION  [ $pkg ]
#
#  show $pkg [ $attribute ]
#  list
#

set SCRIPT		[file dirname [info script]]

source $SCRIPT/common_util.tcl
source $SCRIPT/repo_util.tcl

foreach { _pathname _action _arg2 _arg3 } $argv break

#
#  parse all the records ...
#
set my(Packages)		$_pathname

set my(packages,list)	[load_packages_NEW my $_pathname]

if { $_action == "list" } {

	foreach _name "$my(packages,list)" {
		puts $_name
	}
	
	exit 0
}

if { $_action == "show" } {
	
	if ![info exists my($_arg2)] {
	
		exit 1
	}

	array set _pkg $my($_arg2)
		
	#
	# 查询某一个包属性， 如 "Version"
	#
	if { [info exists _arg3] && ($_arg3 != "") } {
			
		if ![info exists _pkg($_arg3) ] {
			exit 1
		}
		
		puts $_pkg($_arg3)
		exit 0
	}
	
	#
	# print the entire record
	#
	foreach _name { Package Priority Section Architecture Source Version Provides Depends Filename } {
		
		if ![info exists _pkg($_name)] continue
	
		puts "${_name}: $_pkg($_name)"
	}
	
	exit 0
}



