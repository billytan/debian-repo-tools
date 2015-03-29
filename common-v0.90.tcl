#
# common_util.tcl
#

proc is_empty_list { _v } {

	if { [llength $_v] == 0 } {
		return 1
	}
	
	return 0
}

proc begin_with { line _name } {

	if { [string first $_name $line] == 0 } {
		return 1
	}
	
	return 0
}

#
# @file <$pathname> [list RUN _line $_ pathname $< CODE { .... }]
#
proc RUN { args } {

	set _def		{ proc __RUN__  }

	foreach { _name _value } $args {

		if { $_name != "CODE" }  {
		
			lappend args_list $_name 
			lappend params_list $_value
			continue
		}
		
		lappend _def $args_list $_value
		
		#
		# create a new proc
		#
		eval $_def
		
		return [eval __RUN__ $params_list]
	}
	
	#
	# NEVER REACHED
	#
}

#
# RUN var1 var2 ... AS name1 name2 ...  CODE { ... }
#
# RUN var1 var2 ... CODE { ... } 
#

proc RUN2 { args } {

	set _def		{ proc __RUN2__ }
	
	set j		[lsearch -exact $args "CODE"]
	
	if { $j < 0 } return
	
	set script		[lindex $args [expr $j + 1]]
	
	#
	# get the list of variables to be imported ...
	#
	set k		[lsearch -exact $args "AS"]
	
	if { $k < 0 } {
	
		set k		[expr $j - 1]
		
		set vars_list		[lrange $args 0 $k]
		set _vars			$vars_list
		
		#
		# MUST re-name each of them ...
		#
		foreach _name $vars_list {
			lappend params_list "param_${_name}"
		}
	} else {
	
		set vars_list		[lrange $args 0 [expr $k - 1]]
		set _vars			[lrange $args [expr $k + 1] [expr $j - 1]]
		
		set params_list		$vars_list
	}
	
	lappend _def $params_list

	foreach _name $params_list _v $_vars {
	
		set script		"\n upvar \$${_name} $_v \n$script"
	}
	
	lappend _def $script
		
	eval $_def
	
	# puts $_def
	
	# puts "__RUN2__ $vars_list"
	
	#
	# invoke it in the caller level
	#
	return [uplevel __RUN2__ $vars_list]
}


#
# @file $_lines >> $pathname
#   write a few lines to a new file; overwite it if exists;
#
# @file $_lines > $pathname
#   append to the file;
#
# @file <$pathname> $command
#   for each line ( $_ ) in the specified file;
#
# @file <$pathname <<"\n\n" $command
#   read each record using the separator "\n\n"
# 

proc @file { args } {

	set j		[lsearch -exact $args ">>"]
	
	if { $j >= 0 } {
		set k				[expr $j + 1]
		set pathname		[lindex $args $k]
		
		set _args		[lreplace $args $j $k]
		
		
		return [eval [list __write_to_file ">>$pathname"] $_args ]
	}
	
	set j		[lsearch -exact $args ">"]
	
	if { $j >= 0 } {
	
		set k				[expr $j + 1]
		set pathname		[lindex $args $k]
		
		set _args		[lreplace $args $j $k]
		
		return [eval [list __write_to_file ">$pathname"] $_args ]
	}
	
	#
	# FIXME check the first and the last argument, for such things as ">pathname"
	#
	set _arg1		[lindex $args 0]
	
	if [begin_with $_arg1 ">>"] {
	
		return [eval __write_to_file $args]
	}
	
	if [begin_with $_arg1 ">"] {
	
		return [eval __write_to_file $args]
	}
	
	set _argN		[lindex $args end]
	
	if [begin_with $_argN ">>"] {
	
		return [eval __write_to_file $args]
	}
	
	if [begin_with $_argN ">"] {
	
		return [eval __write_to_file $args]
	}
	
	#
	# Similiar to Perl style, "while (<>) { ... }"
	#
	set _arg1		[lindex $args 0]
	
	if [regexp {^<(\S+)>$} $_arg1 _x pathname] {
	
		set _chan		[open $pathname "r"]
		fconfigure $_chan -translation binary -encoding binary
		
		#
		# "$_" is the line
		#
		foreach _ [split [read $_chan] "\n"] {
			#
			# execute the script
			#
			eval [lindex $args 1]
		}
		
		return
	}
	
	
}

#
# @file > $pathname .... 
#
# normalize the line into:
#     @file >$pathname
#
proc normalize_args { args } {

	set _args		$args
	
	foreach _s { ">>" "<<" ">" "<" } {
	
		set j		[lsearch -exact $_args $_s]

		if { $j < 0 } continue
	
		#
		# merge it with the next argument ...
		#
		set k		[expr $j + 1 ]
		
		set _p		[lindex $_args $k]
		
		set _args		[lreplace $_args $j $k "$_s$_p"]
	}
	
	return $_args
}


proc __write_to_file { s args } {

	if [begin_with $s ">>"] {
	
		set _pathname		[string range $s 2 end]
		set _mode			"w+"
		
	} elseif [begin_with $s ">"] {
	
		set _pathname		[string range $s 1 end]
		set _mode			"a+"
	} else {
	
		set _pathname		$s
		set _mode			"a+"
	}
	
	set _chan		[open $_pathname $_mode]
	
	foreach _line $args {
		puts $_chan $_line
	}
	
	close $_chan
}


#
# unwilling to introduce a dependency on Tcllib
#
proc check_args { _args args } {
	
	set j	-1
	
	while {1} {
		incr j
		
		if { $j < [llength $_args] } {
			set _v		[lindex $_args $j]
	
			#
			# check if this is a pre-defined option
			#
			if { [lsearch -exact $args $_v] >= 0 } {
				incr j
				set _arr($_v)			[lindex $_args $j]
			
				continue
			}
		}
		
		set _arr(argv)		[lrange $_args $j end]
		break
	}
	
	set _arr(argc)		[llength $_arr(argv)]
	
	return [array get _arr]
}

#
# TODO:
#    支持  -s <split-string> 选项，如 -s "\n\n"
#
proc load_file { txt_file args } {

	set _chan		[open $txt_file "r"]

	set _lines		[split [read $_chan] "\n"]
	
	close $_chan
	
	return $_lines
}

proc split2 { s substr } {

	set start_j		0

	set _len		[string length $substr]
	set result		[list]
	
	while { 1 } {
	
		set j		[string first $substr $s $start_j]
	
		if {$j < 0 } {
			lappend result		[string range $s $start_j end]
			break
		}
		
		set _s		[string range $s $start_j [expr $j - 1] ]
		
		lappend result $_s
		
		set start_j		[expr $j + $_len ]
	}
	
	return $result
}


proc log_to_file { log_file s args } {

	set _chan		[open $log_file "a+"]

	puts $_chan $s
	close $_chan
}

proc write_to_file { pathname s args } {

	set _chan		[open $pathname "w+"]

	foreach _arg $args {
		eval [list fconfigue $_chan] $args
		break
	}
	
	puts -nonewline $_chan $s
	
	close $_chan
}

proc show_progress { format_str args } {


	set _s		[eval [list format $format_str] $args]
	
	puts -nonewline "$_s\r"
	flush stdout
}


proc counter { cmd args } {

	#
	# special command 
	#
	if { $cmd == "show" } {
	
		parray ::counter
		return
	}
	
	if { $cmd == "clear" } {
	
		unset -nocomplain ::counter
		return
	}
	
	if [regexp {^\+(\S+)$} $cmd _x _name] {
	
		if ![info exists ::counter($_name)] {
			set ::counter($_name)		0
		}
		
		incr ::counter($_name)
		
		return
	}
	
	if [regexp {^%(\S+)$} $cmd _x _name] {

		#
		# in case of init value
		#
		foreach _value $args {
		
			set ::counter($_name)		$_value
			break
		}
		
		return $::counter($_name)
	}
}


#
# LOG "...." %reprepro
#    会生成一个独立的  logs/reprepro-${TIME}.log 文件；
#
# LOG "..." >> Packages-%TIME%.txt
#    会生成一个 logs/Packages.txt
#
# LOG "..." > packages.txt
#    添加到文件末尾
#
# LOG "...." %info
#    在正常运行时，应该显示到 console 的信息；
#
# LOG "...." %debug
#

proc set_logs_dir { _dir } {

	set ::logger(logs,dir)		$_dir
	
	set ::logger(time)			[clock format [clock seconds] -format "%Y%m%d-%H-%M-%S"]
}

proc log { _lines args } {

	if [is_empty_list $args] {

		return
	}
	
	foreach _tag $args break
	
	if { $_tag == "%info" } {
	
		puts $_lines
		flush stdout
		
		return
	}
	
	if { $_tag == "%debug" } {
	
		return
	}
	
	if { $_tag == ">" } {
	
		eval __log_to_file $args
		return
	}
	
	if { $_tag == ">>" } {
	
		eval __log_to_file $args
		return
	}
	
	if { [string first ">>" $_tag] == 0 } {
	
		eval [list __log_to_file ">>" [string range $_tag 2 end]] $args
		return
	}
	
	if { [string first ">" $_tag] == 0 } {
	
		eval [list __log_to_file ">" [string range $_tag 1 end]] $args
		return
	}
	
	
	#
	# save to logs/$_tag-${TIME}.log
	#
	if [regexp {%(\S+)} $_tag _x _tag] {
	
		set _time			$::logger(time)
		
		set log_file		[file join $::logger(logs,dir) "${_tag}-${_time}.log" ]
	
		set _chan			[open $log_file "a+"]
		
		puts $_chan $_lines
		
		close $_chan
		return
	}
}

proc __log_to_file { args } {



}



