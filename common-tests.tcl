#
# common-tests.tcl
#

source "common.tcl"

file copy -force "sbuild.conf" /tmp

# @ subst /tmp/sbuild.conf  [list %ARCH% amd64 %SUITE% jessie %CHROOT% "/tmp/chroot" ]
@ subst /tmp/sbuild.conf  [list %ARCH% amd64 %SUITE% jessie %CHROOT% "/tmp/chroot" ] > /tmp/sbuild-NEW.conf

exit 

set sources(*)		{a b c d}

foreach _name $sources(*) { puts $_name }

exit

cd /tmp

# @ exec /usr/bin/wget http://ftp.de.debian.org/debian-ports/pool-ppc64/main/l/linux/kernel-image-3.16.0-4-powerpc64-di_3.16.7-ckt7-1_ppc64.udeb
@ exec /usr/bin/wget "http://ftp.cn.debian.org/debian/pool/main/l/linux/linux_3.16.7-ckt7.orig.tar.xz"

exit

set count		0

@ read "/var/lib/apt/lists/ftp.cn.debian.org_debian_dists_jessie_main_source_Sources" << "\n\n" {

	puts $_
	
	incr count
	
	if { $count > 15 } break
}

exit

set retcode		[getopt  { "$REPO_DIR/dists/jessie/main/binary-ppc64/Packages.gz" -verbose } -verbose ]

puts  "retcode = $retcode"

exit 

set _text		"this is the first line\n\n but this is another record \n and one more line\n\n the 3rd record start here"

set count		0

@ foreach _r $_text << "\n\n" {

	incr count
	puts "#$count\n $_r"
}

puts "count = $count"

exit

set count		0

incr count; incr count; puts "count = $count";

if { $count < 3 } { puts "OK" }

exit

@file <X.bat> [list RUN2 _ pathname CODE {

	if [file exists $pathname] {
		puts "$_"
	}
}]

exit

# TESTED OK

set all_names	{john billy jacky}

@my_name << all_names

puts "$my_name"
puts "$all_names"

exit

# TESTED OK

set all_names	{john billy jacky}

@ my_name << all_names

puts "$my_name"
puts "$all_names"

exit

@file "this is the first line"  "this is the 2nd line" >> "abc.txt"

@file > "abc2.txt" "this is the first line"  "this is the 2nd line" 

@file ">>abc3.txt" "this is the first line"  "this is the 2nd line" 

exit

@file <X.bat> [list RUN2 _ pathname CODE {

	if [file exists $pathname] {
		puts "$_"
	}
}]

exit


# TESTED OK

proc test_it { _p } {

	upvar $_p _

	puts "$_"
}

set _		"this is just a test"

test_it _

exit

# FAILED

proc test_it { %p } {

	upvar $%p _

	puts "$_"
}

set _		"this is just a test"

test_it _

exit


# FAILED

proc test_it { %_ } {

	upvar $%_ _

	puts "$_"
}

set _		"this is just a test"

test_it _

exit


# TESTED OK

proc test_it { p } {

	upvar $p _

	puts "$_"
}

set _		"this is just a test"

test_it _

exit


# TESTED OK

proc test_it { p } {

	upvar $p _

	puts "$_"
}


set X		"this is just a test"

test_it X
exit

# FAILED

proc test_it { @_ } {

	upvar $@_ _

	puts "$_"
}

set _		"this is just a test"

test_it _

exit

# TESTED OK

proc add2 name {
   upvar $name x
   set x [expr $x+2]
}

set N		15

puts [add2 N]

exit


set pathname	"/etc/apt/sources.list"

eval [list RUN2 pathname CODE {

	puts "$pathname"
}]

exit


@file </etc/apt/sources.list> [list RUN2 _ pathname AS _line _pathname CODE {

	if [file exists $_pathname] {
		puts "$_line"
	}
}]


exit 

@file </etc/apt/sources.list> [list RUN _line \$_ CODE {

	puts "LINE=$_line"
}]

exit

@file </etc/apt/sources.list> { puts $_ }

exit


set _		"just a test"

set script		{
	puts "LINE=$_"
}

eval $script
