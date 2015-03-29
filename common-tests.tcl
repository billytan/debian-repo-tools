#
# common-tests.tcl
#

source "common.tcl"


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
