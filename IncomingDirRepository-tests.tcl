#
# IncomingDirRepository-tests.tcl
#

source common.tcl

source DebianRepository.tcl
source IncomingDirRepository.tcl


if 1 {

	set repo_obj		[IncomingDirRepository new "/baixibao2/buildd_repo_root/Incoming" ]
	# set repo_obj		[IncomingDirRepository new "/disk2/loongfox-linux-dev/rebootstrap-ppc64/RESULT/debs" ]

	$repo_obj load_packages -verbose

	set count		0
	
	$repo_obj foreach_package _pkg {
	
		puts "$_pkg(Source) $_pkg(Version)"
		
		# @ foreach _line $_pkg(Files) { puts "   $_line" }
		
		foreach _fname [$repo_obj package $_pkg(Source) -files ] {
			puts "    $_fname"
		}
		
		incr count ; if { $count > 10 } break
	}
	
}