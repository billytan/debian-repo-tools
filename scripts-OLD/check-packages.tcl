#
# Usage:
#    check-packages.tcl <Packages-file>
#
#    check if exists any packages with multiple versions;
#
#
#     dpkg  --compare-versions ver1 op ver2
#             Compare  version  numbers,  where  op  is a binary operator. dpkg returns success (zero result) if the
#              specified condition is satisfied, and failure (nonzero result) otherwise.  There  are  two  groups  of
#              operators,  which differ in how they treat an empty ver1 or ver2. These treat an empty version as ear©\
#              lier than any version: lt le eq ne ge gt. These treat an empty version  as  later  than  any  version:
#              lt-nl le-nl ge-nl gt-nl. These are provided only for compatibility with control file syntax: < << <= =
#              >= >> >.
#

set SCRIPT		[file dirname [info script]]
source $SCRIPT/debian_utils.tcl

set pathname		[lindex $argv 0]

proc compare_version { ver1 ver2 } {

	catch {
		exec /usr/bin/dpkg --compare-versions $ver1 lt $ver2
	} _output _status
	
	array set status $_status
	
	return $status(-code)
}

set count		0
set _chan		[open_zipped_file $pathname]

while {1} {
	
	set _txt		[get_next_item $_chan]
	if {$_txt == ""} break
		
	unset -nocomplain pkg
		
	array set pkg [parse_package $_txt]
		
	set _name		$pkg(Package)
		
	if [info exists _arr($_name)] {
		
		array set _old [set _arr($_name)]
			
		puts "WARNING: duplicate package found : $_name $_old(Version) | $pkg(Version)"
		
		set retcode		[compare_version $pkg(Version) $_old(Version)]
		
		if {$retcode == 0} continue
		
		puts "$_name UPDATE $pkg(Version)"
	}
	
	set _arr($_name) [array get pkg]
	incr count
}
	
close $_chan
	
puts "$count packages loaded."

