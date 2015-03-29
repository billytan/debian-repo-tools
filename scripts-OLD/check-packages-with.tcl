#
# Usage:
#     check-packages-with.tcl  <installed-Packages> <source-Packages>
#
#    find out those packages available in "source repository", but not yet imported to our own repository
#

set SCRIPT		[file dirname [info script]]
source $SCRIPT/debian_utils.tcl

set LOG_FILE	"result.log"

foreach {installed_packages_file pathname} $argv break

set ::G(packages)	[load_packages_file $installed_packages_file]

puts "$installed_packages_file loaded."
flush stdout

proc search_package { record } {

	array set pkg $record
	
	foreach _item $::G(packages) {
	
		array set _arr $_item
		
		if { $pkg(Package) != $_arr(Package) } continue
		
		if { [file tail $pkg(Filename)] == [file tail $_arr(Filename)] }  {
			return 1
		}
		
		if { $pkg(Version) != $_arr(Version) } {
			log_to_file $::LOG_FILE "$pkg(Package): installed $pkg(Version) | $_arr(Version)"
			puts "$pkg(Package): installed $pkg(Version) | $_arr(Version)"
			return 1
		}
	}
	
	return 0
}

foreach record [load_packages_file $pathname] {

	set is_installed		[search_package $record]
	
	if $is_installed continue

	array set pkg $record

	log_to_file $::LOG_FILE "$pkg(Package): $pkg(Filename)"

	puts "$pkg(Package): $pkg(Filename)"
	flush stdout
}



