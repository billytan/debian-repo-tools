#
# common_util.tcl
#

proc debug_log { line } {

	puts $line
	flush stdout
}

proc log_to_file { log_file args } {

	set _chan		[open $log_file "a+"]

	puts $_chan [join $args " "]
	close $_chan
}


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
#    ֧��  -s <split-string> ѡ��� -s "\n\n"
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
#    ������һ��������  logs/reprepro-${TIME}.log �ļ���
#
# LOG "..." >> Packages-%TIME%.txt
#    ������һ�� logs/Packages.txt
#
# LOG "..." > packages.txt
#    ��ӵ��ļ�ĩβ
#
# LOG "...." %info
#    ����������ʱ��Ӧ����ʾ�� console ����Ϣ��
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



