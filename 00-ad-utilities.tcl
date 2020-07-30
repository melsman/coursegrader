# /tcl/00-ad-utilities.tcl
#
# Author: ron@arsdigita.com, February 2000
# 
# This file provides a variety of utilities (originally written by
# philg@mit.edu a long time ago) as well as some compatibility
# functions to handle differences between AOLserver 2.x and 
# AOLserver 3.x.
#
# 00-ad-utilities.tcl,v 1.29.2.13 2000/02/14 07:37:16 ron Exp

proc util_aolserver_2_p {} {
    if {[string index [ns_info version] 0] == "2"} {
	return 1
    } else {
	return 0
    }
}

# Define nsv_set/get/exists for AOLserver 2.0

if [util_aolserver_2_p] {
    uplevel #0 {
	proc nsv_set { array key value } {
	    return [ns_var set "$array,$key" $value]
	}
	
	proc nsv_get { array key } {
	    return [ns_var get "$array,$key"]
	}

	proc nsv_unset {array key } {
	    ns_var unset "$array,$key"
	}
	
	proc nsv_exists { array key } {
	    return [ns_var exists "$array,$key"]
	}

    }
}

# Let's define the nsv arrays out here, so we can call nsv_exists
# on their keys without checking to see if it already exists.
# we create the array by setting a bogus key.

nsv_set proc_source_file . ""

proc proc_doc {name args doc_string body} {
    # let's define the procedure first
    proc $name $args $body
    nsv_set proc_doc $name $doc_string
    # generate a log message for multiply defined scripts
    if {[nsv_exists proc_source_file $name]
        && [string compare [nsv_get proc_source_file $name] [info script]] != 0} {
        ns_log Notice "Multiple definition of $name in [nsv_get proc_source_file $name] and [info script]"
    }
    nsv_set proc_source_file $name [info script]
}

proc proc_source_file_full_path {proc_name} {
    if ![nsv_exists proc_source_file $proc_name] {
	return ""
    } else {
	set tentative_path [nsv_get proc_source_file $proc_name]
	regsub -all {/\./} $tentative_path {/} result
	return $result
    }
}

proc_doc util_report_library_entry {{extra_message ""}} "Should be called at beginning of private Tcl library files so that it is easy to see in the error log whether or not private Tcl library files contain errors." {
    set tentative_path [info script]
    regsub -all {/\./} $tentative_path {/} scrubbed_path
    if { [string compare $extra_message ""] == 0 } {
	set message "Loading $scrubbed_path"
    } else {
	set message "Loading $scrubbed_path; $extra_message"
    }
    ns_log Notice $message
}

util_report_library_entry

# stuff to process the data that comes 
# back from the users

# if the form looked like
# <input type=text name=yow> and <input type=text name=bar> 
# then after you run this function you'll have Tcl vars 
# $foo and $bar set to whatever the user typed in the form

# this uses the initially nauseating but ultimately delicious
# Tcl system function "uplevel" that lets a subroutine bash
# the environment and local vars of its caller.  It ain't Common Lisp...

proc set_form_variables {{error_if_not_found_p 1}} {
    if { $error_if_not_found_p == 1} {
	uplevel { if { [ns_getform] == "" } {
	    ns_returnerror 500 "Missing form data"
	    return
	}
       }
     } else {
	 uplevel { if { [ns_getform] == "" } {
	     # we're not supposed to barf at the user but we want to return
	     # from this subroutine anyway because otherwise we'd get an error
	     return
	 }
     }
  }

    # at this point we know that the form is legal
    
    uplevel {
	set form [ns_getform] 
	set form_size [ns_set size $form]
	set form_counter_i 0
	while {$form_counter_i<$form_size} {
	    set [ns_set key $form $form_counter_i] [ns_set value $form $form_counter_i]
	    incr form_counter_i
	}
    }
}

proc DoubleApos {string} {
    regsub -all ' "$string" '' result
    return $result
}

# if the user types "O'Malley" and you try to insert that into an SQL
# database, you will lose big time because the single quote is magic
# in SQL and the insert has to look like 'O''Malley'.  This function
# also trims white space off the ends of the user-typed data.

# if the form looked like
# <input type=text name=yow> and <input type=text name=bar> 
# then after you run this function you'll have Tcl vars 
# $QQfoo and $QQbar set to whatever the user typed in the form
# plus an extra single quote in front of the user's single quotes
# and maybe some missing white space

proc set_form_variables_string_trim_DoubleAposQQ {} {
    uplevel {
	set form [ns_getform] 
	if {$form == ""} {
	    ns_returnerror 500 "Missing form data"
	    return;
	}
	set form_size [ns_set size $form]
	set form_counter_i 0
	while {$form_counter_i<$form_size} {
	    set QQ[ns_set key $form $form_counter_i] [DoubleApos [string trim [ns_set value $form $form_counter_i]]]
	    incr form_counter_i
	}
    }
}

# this one does both the regular and the QQ

proc set_the_usual_form_variables {{error_if_not_found_p 1}} {
    if { [ns_getform] == "" } {
	if $error_if_not_found_p {
	    uplevel { 
		ns_returnerror 500 "Missing form data"
		return
	    }
	} else {
	    return
	}
    }
    uplevel {
	set form [ns_getform] 
	set form_size [ns_set size $form]
	set form_counter_i 0
	while {$form_counter_i<$form_size} {
	    set [ns_set key $form $form_counter_i] [ns_set value $form $form_counter_i]
	    set QQ[ns_set key $form $form_counter_i] [DoubleApos [string trim [ns_set value $form $form_counter_i]]]
	    incr form_counter_i
	}
    }
}

proc set_form_variables_string_trim_DoubleApos {} {
    uplevel {
	set form [ns_getform] 
	if {$form == ""} {
	    ns_returnerror 500 "Missing form data"
	    return;
	}
	set form_size [ns_set size $form]
	set form_counter_i 0
	while {$form_counter_i<$form_size} {
	    set [ns_set key $form $form_counter_i] [DoubleApos [string trim [ns_set value $form $form_counter_i]]]
	    incr form_counter_i
	}
    }
}


proc set_form_variables_string_trim {} {
    uplevel {
	set form [ns_getform] 
	if {$form == ""} {
	    ns_returnerror 500 "Missing form data"
	    return;
	}
	set form_size [ns_set size $form]
	set form_counter_i 0
	while {$form_counter_i<$form_size} {
	    set [ns_set key $form $form_counter_i] [string trim [ns_set value $form $form_counter_i]]
	    incr form_counter_i
	}
    }
}

# debugging kludges

proc NsSettoTclString {set_id} {
    set result ""
    for {set i 0} {$i<[ns_set size $set_id]} {incr i} {
	append result "[ns_set key $set_id $i] : [ns_set value $set_id $i]\n"
    }
    return $result
}

proc get_referrer {} {
    return [ns_set get [ns_conn headers] Referer]
}

proc post_args_to_query_string {} {
    set arg_form [ns_getform]
    if {$arg_form!=""} {
	set form_counter_i 0
	while {$form_counter_i<[ns_set size $arg_form]} {
	    append query_return "[ns_set key $arg_form $form_counter_i]=[ns_urlencode [ns_set value $arg_form $form_counter_i]]&"
	    incr form_counter_i
	}
	set query_return [string trim $query_return &]
    }
}    

proc get_referrer_and_query_string {} {
    if {[ns_conn method]!="GET"} {
	set query_return [post_args_to_query_string]
	return "[get_referrer]?${query_return}"
    } else {
	return [get_referrer]
    }
}

# a philg hack for getting all the values from a set of checkboxes
# returns 0 if none are checked, a Tcl list with the values otherwise 
# terence change: specify default return if none checked
proc_doc util_GetCheckboxValues {form checkbox_name {default_return 0}} "For getting all the boxes from a set of checkboxes in a form.  This procedure takes the complete ns_conn form and returns a list of checkbox values.  It returns 0 if none are found (or some other default return value if specified)." {

    set i 0
    set size [ns_set size $form]

    while {$i<$size} {

	if { [ns_set key $form $i] == $checkbox_name} {

	    # LIST_TO_RETURN will be created if it doesn't exist

	    lappend list_to_return [ns_set value $form $i]

	}
	incr i
    }

    #if no list, you can specify a default return
    #default default is 0

    if { [info exists list_to_return] } { return $list_to_return } else {return $default_return}

}

# a legacy name that is deprecated
proc nmc_GetCheckboxValues {form checkbox_name {default_return 0}} {
    return [util_GetCheckboxValues $form $checkbox_name $default_return]
}


##
#  Database-related code
##

proc nmc_GetNewIDNumber {id_name db} {

    ns_db dml $db "begin transaction;"
    ns_db dml $db "update id_numbers set $id_name = $id_name + 1;"
    set id_number [ns_set value\
	    [ns_db 1row $db "select unique $id_name from id_numbers;"] 0]
    ns_db dml $db "end transaction;"

    return $id_number

}


# if you do a 
#   set selection [ns_db 1row $db "select foo,bar from my_table where key=37"]
#   set_variables_after_query
# then you will find that the Tcl vars $foo and $bar are set to whatever
# the database returned.  If you don't like these var names, you can say
#   set selection [ns_db 1row $db "select count(*) as n_rows from my_table"]
#   set_variables_after_query
# and you will find the Tcl var $n_rows set

# You can also use this in a multi-row loop
#   set selection [ns_db select $db "select *,upper(email) from mailing_list order by upper(email)"]
#   while { [ns_db getrow $db $selection] } {
#        set_variables_after_query
#         ... your code here ...
#   }
# then the appropriate vars will be set during your loop

#
# CAVEAT NERDOR:  you MUST use the variable name "selection"
# 

#
# we pick long names for the counter and limit vars
# because we don't want them to conflict with names of
# database columns or in parent programs
#

proc set_variables_after_query {} {
    uplevel {
	    set set_variables_after_query_i 0
	    set set_variables_after_query_limit [ns_set size $selection]
	    while {$set_variables_after_query_i<$set_variables_after_query_limit} {
		set [ns_set key $selection $set_variables_after_query_i] [ns_set value $selection $set_variables_after_query_i]
		incr set_variables_after_query_i
	    }
    }
}

# as above, but you must use sub_selection

proc set_variables_after_subquery {} {
    uplevel {
	    set set_variables_after_query_i 0
	    set set_variables_after_query_limit [ns_set size $sub_selection]
	    while {$set_variables_after_query_i<$set_variables_after_query_limit} {
		set [ns_set key $sub_selection $set_variables_after_query_i] [ns_set value $sub_selection $set_variables_after_query_i]
		incr set_variables_after_query_i
	    }
    }
}

#same as philg's but you can:
#1. specify the name of the "selection" variable
#2. append a prefix to all the named variables

proc set_variables_after_query_not_selection {selection_variable {name_prefix ""}} {
    set set_variables_after_query_i 0
    set set_variables_after_query_limit [ns_set size $selection_variable]
    while {$set_variables_after_query_i<$set_variables_after_query_limit} {
        # NB backslash squarebracket needed since mismatched {} would otherwise mess up value stmt.
	uplevel "
	set ${name_prefix}[ns_set key $selection_variable $set_variables_after_query_i] \[ns_set value $selection_variable $set_variables_after_query_i]
	"
	incr set_variables_after_query_i
    }
}

# takes a query like "select unique short_name from products where product_id = 45"
# and returns the result (only works when you are after a single row/column
# intersection)

proc database_to_tcl_string {db sql} {

    set selection [ns_db 1row $db $sql]

    return [ns_set value $selection 0]

}

proc database_to_tcl_string_or_null {db sql {null_value ""}} {
    set selection [ns_db 0or1row $db $sql]
    if { $selection != "" } {
	return [ns_set value $selection 0]
    } else {
	# didn't get anything from the database
	return $null_value
    }
}

#for commands like set full_name  ["select first_name, last_name..."]

proc database_cols_to_tcl_string {db sql} {
    set string_to_return ""	
    set selection [ns_db 1row $db $sql]
    set size [ns_set size $selection]
    set i 0
    while {$i<$size} {
	append string_to_return " [ns_set value $selection $i]"
        incr i
    }
    return [string trim $string_to_return]
}

# takes a query like "select product_id from foobar" and returns all
# the ids as a Tcl list

proc database_to_tcl_list {db sql} {
    
    set selection [ns_db select $db $sql]

    set list_to_return [list]

    while {[ns_db getrow $db $selection]} {

	lappend list_to_return [ns_set value $selection 0]

    }

    return $list_to_return

}

proc database_to_tcl_list_list {db sql} {
    set selection [ns_db select $db $sql]

    set list_to_return ""

    while {[ns_db getrow $db $selection]} {

	set row_list ""
	set size [ns_set size $selection]
	set i 0
	while {$i<$size} {
	    lappend row_list [ns_set value $selection $i]
	    incr i
	}
	lappend list_to_return $row_list
    }

    return $list_to_return
}

proc database_1row_to_tcl_list {db sql} {

    if [catch {set selection [ns_db 1row $db $sql]} errmsg] {
	return ""
    }
    set list_to_return ""
    set size [ns_set size $selection]
    set counter 0

    while {$counter<$size} {
	lappend list_to_return [ns_set value $selection $counter]
	incr counter
    }

    return $list_to_return
}


proc_doc ad_dbclick_check_dml { db table_name id_column_name generated_id return_url insert_sql } "
this proc is used for pages using double click protection. table_name is table_name for which we are checking whether the double click occured. id_column_name is the name of the id table column. generated_id is the generated id, which is supposed to have been generated on the previous page. return_url is url to which this procedure will return redirect in the case of successful insertion in the database. insert_sql is the sql insert statement. if data is ok this procedure will insert data into the database in a double click safe manner and will returnredirect to the page specified by return_url. if database insert fails, this procedure will return a sensible error message to the user." {
    if [catch { 
	ns_db dml $db $insert_sql
    } errmsg] {
	# Oracle choked on the insert
	
	# detect double click
	set selection [ns_db 0or1row $db "
	select 1
	from $table_name
	where $id_column_name='[DoubleApos $generated_id]'"]
	
	if { ![empty_string_p $selection] } {
	    # it's a double click, so just redirect the user to the index page
	    ns_returnredirect $return_url
	    return
	}
	
	ns_log Error "[info script] choked. Oracle returned error:  $errmsg"

	ad_return_error "Error in insert" "
	We were unable to do your insert in the database. 
	Here is the error that was returned:
	<p>
	<blockquote>
	<pre>
	$errmsg
	</pre>
	</blockquote>"
	return
    }

    ns_returnredirect $return_url
    return
}

proc nmc_IllustraDatetoPrettyDate {sql_date} {

    regexp {(.*)-(.*)-(.*)$} $sql_date match year month day

    set allthemonths {January February March April May June July August September October November December}

    # we have to trim the leading zero because Tcl has such a 
    # brain damaged model of numbers and decided that "09-1"
    # was "8.0"

    set trimmed_month [string trimleft $month 0]
    set pretty_month [lindex $allthemonths [expr $trimmed_month - 1]]

    return "$pretty_month $day, $year"

}

proc util_IllustraDatetoPrettyDate {sql_date} {

    regexp {(.*)-(.*)-(.*)$} $sql_date match year month day

    set allthemonths {January February March April May June July August September October November December}

    # we have to trim the leading zero because Tcl has such a 
    # brain damaged model of numbers and decided that "09-1"
    # was "8.0"

    set trimmed_month [string trimleft $month 0]
    set pretty_month [lindex $allthemonths [expr $trimmed_month - 1]]

    return "$pretty_month $day, $year"

}

# this is the preferred one to use

proc_doc util_AnsiDatetoPrettyDate {sql_date} "Converts 1998-09-05 to September 5, 1998" {
    if ![regexp {(.*)-(.*)-(.*)$} $sql_date match year month day] {
	return ""
    } else {
	set allthemonths {January February March April May June July August September October November December}

	# we have to trim the leading zero because Tcl has such a 
	# brain damaged model of numbers and decided that "09-1"
	# was "8.0"

	set trimmed_month [string trimleft $month 0]
	set pretty_month [lindex $allthemonths [expr $trimmed_month - 1]]

	set trimmed_day [string trimleft $day 0]

	return "$pretty_month $trimmed_day, $year"
    }
}

# from the new-utilities.tcl file

proc remove_nulls_from_ns_set {old_set_id} {

    set new_set_id [ns_set new "no_nulls$old_set_id"]

    for {set i 0} {$i<[ns_set size $old_set_id]} {incr i} {
	if { [ns_set value $old_set_id $i] != "" } {

	    ns_set put $new_set_id [ns_set key $old_set_id $i] [ns_set value $old_set_id $i]

	}

    }

    return $new_set_id

}

proc merge_form_with_ns_set {form set_id} {

    for {set i 0} {$i<[ns_set size $set_id]} {incr i} {
	set form [ns_formvalueput $form [ns_set key $set_id $i] [ns_set value $set_id $i]]
    }

    return $form

}

proc merge_form_with_query {form db query} {

    set set_id [ns_db 0or1row $db $query]

    if { $set_id != "" } {

	for {set i 0} {$i<[ns_set size $set_id]} {incr i} {
	    set form [ns_formvalueput $form [ns_set key $set_id $i] [ns_set value $set_id $i]]
	}

    }

    return $form

}


proc bt_mergepiece {htmlpiece values} {
    # HTMLPIECE is a form usually; VALUES is an ns_set

    # NEW VERSION DONE BY BEN ADIDA (ben@mit.edu)
    # Last modification (ben@mit.edu) on Jan ?? 1998
    # added support for dates in the date_entry_widget.
    #
    # modification (ben@mit.edu) on Jan 12th, 1998
    # when the val of an option tag is "", things screwed up
    # FIXED.
    #
    # This used to count the number of vars already introduced
    # in the form (see remaining num_vars statements), so as 
    # to end early. However, for some unknown reason, this cut off a number 
    # of forms. So now, this processes every tag in the HTML form.

    set newhtml ""
    
    set html_piece_ben $htmlpiece

    set num_vars 0

    for {set i 0} {$i<[ns_set size $values]} {incr i} {
	if {[ns_set key $values $i] != ""} {
	    set database_values([ns_set key $values $i]) [philg_quote_double_quotes [ns_set value $values $i]]
	    incr num_vars
	} 
    }

    set vv {[Vv][Aa][Ll][Uu][Ee]}     ; # Sorta obvious
    set nn {[Nn][Aa][Mm][Ee]}         ; # This is too
    set qq {"([^"]*)"}                ; # Matches what's in quotes
    set pp {([^ ]*)}                  ; # Matches a word (mind yer pp and qq)

    set slist {}
    
    set count 0

    while {1} {

	incr count
	set start_point [string first < $html_piece_ben]
	if {$start_point==-1} {
	    append newhtml $html_piece_ben
	    break;
	}
	if {$start_point>0} {
	    append newhtml [string range $html_piece_ben 0 [expr $start_point - 1]]
	}
	set end_point [string first > $html_piece_ben]
	if {$end_point==-1} break
	incr start_point
	incr end_point -1
	set tag [string range $html_piece_ben $start_point $end_point]
	incr end_point 2
	set html_piece_ben [string range $html_piece_ben $end_point end]
	set CAPTAG [string toupper $tag]

	set first_white [string first " " $CAPTAG]
	set first_word [string range $CAPTAG 0 [expr $first_white - 1]]
	
	switch -regexp $CAPTAG {
	    
	    {^INPUT} {
		if {[regexp {TYPE[ ]*=[ ]*("IMAGE"|"SUBMIT"|"RESET"|IMAGE|SUBMIT|RESET)} $CAPTAG]} {
		    
		    ###
		    #   Ignore these
		    ###
		    
		    append newhtml <$tag>
		    
		} elseif {[regexp {TYPE[ ]*=[ ]*("CHECKBOX"|CHECKBOX)} $CAPTAG]} {
		    # philg and jesse added optional whitespace 8/9/97
		    ## If it's a CHECKBOX, we cycle through
		    #  all the possible ns_set pair to see if it should
		    ## end up CHECKED or not.
		    
		    if {[regexp "$nn=$qq" $tag m nam]} {}\
			    elseif {[regexp "$nn=$pp" $tag m nam]} {}\
			    else {set nam ""}
		    
		    if {[regexp "$vv=$qq" $tag m val]} {}\
			    elseif {[regexp "$vv=$pp" $tag m val]} {}\
			    else {set val ""}
		    
		    regsub -all {[Cc][Hh][Ee][Cc][Kk][Ee][Dd]} $tag {} tag
		    
		    # support for multiple check boxes provided by michael cleverly
		    if {[info exists database_values($nam)]} {
			if {[ns_set unique $values $nam]} {
			    if {$database_values($nam) == $val} {
				append tag " checked"
				incr num_vars -1
			    }
			} else {
			    for {set i [ns_set find $values $nam]} {$i < [ns_set size $values]} {incr i} {
				if {[ns_set key $values $i] == $nam && [philg_quote_double_quotes [ns_set value $values $i]] == $val} {
				    append tag " checked"
				    incr num_vars -1
				    break
				}
			    }
			}
		    }

		    append newhtml <$tag>
		    
		} elseif {[regexp {TYPE[ ]*=[ ]*("RADIO"|RADIO)} $CAPTAG]} {
		    
		    ## If it's a RADIO, we remove all the other
		    #  choices beyond the first to keep from having
		    ## more than one CHECKED
		    
		    if {[regexp "$nn=$qq" $tag m nam]} {}\
			    elseif {[regexp "$nn=$pp" $tag m nam]} {}\
			    else {set nam ""}
		    
		    if {[regexp "$vv=$qq" $tag m val]} {}\
			    elseif {[regexp "$vv=$pp" $tag m val]} {}\
			    else {set val ""}
		    
		    #Modified by Ben Adida (ben@mit.edu) so that
		    # the checked tags are eliminated only if something
		    # is in the database. 
		    
		    if {[info exists database_values($nam)]} {
			regsub -all {[Cc][Hh][Ee][Cc][Kk][Ee][Dd]} $tag {} tag
			if {$database_values($nam)==$val} {
			    append tag " checked"
			    incr num_vars -1
			}
		    }
		    
		    append newhtml <$tag>
		    
		} else {
		    
		    ## If it's an INPUT TYPE that hasn't been covered
		    #  (text, password, hidden, other (defaults to text))
		    ## then we add/replace the VALUE tag
		    
		    if {[regexp "$nn=$qq" $tag m nam]} {}\
			    elseif {[regexp "$nn=$pp" $tag m nam]} {}\
			    else {set nam ""}

		    set nam [ns_urldecode $nam]

		    if {[info exists database_values($nam)]} {
			regsub -all "$vv=$qq" $tag {} tag
			regsub -all "$vv=$pp" $tag {} tag
			append tag " value=\"$database_values($nam)\""
			incr num_vars -1
		    } else {
			if {[regexp {ColValue.([^.]*).([^ ]*)} $tag all nam type]} {
			    set nam [ns_urldecode $nam]
			    set typ ""
			    if {[string match $type "day"]} {
				set typ "day"
			    }
			    if {[string match $type "year"]} {
				set typ "year"
			    }
			    if {$typ != ""} {
				if {[info exists database_values($nam)]} {
				    regsub -all "$vv=$qq" $tag {} tag
				    regsub -all "$vv=$pp" $tag {} tag
				    append tag " value=\"[ns_parsesqldate $typ $database_values($nam)]\""
				}
			    }
			    #append tag "><nam=$nam type=$type typ=$typ" 
			}
		    }
		    append newhtml <$tag>
		}
	    }
	    
	    {^TEXTAREA} {
		
		###
		#   Fill in the middle of this tag
		###
		
		if {[regexp "$nn=$qq" $tag m nam]} {}\
			elseif {[regexp "$nn=$pp" $tag m nam]} {}\
			else {set nam ""}
		
		if {[info exists database_values($nam)]} {
		    while {![regexp {^<( *)/[Tt][Ee][Xx][Tt][Aa][Rr][Ee][Aa]} $html_piece_ben]} {
			regexp {^.[^<]*(.*)} $html_piece_ben m html_piece_ben
		    }
		    append newhtml <$tag>$database_values($nam)
		    incr num_vars -1
		} else {
		    append newhtml <$tag>
		}
	    }
	    
	    {^SELECT} {
		
		###
		#   Set the snam flag, and perhaps smul, too
		###
		
		set smul [regexp "MULTIPLE" $CAPTAG]
		
		set sflg 1
		
		set select_date 0
		
		if {[regexp "$nn=$qq" $tag m snam]} {}\
			elseif {[regexp "$nn=$pp" $tag m snam]} {}\
			else {set snam ""}

		set snam [ns_urldecode $snam]

		# In case it's a date
		if {[regexp {ColValue.([^.]*).month} $snam all real_snam]} {
		    if {[info exists database_values($real_snam)]} {
			set snam $real_snam
			set select_date 1
		    }
		}
		
		lappend slist $snam
		
		append newhtml <$tag>
	    }
	    
	    {^OPTION} {
		
		###
		#   Find the value for this
		###
		
		if {$snam != ""} {
		    
		    if {[lsearch -exact $slist $snam] != -1} {regsub -all {[Ss][Ee][Ll][Ee][Cc][Tt][Ee][Dd]} $tag {} tag}
		    
		    if {[regexp "$vv *= *$qq" $tag m opt]} {}\
			    elseif {[regexp "$vv *= *$pp" $tag m opt]} {}\
			    else {
			if {[info exists opt]} {
			    unset opt
		    }   }
		    # at this point we've figured out what the default from the form was
		    # and put it in $opt (if the default was spec'd inside the OPTION tag
		    # just in case it wasn't, we're going to look for it in the 
		    # human-readable part
		    regexp {^([^<]*)(.*)} $html_piece_ben m txt html_piece_ben
		    if {![info exists opt]} {
			set val [string trim $txt]
		    } else {
			set val $opt
		    }
		    
		    if {[info exists database_values($snam)]} {
			# If we're dealing with a date
			if {$select_date == 1} {
			    set db_val [ns_parsesqldate month $database_values($snam)]
			} else {
			    set db_val $database_values($snam)
			}

			if {
			    ($smul || $sflg) &&
			    [string match $db_val $val]
			} then {
			    append tag " selected"
			    incr num_vars -1
			    set sflg 0
			}
		    }
		}
		append newhtml <$tag>$txt
	    }
	    
	    {^/SELECT} {
		    
		###
		#   Do we need to add to the end?
		###
		
		set txt ""
		
		if {$snam != ""} {
		    if {[info exists database_values($snam)] && $sflg} {
			append txt "<option selected>$database_values($snam)"
			incr num_vars -1
			if {!$smul} {set snam ""}
		    }
		}
		
		append newhtml $txt<$tag>
	    }
	    
	    {default} {
		append newhtml <$tag>
	    }
	}
	
    }
    return $newhtml
}



# database stuff


proc_doc GetColumnNames {db table} "returns a list with the column names of the table" {
    #returns a list with the column names of the table
    set size [ns_column count $db $table]
    set i 0
    set column_names ""
    while {$i<$size} {
	lappend column_names [ns_column name $db $table $i]
	incr i
    }
    return $column_names;
}

proc util_GetNewIDNumber {id_name db} {

    ns_db dml $db "begin transaction;"
    ns_db dml $db "update id_numbers set $id_name = $id_name + 1;"
    set id_number [ns_set value\
	    [ns_db 1row $db "select unique $id_name from id_numbers;"] 0]
    ns_db dml $db "end transaction;"

    return $id_number

}

proc util_prepare_update {db table_name primary_key_name primary_key_value form} {

    set form_size [ns_set size $form]
    set form_counter_i 0
    set column_list [GetColumnNames $db $table_name]
    while {$form_counter_i<$form_size} {

	set form_var_name [ns_set key $form $form_counter_i]
	set value [string trim [ns_set value $form $form_counter_i]]
	if { ($form_var_name != $primary_key_name) && ([lsearch $column_list $form_var_name] != -1) } {

	    set column_type [ns_column type $db $table_name $form_var_name]

	    # we use the NaviServer built-in function quoted_value
	    # which is part of the nsdb tcl module (util.tcl)

	    #Added this to allow dates and such to call things
	    #like "current_date"--this is kludgy and should be
	    #fleshed out

	    if {[regexp {date|time} $column_type]&&[regexp -nocase {current} $value]} {
		set quoted_value $value
	    } else {
		set quoted_value [ns_dbquotevalue $value $column_type]
	    }

	    lappend the_sets "$form_var_name = $quoted_value"


	}

	incr form_counter_i
    }

    set primary_key_type [ns_column type $db $table_name $primary_key_name]

    return "update $table_name\nset [join $the_sets ",\n"] \n where $primary_key_name = [ns_dbquotevalue $primary_key_value $primary_key_type]"
    
}

proc util_prepare_update_multi_key {db table_name primary_key_name_list primary_key_value_list form} {

    set form_size [ns_set size $form]
    set form_counter_i 0
    while {$form_counter_i<$form_size} {

	set form_var_name [ns_set key $form $form_counter_i]
	set value [string trim [ns_set value $form $form_counter_i]]

	if { [lsearch -exact $primary_key_name_list $form_var_name] == -1 } {

	    # this is not one of the keys

	    set column_type [ns_column type $db $table_name $form_var_name]

	    # we use the NaviServer built-in function quoted_value
	    # which is part of the nsdb tcl module (util.tcl)

	    set quoted_value [ns_dbquotevalue $value $column_type]

	    lappend the_sets "$form_var_name = $quoted_value"


	}

	incr form_counter_i
    }

    for {set i 0} {$i<[llength $primary_key_name_list]} {incr i} {

	set this_key_name [lindex $primary_key_name_list $i]
	set this_key_value [lindex $primary_key_value_list $i]
	set this_key_type [ns_column type $db $table_name $this_key_name]

	lappend key_eqns "$this_key_name = [ns_dbquotevalue $this_key_value $this_key_type]"

    }

    return "update $table_name\nset [join $the_sets ",\n"] \n where [join $key_eqns " AND "]"
    
}

proc util_prepare_insert {db table_name primary_key_name primary_key_value form} {

    set form_size [ns_set size $form]
    set form_counter_i 0
    while {$form_counter_i<$form_size} {

	set form_var_name [ns_set key $form $form_counter_i]
	set value [string trim [ns_set value $form $form_counter_i]]

	if { $form_var_name != $primary_key_name } {

	    set column_type [ns_column type $db $table_name $form_var_name]

	    # we use the NaviServer built-in function quoted_value
	    # which is part of the nsdb tcl module (util.tcl)

	    set quoted_value [ns_dbquotevalue $value $column_type]

	    lappend the_names $form_var_name
	    lappend the_vals $quoted_value


	}

	incr form_counter_i
    }

    set primary_key_type [ns_column type $db $table_name $primary_key_name]

    return "insert into $table_name\n($primary_key_name,[join $the_names ","]) \n values ([ns_dbquotevalue $primary_key_value $primary_key_type],[join $the_vals ","])"
    
}

proc util_prepare_insert_string_trim {db table_name primary_key_name primary_key_value form} {

    set form_size [ns_set size $form]
    set form_counter_i 0
    while {$form_counter_i<$form_size} {

	set form_var_name [ns_set key $form $form_counter_i]
	set value [string trim [ns_set value $form $form_counter_i]]

	if { $form_var_name != $primary_key_name } {

	    set column_type [ns_column type $db $table_name $form_var_name]

	    # we use the NaviServer built-in function quoted_value
	    # which is part of the nsdb tcl module (util.tcl)

	    set quoted_value [ns_dbquotevalue $value $column_type]

	    lappend the_names $form_var_name
	    lappend the_vals $quoted_value


	}

	incr form_counter_i
    }

    set primary_key_type [ns_column type $db $table_name $primary_key_name]

    return "insert into $table_name\n($primary_key_name,[join $the_names ","]) \n values ([ns_dbquotevalue $primary_key_value $primary_key_type],[join $the_vals ","])"
    
}

proc util_prepare_insert_no_primary_key {db table_name form} {

    set form_size [ns_set size $form]
    set form_counter_i 0
    while {$form_counter_i<$form_size} {

	set form_var_name [ns_set key $form $form_counter_i]
	set value [string trim [ns_set value $form $form_counter_i]]

	set column_type [ns_column type $db $table_name $form_var_name]

	# we use the NaviServer built-in function quoted_value
	# which is part of the nsdb tcl module (util.tcl)

	set quoted_value [ns_dbquotevalue $value $column_type]

	lappend the_names $form_var_name
	lappend the_vals $quoted_value

	incr form_counter_i
    }


    return "insert into $table_name\n([join $the_names ","]) \n values ([join $the_vals ","])"
    
}

proc util_PrettySex {m_or_f { default "default" }} {
    if { $m_or_f == "M" || $m_or_f == "m" } {
	return "Male"
    } elseif { $m_or_f == "F" || $m_or_f == "f" } {
	return "Female"
    } else {
	# Note that we can't compare default to the empty string as in 
	# many cases, we are going want the default to be the empty
	# string
	if { [string compare $default "default"] == 0 } {
	    return "Unknown (\"$m_or_f\")"
	} else {
	    return $default
	}
    }
}

proc util_PrettySexManWoman {m_or_f { default "default"} } {
    if { $m_or_f == "M" || $m_or_f == "m" } {
	return "Man"
    } elseif { $m_or_f == "F" || $m_or_f == "f" } {
	return "Woman"
    } else {
	# Note that we can't compare default to the empty string as in 
	# many cases, we are going want the default to be the empty
	# string
	if { [string compare $default "default"] == 0 } {
	    return "Person of Unknown Sex"
	} else {
	    return $default
	}
    }
}

proc util_PrettyBoolean {t_or_f { default  "default" } } {
    if { $t_or_f == "t" || $t_or_f == "T" } {
	return "Yes"
    } elseif { $t_or_f == "f" || $t_or_f == "F" } {
	return "No"
    } else {
	# Note that we can't compare default to the empty string as in 
	# many cases, we are going want the default to be the empty
	# string
	if { [string compare $default "default"] == 0 } {
	    return "Unknown (\"$t_or_f\")"
	} else {
	    return $default
	}
    }
}


proc_doc util_PrettyTclBoolean {zero_or_one} "Turns a 1 (or anything else that makes a Tcl IF happy) into Yes; anything else into No" {
    if $zero_or_one {
	return "Yes"
    } else {
	return "No"
    }
}

# Pre-declare the cache arrays used in util_memoize.
nsv_set util_memorize_cache_value . ""
nsv_set util_memorize_cache_timestamp . ""

proc_doc util_memoize {tcl_statement {oldest_acceptable_value_in_seconds ""}} "Returns the result of evaluating the Tcl statement argument and then remembers that value in a cache; the memory persists for the specified number of seconds (or until the server is restarted if the second argument is not supplied) or until someone calls util_memoize_flush with the same Tcl statement.  Note that this procedure should be used with care because it calls the eval built-in procedure (and therefore an unscrupulous user could  " {

    # we look up the statement in the cache to see if it has already
    # been eval'd.  The statement itself is the key

    if { ![nsv_exists util_memorize_cache_value $tcl_statement] || ( ![empty_string_p $oldest_acceptable_value_in_seconds] && ([expr [nsv_get util_memorize_cache_timestamp $tcl_statement] + $oldest_acceptable_value_in_seconds] < [ns_time]) )} {

	# not in the cache already OR the caller spec'd an expiration
	# time and our cached value is too old

	set statement_value [eval $tcl_statement]
	nsv_set util_memorize_cache_value $tcl_statement $statement_value
	# store the time in seconds since 1970
	nsv_set util_memorize_cache_timestamp $tcl_statement [ns_time]
    }

    return [nsv_get util_memorize_cache_value $tcl_statement]
}

# flush the cache

proc_doc util_memoize_flush {tcl_statement} "Flush the cached value (established with util_memoize associated with the argument)" {

    if [nsv_exists util_memorize_cache_value $tcl_statement] {
	nsv_unset util_memorize_cache_value $tcl_statement
    }
    if [nsv_exists util_memorize_cache_timestamp $tcl_statement] {
	nsv_unset util_memorize_cache_timestamp $tcl_statement
    }
}

proc_doc util_memoize_value_cached_p {tcl_statement {oldest_acceptable_value_in_seconds ""}} "Returns 1 if there is a cached value for this Tcl expression.  If a second argument is supplied, only returns 1 if the cached value isn't too old." {

    # we look up the statement in the cache to see if it has already
    # been eval'd.  The statement itself is the key

    if { ![nsv_exists util_memorize_cache_value $tcl_statement] || ( ![empty_string_p $oldest_acceptable_value_in_seconds] && ([expr [nsv_get util_memorize_cache_timestamp $tcl_statement] + $oldest_acceptable_value_in_seconds] < [ns_time]) )} {
	return 0
    } else {
	return 1
    }    
}


proc current_year {db} {
    util_memoize "current_year_internal $db"
}

proc current_year_internal {db} {

    database_to_tcl_string $db "return extract(year from current_date)"

}

proc philg_server_default_pool {} {
    set server_name [ns_info server]
    append config_path "ns\\server\\" $server_name "\\db"
    set default_pool [ns_config $config_path DefaultPool]
    return $default_pool
}

# this is typically called like this...
# philg_urldecode_form_variable [ns_getform]
# and it is called for effect, not value
# we use it if we've urlencoded something for a hidden
# variable (e.g., to escape the string quotes) in a form

proc philg_urldecode_form_variable {form variable_name} {
    set old_value [ns_set get $form $variable_name]
    set new_value [ns_urldecode $old_value]
    # one has to delete the old value first, otherwise
    # you just get two values for the same key in the ns_set
    ns_set delkey $form $variable_name
    ns_set put $form $variable_name $new_value
}

proc util_convert_plaintext_to_html {raw_string} {
    if { [regexp -nocase {<p>} $raw_string] || [regexp -nocase {<br>} $raw_string] } {
	# user was already trying to do this as HTML
	return $raw_string
    } else {
	# quote <, >, and &
	set clean_for_html [ns_quotehtml $raw_string]
	# turn CRLFCRLF into <P>
	if { [regsub -all "\015\012\015\012" $clean_for_html "\n\n<p>\n\n" clean_for_html] == 0 } {
	    # try LFLF
	    if { [regsub -all "\012\012" $clean_for_html "\n\n<p><p>\n\n" clean_for_html] == 0 } {
		# try CRCR
		regsub -all "\015\015" $clean_for_html "\n\n<p><p>\n\n" clean_for_html
	    }
	}
	return $clean_for_html
    }
}

proc_doc util_maybe_convert_to_html {raw_string html_p} "very useful for info pulled from the news, neighbor, events subsystems."  {
    if { $html_p == "t" } {
	return $raw_string
    } else {
	return [util_convert_plaintext_to_html $raw_string]
    }
}


# turn " into &quot; before using strings inside hidden vars
# patched on May 31, 1999 by philg to also quote >, <, and &
# fixed a bug in /bboard/confirm

proc philg_quote_double_quotes {arg} {
    # we have to do & first or we'll hose ourselves with the ones lower down
    regsub -all & $arg \\&amp\; arg
    regsub -all \" $arg \\&quot\; arg
    regsub -all < $arg \\&lt\; arg
    regsub -all > $arg \\&gt\; arg
    return $arg
}

# stuff that will let us do what ns_striphtml does but a little better

proc_doc util_striphtml {html} {Returns a best-guess plain text version of an HTML fragment.  Better than ns_striphtml because it doesn't replace & g t ; and & l t ; with empty string.} {
    return [util_expand_entities [util_remove_html_tags $html]]
}

proc util_remove_html_tags {html} {
   regsub -all {<[^>]*>} $html {} html
   return $html
}

proc util_expand_entities {html} {
   regsub -all {&lt;} $html {<} html
   regsub -all {&gt;} $html {>} html
   regsub -all {&quot;} $html {"} html
   regsub -all {&amp;} $html {\&} html
   return $html
}

proc util_GetUserAgentHeader {} {
    set header [ns_conn headers]

    # note that this MUST be case-insensitive search (iget)
    # due to a NaviServer bug -- philg 2/1/96

    set userag [ns_set iget $header "USER-AGENT"]
    return $userag
}

proc msie_p {} {
    return [regexp -nocase {msie} [util_GetUserAgentHeader]]
}

proc submit_button_if_msie_p {} {
    if { [msie_p] } {
	return "<input type=submit>"
    } else {
	return ""
    }
}

proc randomInit {seed} {
    nsv_set rand ia 9301
    nsv_set rand ic 49297
    nsv_set rand im 233280
    nsv_set rand seed $seed
}

# initialize the random number generator

randomInit [ns_time]

proc random {} {
    nsv_set rand seed [expr ([nsv_get rand seed] * [nsv_get rand ia] + [nsv_get rand ic]) % [nsv_get rand im]]
    return [expr [nsv_get rand seed]/double([nsv_get rand im])]
}

proc randomRange {range} {
    return [expr int([random] * $range)]
}

proc capitalize {word} {
    if {$word != ""} {
	set newword ""
	if [regexp {[^ ]* [^ ]*} $word] {
	    set words [split $word]
	    foreach part $words {
		set newword "$newword [capitalize $part]"
	    }
	} else {
	    regexp {^(.)(.*)$} $word match firstchar rest
	    set newword [string toupper $firstchar]$rest
	}
	return [string trim $newword]
    }
    return $word
}

proc html_select_options {options {select_option ""}} {
    #this is html to be placed into a select tag
    set select_options ""
    foreach option $options {
	if { [lsearch $select_option $option] != -1 } {
	    append select_options "<option selected>$option\n"
	} else {
	    append select_options "<option>$option\n"
	}
    }
    return $select_options
}

proc db_html_select_options {db query {select_option ""}} {
    #this is html to be placed into a select tag
    set select_options ""
    set options [database_to_tcl_list $db $query]
    foreach option $options {
	if { [string compare $option $select_option] == 0 } {
	    append select_options "<option selected>$option\n"
	} else {
	    append select_options "<option>$option\n"
	}
    }
    return $select_options
}

proc html_select_value_options {options {select_option ""} {value_index 0} {option_index 1}} {
    #this is html to be placed into a select tag
    #when value!=option, set the index of the return list
    #from the db query. selected option must match value

    set select_options ""
    foreach option $options {
	if { [lsearch $select_option [lindex $option $value_index]] != -1 } {
	    append select_options "<option value=[lindex $option $value_index] selected>[lindex $option $option_index]\n"
	} else {
	    append select_options "<option value=[lindex $option $value_index]>[lindex $option $option_index]\n"
	}
    }
    return $select_options
}

proc db_html_select_value_options {db query {select_option ""} {value_index 0} {option_index 1}} {
    #this is html to be placed into a select tag
    #when value!=option, set the index of the return list
    #from the db query. selected option must match value

    set select_options ""
    set options [database_to_tcl_list_list $db $query]
    foreach option $options {
	if { [lsearch $select_option [lindex $option $value_index]] != -1 } {
	    append select_options "<option value=[lindex $option $value_index] selected>[lindex $option $option_index]\n"
	} else {
	    append select_options "<option value=[lindex $option $value_index]>[lindex $option $option_index]\n"
	}
    }
    return $select_options
}

# new philg kludges

# produces a safe-for-browsers hidden variable, i.e., one where
# " has been replaced by &quot; 

proc philg_hidden_input {name value} {
    return "<input type=hidden name=\"$name\" value=\"[philg_quote_double_quotes $value]\">"
}

# this REGEXP was very kindly contributed by Jeff Friedl, author of 
# _Mastering Regular Expressions_ (O'Reilly 1997)
proc_doc philg_email_valid_p {query_email} "Returns 1 if an email address has more or less the correct form" {
    return [regexp "^\[^@\t ]+@\[^@.\t]+(\\.\[^@.\n ]+)+$" $query_email]
}

proc_doc philg_url_valid_p {query_url} "Returns 1 if a URL has more or less the correct form." {
    return [regexp {http://.+} $query_url]
}

# just checking it for format, not semantics

proc philg_date_valid_p {query_date} {
    return [regexp {[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]} $query_date]
}
# Return a string of hidden input fields for a form to pass along any
# of the parameters in args if they exist in the current environment.
#  -- jsc@arsdigita.com

# usage:  [export_form_vars foo bar baz]

proc export_form_vars args {
    set hidden ""
    foreach var $args {
        if [eval uplevel {info exists $var}] {
            upvar 1 $var value
            append hidden "<input type=hidden name=$var value=\"[philg_quote_double_quotes $value]\">\n"
        }
    }
    return $hidden
}

proc export_entire_form {} {
    set hidden ""
    set the_form [ns_getform]
    for {set i 0} {$i<[ns_set size $the_form]} {incr i} {
	set varname [ns_set key $the_form $i]
	set varvalue [ns_set value $the_form $i]
	append hidden "<input type=hidden name=\"$varname\" value=\"[philg_quote_double_quotes $varvalue]\">\n"
    }
    return $hidden
}


proc_doc export_ns_set_vars {{format "url"} {exclusion_list ""}  {setid ""}} "Returns all the params in an ns_set with the exception of those in exclusion_list. If no setid is provide, ns_getform is used. If format = url, a url parameter string will be returned. If format = form, a block of hidden form fragments will be returned."  {

    if [empty_string_p $setid] {
	set setid [ns_getform]
    }

    set return_list [list]
    if ![empty_string_p $setid] {
        set set_size [ns_set size $setid]
        set set_counter_i 0
        while { $set_counter_i<$set_size } {
            set name [ns_set key $setid $set_counter_i]
            set value [ns_set value $setid $set_counter_i]
            if {[lsearch $exclusion_list $name] == -1 && ![empty_string_p $name]} {
                if {$format == "url"} {
                    lappend return_list "$name=[ns_urlencode $value]"
                } else {
                    lappend return_list " name=$name value=\"[philg_quote_double_quotes $value]\""
                }
            }
            incr set_counter_i
        }
    }
    if {$format == "url"} {
        return [join $return_list "&"]
    } else {
        return "<input type=hidden [join $return_list ">\n <input type=hidden "] >"
    }
}


# Return a URL parameter string passing along all the parameters 
# given to it as arguments, if they exist in the current environment. 
# -- jsc@arsdigita.com 
proc_doc export_url_vars args "Returns a string of key=value pairs suitable for inclusion in a URL; you can pass it any number of variables as arguments.  If any are defined in the caller's environment, they are included.  See also export_entire_form_as_url_vars" { 
    set params {} 
    foreach var $args { 
        if [eval uplevel {info exists $var}] { 
            upvar 1 $var value 
            lappend params "$var=[ns_urlencode $value]" 
        } 
    } 
    return [join $params "&"] 
} 
 
proc_doc export_entire_form_as_url_vars {{vars_to_passthrough ""}} "Returns a URL parameter string of name-value pairs of all the form parameters passed to this page. If vars_to_passthrough is given, it should be a list of parameter names that will be the only ones passed through." {
    set params [list]
    set the_form [ns_getform]
    for {set i 0} {$i<[ns_set size $the_form]} {incr i} {
	set varname [ns_set key $the_form $i]
	set varvalue [ns_set value $the_form $i]
	if { $vars_to_passthrough == "" || ([lsearch -exact $vars_to_passthrough $varname] != -1) } {
	    lappend params "$varname=[ns_urlencode $varvalue]" 
	}
    }
    return [join $params "&"]
}


# we use this to shut off spam scheduling and such 
# it asks the question "is this just a development server"?

# we write DevelopmentServer=1 into the server portion of the .ini file

# [ns/server/philg]
# DevelopmentServer=1


proc philg_development_p {} {
    set config_param [ns_config "ns/server/[ns_info server]" DevelopmentServer]
    if { $config_param == 1 } {
	return 1
    } else {
	return 0
    }
}

proc philg_keywords_match {keywords string_to_search} {
    # turn keywords into space-separated things
    # replace one or more commads with a space
    regsub -all {,+} $keywords " " keywords_no_commas
    set keyword_list [split $keywords_no_commas " "]
    set found_p 0
    foreach word $keyword_list {
	# turns out that "" is never found in a search, so we
	# don't really have to special case $word == ""
	if { $word != "" && [string first [string toupper $word] [string toupper $string_to_search]] != -1 } {
	    # found it!
	    set found_p 1
	}
    }
    return $found_p
}

proc_doc philg_keywords_score {keywords string_to_search} "Takes space-separated keywords and returns 0 if none are found or a count of how many matched.  If a keyword occurs twice then it is weighted 2." {
    # turn keywords into space-separated things
    # replace one or more commads with a space
    regsub -all {,+} $keywords " " keywords_no_commas
    set keyword_list [split $keywords_no_commas " "]
    set score 0
    foreach word $keyword_list {
	# turns out that "" is never found in a search, so we
	# don't really have to special case $word == ""
	if { $word != "" && [string first [string toupper $word] [string toupper $string_to_search]] != -1 } {
	    # found at least one!
	    if { [string first [string toupper $word] [string toupper $string_to_search]] == [string last [string toupper $word] [string toupper $string_to_search]] } {
		# only one occurrence
		incr score
	    } else {
		# more than one, count as 2 (like AltaVista)
		incr score 2
	    }
	}
    }
    return $score
}

# usage: 
#   suppose the variable is called "expiration_date"
#   put "[philg_dateentrywidget expiration_date]" in your form
#     and it will expand into lots of weird generated var names
#   put ns_dbformvalue [ns_getform] expiration_date date expiration_date
#     and whatever the user typed will be set in $expiration_date

proc philg_dateentrywidget {column {default_date "1940-11-03"}} {
    ns_share NS

    set output "<SELECT name=ColValue.[ns_urlencode $column].month>\n"
    for {set i 0} {$i < 12} {incr i} {
	append output "<OPTION> [lindex $NS(months) $i]\n"
    }

    append output \
"</SELECT>&nbsp;<INPUT NAME=ColValue.[ns_urlencode $column].day\
TYPE=text SIZE=3 MAXLENGTH=2>&nbsp;<INPUT NAME=ColValue.[ns_urlencode $column].year\
TYPE=text SIZE=5 MAXLENGTH=4>"

    return [ns_dbformvalueput $output $column date $default_date]
}

proc philg_dateentrywidget_default_to_today {column} {
    set today [lindex [split [ns_localsqltimestamp] " "] 0]
    return [philg_dateentrywidget $column $today]
}

# Perform the dml statements in sql_list in a transaction.
# Aborts the transaction and returns an error message if
# an error occurred for any of the statements, otherwise
# returns null string. -jsc
proc do_dml_transactions {db sql_list} {
    ns_db dml $db "begin transaction"
    foreach stmt $sql_list {
        if [catch {ns_db dml $db $stmt} errmsg] {
            ns_db dml $db "abort transaction"
            return $errmsg
        }
    }
    ns_db dml $db "end transaction"
    return ""
}

# Perform body within a database transaction.
# Execute on_error if there was some error caught
# within body, with errmsg bound.
# This procedure will clobber errmsg in the caller.
# -jsc
proc with_transaction {db body on_error} {
    upvar errmsg errmsg
    global errorInfo errorCode
    if [catch {ns_db dml $db "begin transaction"
               uplevel $body
               ns_db dml $db "end transaction"} errmsg] {
        ns_db dml $db "abort transaction"
        set code [catch {uplevel $on_error} string]
        # Return out of the caller appropriately.
        if { $code == 1 } {
            return -code error -errorinfo $errorInfo -errorcode $errorCode $string
        } elseif { $code == 2 } {
            return -code return $string
        } elseif { $code == 3 } {
            return -code break
	} elseif { $code == 4 } {
	    return -code continue
        } elseif { $code > 4 } {
            return -code $code $string
        }
    }        
}

proc with_catch {error_var body on_error} { 
    upvar 1 $error_var $error_var 
    global errorInfo errorCode 
    if [catch { uplevel $body } $error_var] { 
        set code [catch {uplevel $on_error} string] 
        # Return out of the caller appropriately. 
        if { $code == 1 } { 
            return -code error -errorinfo $errorInfo -errorcode $errorCode $string 
        } elseif { $code == 2 } { 
            return -code return $string 
        } elseif { $code == 3 } { 
            return -code break
	} elseif { $code == 4 } {
	    return -code continue
        } elseif { $code > 4 } { 
            return -code $code $string 
        } 
    }         
} 

proc_doc empty_string_p {query_string} "returns 1 if a string is empty; this is better than using == because it won't fail on long strings of numbers" {
    if { [string compare $query_string ""] == 0 } {
	return 1
    } else {
	return 0
    }
}

proc_doc string_contains_p {small_string big_string} {Returns 1 if the BIG_STRING contains the SMALL_STRING, 0 otherwise; syntactic sugar for string first != -1} {
    if { [string first $small_string $big_string] == -1 } {
	return 0
    } else {
	return 1
    }
}

# -- philg had this at Primehost

# take a string and wrap it to 80 columns max this does not justify
# text, only insert line breaks

proc_doc wrap_string {input {threshold 80}} "wraps a string to be no wider than 80 columns by inserting line breaks" {
    set result_rows [list]
    set start_of_line_index 0
    while 1 {
	set this_line [string range $input $start_of_line_index [expr $start_of_line_index + $threshold - 1]]
	if { $this_line == "" } {
	    return [join $result_rows "\n"]
	}
	set first_new_line_pos [string first "\n" $this_line]
	if { $first_new_line_pos != -1 } {
	    # there is a newline
	    lappend result_rows [string range $input $start_of_line_index [expr $start_of_line_index + $first_new_line_pos - 1]]
	    set start_of_line_index [expr $start_of_line_index + $first_new_line_pos + 1]
	    continue
	}
	if { [expr $start_of_line_index + $threshold + 1] >= [string length $input] } {
	    # we're on the last line and it is < threshold so just return it
		lappend result_rows $this_line
		return [join $result_rows "\n"]
	}
	set last_space_pos [string last " " $this_line]
	if { $last_space_pos == -1 } {
	    # no space found!  Try the first space in the whole rest of the string
	    set $last_space_pos [string first " " [string range $input $start_of_line_index end]]
	    if { $last_space_pos == -1 } {
		# didn't find any more spaces, append the whole thing as a line
		lappend result_rows [string range $input $start_of_line_index end]
		return [join $result_rows "\n"]
	    }
	}
	# OK, we have a last space pos of some sort
	set real_index_of_space [expr $start_of_line_index + $last_space_pos]
	lappend result_rows [string range $input $start_of_line_index [expr $real_index_of_space - 1]]
	set start_of_line_index [expr $start_of_line_index + $last_space_pos + 1]
    }
}

proc remove_whitespace {input_string} {
    if [regsub -all "\[\015\012\t \]" $input_string "" output_string] {
	return $output_string 
    } else {
	return $input_string
    }
}

proc util_just_the_digits {input_string} {
    if [regsub -all {[^0-9]} $input_string "" output_string] {
	return $output_string 
    } else {
	return $input_string
    }
}

# sort of the opposite (for phone numbers, takes
# 6172538574 and turns it into "(617) 253-8574")

proc philg_format_phone_number {just_the_digits} {
    if { [string length $just_the_digits] != 10 } {
	return $just_the_digits
    } else {
	return "([string range $just_the_digits 0 2]) [string range $just_the_digits 3 5]-[string range $just_the_digits 6 9]"
    }
}

# putting commas into numbers (thank you, Michael Bryzek)

proc_doc util_commify_number { num } {Returns the number with commas inserted where appropriate. Number can be positive or negative and can have a decimal point. e.g. -1465.98 => -1,465.98} {
    while { 1 } {
	# Regular Expression taken from mastering regular expressions
	# matches optional leading negative sign plus any
	# other 3 digits, starting from end
	if { ![regsub -- {^(-?[0-9]+)([0-9][0-9][0-9])} $num {\1,\2} num] } {
	    break
	}
    }
    return $num
}

# for limiting a string to 4000 characters because the Oracle SQL
# parser is so stupid and can only handle a string literal that long

proc util_limit_to_4000_chars {input_string} {
    return [string range $input_string 0 3999]
}


proc leap_year_p {year} {
    expr ( $year % 4 == 0 ) && ( ( $year % 100 != 0 ) || ( $year % 400 == 0 ) )
}

proc_doc ad_proc args {
    Use just like proc, but first argument must be a named argument description.
    A named argument description is a list of flag/default value pairs:
    {-arg1 arg1default -arg2 arg2default}
    By jsc@arsdigita.com
} {

    set proc_name [lindex $args 0]
    set ad_args [lindex $args 1]

    nsv_set ad_proc_args $proc_name $ad_args

    generate_argument_parser $proc_name $ad_args

    # Four argument version indicates use of proc_doc instead of proc.
    if { [llength $args] == 4 } {
        set doc_string [lindex $args 2]
        set body [lindex $args 3]
        proc_doc $proc_name args $doc_string "arg_parser_for_$proc_name \$args\n$body"
    } else {
        set body [lindex $args 2]
        proc $proc_name args "arg_parser_for_$proc_name \$args\n$body"
    }
}

# Helper function, acts like perl shift:
# Return value of first element and remove it from the list.
proc shift {list_name} {
    upvar 1 $list_name list_to_shift
    set first_arg_p 1
    set first_arg ""
    set rest ""

    foreach element $list_to_shift {
        if { $first_arg_p } {
            set first_arg $element
            set first_arg_p 0
        } else {
            lappend rest $element
        }
    }
    set list_to_shift $rest
    return $first_arg
}

# Helper function: If its argument does not start with "{", surround
# it with a pair of braces.
proc format_as_list {some_list} {
    if { [string index $some_list 0] == "\{" } {
        return $some_list
    } else {
        return "{$some_list}"
    }
}


# Given the name of a procedure and an argument description,
# creates a procedure named arg_parser_for_{procedure_name} that
# takes an argument list, parses it according to the description,
# and sets the parameters in the argument list as variables in
# its caller's environment. Named values are set to the value they
# are called with, or to the default given in the argument description.
proc generate_argument_parser {proc_name argdesc} {
    # First argument is named argument description; others are
    # regular arguments.
    set named_args_desc [shift argdesc]
    set rest $argdesc
    set named_arg_length [llength $named_args_desc]

    # Use the named argument description to generate two hunks of tcl,
    # one for initially setting defaults for all the named arguments,
    # and another one which will handle those arguments in a switch
    # statement.
    set flag_clauses ""
    set defaults_setting_clauses ""

    for {set i 0} {$i < $named_arg_length} {incr i} {
        set flag [lindex $named_args_desc $i]
        set named_arg [string range $flag 1 end]
        incr i
        set flag_value [lindex $named_args_desc $i]

        append defaults_setting_clauses "
            upvar 1 $named_arg $named_arg
            set $named_arg \"$flag_value\"
        "

        append flag_clauses "
                        $flag {
                            incr i
                            upvar 1 $named_arg $named_arg
                            set $named_arg \[lindex \$arglist \$i\]
                            continue
                        }
"
    }

    # Generate the Tcl for creating the argument parser procedure.
    set evalstr "proc arg_parser_for_$proc_name arglist {
        set regular_arg_names [format_as_list $rest]
        set regular_arg_index 0
        set regular_arg_length \[llength \$regular_arg_names\]
        set parsing_named_args_p 1

$defaults_setting_clauses

        set arg_length \[llength \$arglist\]
        for {set i 0} {\$i < \$arg_length} {incr i} {
            set arg \[lindex \$arglist \$i\]

            if \$parsing_named_args_p {
                if { \[string index \$arg 0\] == \"-\" } {
                    switch -- \$arg {
                        \"--\" {
                            set parsing_named_args_p 0
                            continue
                        }
$flag_clauses
                        default {
                            error \"Unrecognized argument \$arg\"
                        }
                    }
                } else {
                    set parsing_named_args_p 0
                }
            }

            if { !\$parsing_named_args_p } {
                if { \$regular_arg_index == \$regular_arg_length } {
                    error \"called \\\"$proc_name\\\" with too many arguments\"
                }
                set regular_arg_name \[lindex \$regular_arg_names \$regular_arg_index\]
                incr regular_arg_index
                upvar \$regular_arg_name \$regular_arg_name
                set \$regular_arg_name \$arg
            }
        }
        if { \$regular_arg_index != \$regular_arg_length } {
            error \"too few arguments given for \\\"$proc_name\\\"\"
        }
    }
"
    eval $evalstr
}

proc_doc util_search_list_of_lists {list_of_lists query_string {sublist_element_pos 0}} "Returns position of sublist that contains QUERY_STRING at SUBLIST_ELEMENT_POS." {
    set sublist_index 0
    foreach sublist $list_of_lists {
	set comparison_element [lindex $sublist $sublist_element_pos]
	if { [string compare $query_string $comparison_element] == 0 } {
	    return $sublist_index
	}
	incr sublist_index
    }
    # didn't find it
    return -1
}

# --- network stuff 

proc_doc util_get_http_status {url {use_get_p 1} {timeout 30}} "Returns the HTTP status code, e.g., 200 for a normal response or 500 for an error, of a URL.  By default this uses the GET method instead of HEAD since not all servers will respond properly to a HEAD request even when the URL is perfectly valid.  Note that this means AOLserver may be sucking down a lot of bits that it doesn't need." { 
    if $use_get_p {
	set http [ns_httpopen GET $url "" $timeout] 
    } else {
	set http [ns_httpopen HEAD $url "" $timeout] 
    }
    # philg changed these to close BOTH rfd and wfd
    set rfd [lindex $http 0] 
    set wfd [lindex $http 1] 
    close $rfd
    close $wfd
    set headers [lindex $http 2] 
    set response [ns_set name $headers] 
    set status [lindex $response 1] 
    ns_set free $headers
    return $status
}

proc_doc util_link_responding_p {url {list_of_bad_codes "404"}} "Returns 1 if the URL is responding (generally we think that anything other than 404 (not found) is okay)." {
    if [catch { set status [util_get_http_status $url] } errmsg] {
	# got an error; definitely not valid
	return 0
    } else {
	# we got the page but it might have been a 404 or something
	if { [lsearch $list_of_bad_codes $status] != -1 } {
	    return 0
	} else {
	    return 1
	}
    }
}

# system by Tracy Adams (teadams@arsdigita.com) to permit AOLserver to POST 
# to another Web server; sort of like ns_httpget

proc_doc util_httpopen {method url {rqset ""} {timeout 30} {http_referer ""}} "Like ns_httpopen but works for POST as well; called by util_httppost" {
    
	if ![string match http://* $url] {
		return -code error "Invalid url \"$url\":  _httpopen only supports HTTP"
	}
	set url [split $url /]
	set hp [split [lindex $url 2] :]
	set host [lindex $hp 0]
	set port [lindex $hp 1]
	if [string match $port ""] {set port 80}
	set uri /[join [lrange $url 3 end] /]
	set fds [ns_sockopen -nonblock $host $port]
	set rfd [lindex $fds 0]
	set wfd [lindex $fds 1]
	if [catch {
		_http_puts $timeout $wfd "$method $uri HTTP/1.0\r"
		if {$rqset != ""} {
			for {set i 0} {$i < [ns_set size $rqset]} {incr i} {
				_http_puts $timeout $wfd \
					"[ns_set key $rqset $i]: [ns_set value $rqset $i]\r"
			}
		} else {
			_http_puts $timeout $wfd \
				"Accept: */*\r"

		    	_http_puts $timeout $wfd "User-Agent: Mozilla/1.01 \[en\] (Win95; I)\r"    
		    	_http_puts $timeout $wfd "Referer: $http_referer \r"    
	}

    } errMsg] {
		global errorInfo
		#close $wfd
		#close $rfd
		if [info exists rpset] {ns_set free $rpset}
		return -1
	}
	return [list $rfd $wfd ""]
    
}


# httppost; give it a URL and a string with formvars, and it 
# returns the page as a Tcl string
# formvars are the posted variables in the following form: 
#        arg1=value1&arg2=value2

# in the event of an error or timeout, -1 is returned

proc_doc util_httppost {url formvars {timeout 30} {depth 0} {http_referer ""}} "Returns the result of POSTing to another Web server or -1 if there is an error or timeout.  formvars should be in the form \"arg1=value1&arg2=value2\"" {
    if [catch {
	if {[incr depth] > 10} {
		return -code error "util_httppost:  Recursive redirection:  $url"
	}
	set http [util_httpopen POST $url "" $timeout $http_referer]
	set rfd [lindex $http 0]
	set wfd [lindex $http 1]

	#headers necesary for a post and the form variables

	_http_puts $timeout $wfd "Content-type: application/x-www-form-urlencoded \r"
	_http_puts $timeout $wfd "Content-length: [string length $formvars]\r"
	_http_puts $timeout $wfd \r
	_http_puts $timeout $wfd "$formvars\r"
	flush $wfd
	close $wfd

	set rpset [ns_set new [_http_gets $timeout $rfd]]
		while 1 {
			set line [_http_gets $timeout $rfd]
			if ![string length $line] break
			ns_parseheader $rpset $line
		}



	set headers $rpset
	set response [ns_set name $headers]
	set status [lindex $response 1]
	if {$status == 302} {
		set location [ns_set iget $headers location]
		if {$location != ""} {
			ns_set free $headers
			close $rfd
			return [ns_httpget $location $timeout $depth]
		}
	}
	set length [ns_set iget $headers content-length]
	if [string match "" $length] {set length -1}
	set err [catch {
		while 1 {
			set buf [_http_read $timeout $rfd $length]
			append page $buf
			if [string match "" $buf] break
			if {$length > 0} {
				incr length -[string length $buf]
				if {$length <= 0} break
			}
		}
	} errMsg]
	ns_set free $headers
	close $rfd
	if $err {
		global errorInfo
		return -code error -errorinfo $errorInfo $errMsg
	}
    } errmgs ] {return -1}
	return $page
}


proc_doc util_report_successful_library_load {{extra_message ""}} "Should be called at end of private Tcl library files so that it is easy to see in the error log whether or not private Tcl library files contain errors." {
    set tentative_path [info script]
    regsub -all {/\./} $tentative_path {/} scrubbed_path
    if { [string compare $extra_message ""] == 0 } {
	set message "Done... $scrubbed_path"
    } else {
	set message "Done... $scrubbed_path; $extra_message"
    }
    ns_log Notice $message
}

proc_doc exists_and_not_null { varname } {Returns 1 if the variable name exists in the caller's environment and is not the empty string.} {
    upvar 1 $varname var 
    return [expr { [info exists var] && ![empty_string_p $var] }] 
} 


proc_doc util_decode args {
    like decode in sql
    Takes the place of an if (or switch) statement -- convenient because it's
    compact and you don't have to break out of an ns_write if you're in one.
    args: same order as in sql: first the unknown value, then any number of
    pairs denoting "if the unknown value is equal to first element of pair,
    then return second element", then if the unknown value is not equal to any
    of the first elements, return the last arg
} {
    set args_length [llength $args]
    set unknown_value [lindex $args 0]
    
    # we want to skip the first & last values of args
    set counter 1
    while { $counter < [expr $args_length -2] } {
	if { [string compare $unknown_value [lindex $args $counter]] == 0 } {
	    return [lindex $args [expr $counter + 1]]
	}
	set counter [expr $counter + 2]
    }
    return [lindex $args [expr $args_length -1]]
}

proc_doc util_httpget {url {headers ""} {timeout 30} {depth 0}} "Just like ns_httpget, but first optional argument is an ns_set of headers to send during the fetch." {
    if {[incr depth] > 10} {
	return -code error "util_httpget:  Recursive redirection:  $url"
    }
    set http [ns_httpopen GET $url $headers $timeout]
    set rfd [lindex $http 0]
    close [lindex $http 1]
    set headers [lindex $http 2]
    set response [ns_set name $headers]
    set status [lindex $response 1]
    if {$status == 302} {
	set location [ns_set iget $headers location]
	if {$location != ""} {
	    ns_set free $headers
	    close $rfd
	    return [ns_httpget $location $timeout $depth]
	}
    }
    set length [ns_set iget $headers content-length]
    if [string match "" $length] {set length -1}
    set err [catch {
	while 1 {
	    set buf [_http_read $timeout $rfd $length]
	    append page $buf
	    if [string match "" $buf] break
	    if {$length > 0} {
		incr length -[string length $buf]
		if {$length <= 0} break
	    }
	}
    } errMsg]
    ns_set free $headers
    close $rfd
    if $err {
	global errorInfo
	return -code error -errorinfo $errorInfo $errMsg
    }
    return $page
}

# some procs to make it easier to deal with CSV files (reading and writing)
# added by philg@mit.edu on October 30, 1999

proc_doc util_escape_quotes_for_csv {string} "Returns its argument with double quote replaced by backslash double quote" {
    regsub -all {"} $string {\"}  result
    return $result
}

proc_doc set_csv_variables_after_query {} {You can call this after an ns_db getrow or ns_db 1row to set local Tcl variables to values from the database.  You get $foo, $EQfoo (the same thing but with double quotes escaped), and $QEQQ (same thing as $EQfoo but with double quotes around the entire she-bang).} {
    uplevel {
	    set set_variables_after_query_i 0
	    set set_variables_after_query_limit [ns_set size $selection]
	    while {$set_variables_after_query_i<$set_variables_after_query_limit} {
		set [ns_set key $selection $set_variables_after_query_i] [ns_set value $selection $set_variables_after_query_i]
		set EQ[ns_set key $selection $set_variables_after_query_i] [util_escape_quotes_for_csv [string trim [ns_set value $selection $set_variables_after_query_i]]]
		set QEQQ[ns_set key $selection $set_variables_after_query_i] "\"[util_escape_quotes_for_csv [string trim [ns_set value $selection $set_variables_after_query_i]]]\""
		incr set_variables_after_query_i
	    }
    }
}

#"

proc_doc ad_page_variables {variable_specs} {
<pre>
Current syntax:

    ad_page_variables {var_spec1 [varspec2] ... }

    This proc handles translating form inputs into Tcl variables, and checking
    to see that the correct set of inputs was supplied.  Note that this is mostly a
    check on the proper programming of a set of pages.

Here are the recognized var_specs:

    variable				; means it's required and not null
    {variable default-value}
      Optional, with default value.  If the value is supplied but is null, and the
      default-value is present, that value is used.
    {variable -multiple-list}
      The value of the Tcl variable will be a list containing all of the
      values (in order) supplied for that form variable.  Particularly useful
      for collecting checkboxes or select multiples.
      Note that if required or optional variables are specified more than once, the
      first (leftmost) value is used, and the rest are ignored.
    {variable -array}
      This syntax supports the idiom of supplying multiple form variables of the
      same name but ending with a "_[0-9]", e.g., foo_1, foo_2.... Each value will be
      stored in the array variable variable with the index being whatever follows the
      underscore.

There is an optional third element in the var_spec.  If it is "QQ", "qq", or
some variant, a variable named "QQvariable" will be created and given the
same value, but with single quotes escaped suitable for handing to SQL.

Other elements of the var_spec are ignored, so a documentation string
describing the variable can be supplied.

Note that the default value form will become the value form in a "set"

Note that the default values are filled in from left to right, and can depend on
values of variables to their left:
ad_page_variables {
    file
    {start 0}
    {end {[expr $start + 20]}}
}
</pre>
} {
    set exception_list [list]
    set form [ns_getform]
    if { $form != "" } {
	set form_size [ns_set size $form]
	set form_counter_i 0

	# first pass -- go through all the variables supplied in the form
	while {$form_counter_i<$form_size} {
	    set variable [ns_set key $form $form_counter_i]
	    set found "not"
	    # find the matching variable spec, if any
	    foreach variable_spec $variable_specs {
		if { [llength $variable_spec] >= 2 } {
		    switch -- [lindex $variable_spec 1] {
			-multiple-list {
			    if { [lindex $variable_spec 0] == $variable } {
				# variable gets a list of all the values
				upvar 1 $variable var
				lappend var [ns_set value $form $form_counter_i]
				set found "done"
				break
			    }
			}
			-array {
			    set varname [lindex $variable_spec 0]
			    set pattern "($varname)_(.+)"
			    if { [regexp $pattern $variable match array index] } {
				if { ![empty_string_p $array] } {
				    upvar 1 $array arr
				    set arr($index) [ns_set value $form $form_counter_i]
				}
				set found "done"
				break
			    }
			}
			default {
			    if { [lindex $variable_spec 0] == $variable } {
				set found "set"
				break
			    }
			}
		    }
		} elseif { $variable_spec == $variable } {
		    set found "set"
		    break
		}
	    }
	    if { $found == "set" } {
		upvar 1 $variable var
		if { ![info exists var] } {
		    # take the leftmost value, if there are multiple ones
		    set var [ns_set value $form $form_counter_i]
		}
	    }
	    incr form_counter_i
	}
    }

    # now make a pass over each variable spec, making sure everything required is there
    # and doing defaulting for unsupplied things that aren't required
    foreach variable_spec $variable_specs {
	set variable [lindex $variable_spec 0]
	upvar 1 $variable var

	if { [llength $variable_spec] >= 2 } {
	    if { ![info exists var] } {
		set default_value_or_flag [lindex $variable_spec 1]
		
		switch -- $default_value_or_flag {
		    -array {
			# don't set anything
		    }
		    -multiple-list {
			set var [list]
		    }
		    default {
			# Needs to be set.
			uplevel [list eval [list set $variable "$default_value_or_flag"]]
		    }
		}
	    }

	    # no longer needed because we QQ everything by default now
	    #	    # if there is a QQ or qq or any variant after the var_spec,
	    #	    # make a "QQ" variable
	    #	    if { [regexp {^[Qq][Qq]$} [lindex $variable_spec 2]] && [info exists var] } {
	    #		upvar QQ$variable QQvar
	    #		set QQvar [DoubleApos $var]
	    #	    }

	} else {
	    if { ![info exists var] } {
		lappend exception_list "\"$variable\" required but not supplied"
	    }
	}

        # modified by rhs@mit.edu on 1/31/2000
	# to QQ everything by default (but not arrays)
        if {[info exists var] && ![array exists var]} {
	    upvar QQ$variable QQvar
	    set QQvar [DoubleApos $var]
	}

    }

    set n_exceptions [llength $exception_list]
    # this is an error in the HTML form
    if { $n_exceptions == 1 } {
	ns_returnerror 500 [lindex $exception_list 0]
	return -code return
    } elseif { $n_exceptions > 1 } {
	ns_returnerror 500 "<li>[join $exception_list "\n<li>"]\n"
	return -code return
    }
}

proc_doc page_validation {args} {
    This proc allows page arg, etc. validation.  It accepts a bunch of
    code blocks.  Each one is executed, and any error signalled is
    appended to the list of exceptions.
    Note that you can customize the complaint page to match the design of your site,
    by changing the proc called to do the complaining:
    it's [ad_parameter ComplainProc "" ad_return_complaint]

    The division of labor between ad_page_variables and page_validation 
    is that ad_page_variables
    handles programming errors, and does simple defaulting, so that the rest of
    the Tcl code doesn't have to worry about testing [info exists ...] everywhere.
    page_validation checks for errors in user input.  For virtually all such tests,
    there is no distinction between "unsupplied" and "null string input".

    Note that errors are signalled using the Tcl "error" function.  This allows
    nesting of procs which do the validation tests.  In addition, validation
    functions can return useful values, such as trimmed or otherwise munged
    versions of the input.
} {
    if { [info exists {%%exception_list}] } {
	error "Something's wrong"
    }
    # have to put this in the caller's frame, so that sub_page_validation can see it
    # that's because the "uplevel" used to evaluate the code blocks hides this frame
    upvar {%%exception_list} {%%exception_list}
    set {%%exception_list} [list]
    foreach validation_block $args {
	if { [catch {uplevel $validation_block} errmsg] } {
	    lappend {%%exception_list} $errmsg
	}
    }
    set exception_list ${%%exception_list}
    unset {%%exception_list}
    set n_exceptions [llength $exception_list]
    if { $n_exceptions != 0 } {
	set complain_proc [ad_parameter ComplainProc "" ad_return_complaint]
	if { $n_exceptions == 1 } {
	    $complain_proc $n_exceptions [lindex $exception_list 0]
	} else {
	    $complain_proc $n_exceptions "<li>[join $exception_list "\n<li>"]\n"
	}
	return -code return
    }
}

proc_doc sub_page_validation {args} {
    Use this inside a page_validation block which needs to check more than one thing.
    Put this around each part that might signal an error.
} {
    # to allow this to be at any level, we search up the stack for {%%exception_list}
    set depth [info level]
    for {set level 1} {$level <= $depth} {incr level} {
	upvar $level {%%exception_list} {%%exception_list}
	if { [info exists {%%exception_list}] } {
	    break
	}
    }
    if { ![info exists {%%exception_list}] } {
	error "sub_page_validation not inside page_validation"
    }
    foreach validation_block $args {
	if { [catch {uplevel $validation_block} errmsg] } {
	    lappend {%%exception_list} $errmsg
	}
    }
}

proc_doc validate_integer {field_name string} "Throws an error if the string isn't a decimal integer; otherwise strips any leading zeros (so this won't work for octals) and returns the result." {
    if { ![regexp {^[0-9]+$} $string] } {
	error "The entry for $field_name, \"$string\" is not an integer"
    }
    # trim leading zeros, so as not to confuse Tcl
    set string [string trimleft $string "0"]
    if { [empty_string_p $string] } {
	# but not all of the zeros
	return "0"
    }
    return $string
}

proc_doc validate_zip_code {field_name db zip_string country_code} "Given a string, signals an error if it's not a legal zip code" {
    if { $country_code == "" || [string toupper $country_code] == "US" } {
	if { [regexp {^[0-9][0-9][0-9][0-9][0-9](-[0-9][0-9][0-9][0-9])?$} $zip_string] } {
	    set zip_5 [string range $zip_string 0 4]
	    set selection [ns_db 0or1row $db "select 1 from dual where exists
(select 1 from zip_codes where zip_code like '$zip_5%')"]
            if { $selection == "" } {
		error "The entry for $field_name, \"$zip_string\" is not a recognized zip code"
	    }
	} else {
	    error "The entry for $field_name, \"$zip_string\" does not look like a zip code"
	}
    } else {
	if { $zip_string != "" } {
	    error "Zip code is not needed outside the US"
	}
    }
    return $zip_string
}

proc_doc validate_ad_dateentrywidget {field_name column form {allow_null 0}} {
} {
    set col [ns_urlencode $column]
    set day [ns_set get $form "ColValue.$col.day"]
    ns_set update $form "ColValue.$col.day" [string trimleft $day "0"]
    set month [ns_set get $form "ColValue.$col.month"]
    set year [ns_set get $form "ColValue.$col.year"]

    # check that either all elements are blank
    # date value is formated correctly for ns_dbformvalue
    if { [empty_string_p "$day$month$year"] } {
	if { $allow_null == 0 } {
	    error "$field_name must be supplied"
	} else {
	    return ""
	}
    } elseif { ![empty_string_p $year] && [string length $year] != 4 } {
	error "The year must contain 4 digits."
    } elseif { [catch  { ns_dbformvalue $form $column date date } errmsg ] } {
	error "The entry for $field_name had a problem:  $errmsg."
    }

    return $date
}



proc_doc util_WriteWithExtraOutputHeaders {headers_so_far {first_part_of_page ""}} "Takes in a string of headers to write to an HTTP connection, terminated by a newline.  Checks \[ns_conn outputheaders\] and adds those headers if appropriate.  Adds two newlines at the end and writes out to the connection.  May optionally be used to write the first part of the page as well (saves a packet)" {
    set set_headers_i 0
    set set_headers_limit [ns_set size [ns_conn outputheaders]]
    while {$set_headers_i < $set_headers_limit} {
	append headers_so_far "[ns_set key [ns_conn outputheaders] $set_headers_i]: [ns_set value [ns_conn outputheaders] $set_headers_i]\n"
	incr set_headers_i
    }
    append entire_string_to_write $headers_so_far "\n" $first_part_of_page
    ns_write $entire_string_to_write
}


# we use this when we want to send out just the headers 
# and then do incremental ns_writes.  This way the user
# doesn't have to wait like if you used a single ns_return

proc ReturnHeaders {{content_type text/html}} {
    set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type\n"
     util_WriteWithExtraOutputHeaders $all_the_headers
}


# All the following ReturnHeaders versions are obsolete;
# just set [ns_conn outputheaders].

proc ReturnHeadersNoCache {{content_type text/html}} {

    ns_write "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type
pragma: no-cache

"

}


proc ReturnHeadersWithCookie {cookie_content {content_type text/html}} {

    ns_write "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type
Set-Cookie:  $cookie_content

"

}

proc ReturnHeadersWithCookieNoCache {cookie_content {content_type text/html}} {

    ns_write "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type
Set-Cookie:  $cookie_content
pragma: no-cache

"

}


proc_doc ad_return_top_of_page {first_part_of_page {content_type text/html}} "Returns HTTP headers plus the top of the user-ivisible page.  Saves a TCP packet (and therefore some overhead) compared to using ReturnHeaders and an ns_write." {
    set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type\n"
     util_WriteWithExtraOutputHeaders $all_the_headers $first_part_of_page
}



proc_doc apply {func arglist} {
    Evaluates the first argument with ARGLIST as its arguments, in the
    environment of its caller. Analogous to the Lisp function of the same name.
} {
    set func_and_args [concat $func $arglist]
    return [uplevel $func_and_args]
}

proc_doc safe_eval args {
    Version of eval that checks its arguments for brackets that may be
used to execute unsafe code.
} {
    foreach arg $args {
	if { [regexp "\\\[" $arg] } {
	    return -code error "Unsafe argument to safe_eval: $arg"
	}
    }
    return [apply uplevel $args]
}

# if this hairy proc doesn't work, complain to davis@arsdigita.com
proc_doc util_close_html_tags {html_fragment {break_soft 0} {break_hard 0}} {
    Given an HTML fragment, this procedure will close any tags that
    have been left open.  The optional arguments let you specify that
    the fragment is to be truncated to a certain number of displayable 
    characters.  After break_soft, it truncates and closes open tags unless 
    you're within non-breaking tags (e.g., Af).  After break_hard displayable
    characters, the procedure simply truncates and closes any open HTML tags
    that might have resulted from the truncation.
    <p>
    Note that the internal syntax table dictates which tags are non-breaking.
    The syntax table has codes:
    <ul>
    <li>  nobr --  treat tag as nonbreaking.
    <li>  discard -- throws away everything until the corresponding close tag.
    <li>  remove -- nuke this tag and its closing tag but leave contents.
    <li>  close -- close this tag if left open.
    </ul>
} {
    set frag $html_fragment 

    set syn(A) nobr
    set syn(ADDRESS) nobr
    set syn(NOBR) nobr
    #
    set syn(FORM) discard
    set syn(TABLE) discard
    #
    set syn(BLINK) remove 
    #
    set syn(FONT) close
    set syn(B) close
    set syn(BIG) close
    set syn(I) close
    set syn(S) close
    set syn(SMALL) close
    set syn(STRIKE) close
    set syn(SUB) close
    set syn(SUP) close
    set syn(TT) close
    set syn(U) close
    set syn(ABBR) close
    set syn(ACRONYM) close
    set syn(CITE) close
    set syn(CODE) close
    set syn(DEL) close
    set syn(DFN) close
    set syn(EM) close
    set syn(INS) close
    set syn(KBD) close
    set syn(SAMP) close
    set syn(STRONG) close
    set syn(VAR) close
    set syn(DIR) close
    set syn(DL) close
    set syn(MENU) close
    set syn(OL) close
    set syn(UL) close
    set syn(H1) close
    set syn(H2) close
    set syn(H3) close
    set syn(H4) close
    set syn(H5) close
    set syn(H6) close
    set syn(BDO) close
    set syn(BLOCKQUOTE) close
    set syn(CENTER) close
    set syn(DIV) close
    set syn(PRE) close
    set syn(Q) close
    set syn(SPAN) close

    set out {} 
    set out_len 0

    # counts how deep we are nested in nonbreaking tags, tracks the nobr point
    # and what the nobr string length would be
    set nobr 0
    set nobr_out_point 0
    set nobr_tagptr 0
    set nobr_len 0

    set discard 0

    set tagptr -1

    # first thing we do is chop off any trailing unclosed tag 
    # since when we substr blobs this sometimes happens
    
    # this should in theory cut any tags which have been cut open.
    while {[regexp {(.*)<[^>]*$} $frag match frag]} {}

    while { "$frag" != "" } {
        # here we attempt to cut the string into "pretag<TAG TAGBODY>posttag"
        # and build the output list.

        if {![regexp "(\[^<]*)(<\[ \t]*(/?)(\[^ \t>]+)(\[^>]*)>)?(.*)" $frag match pretag fulltag close tag tagbody frag]} {
            # should never get here since above will match anything.
            # puts "NO MATCH: should never happen! frag=$frag"
            append out $frag 
            set frag {}
        } else {
            # puts "\n\nmatch=$match\n pretag=$pretag\n fulltag=$fulltag\n close=$close\n tag=$tag\n tagbody=$tagbody\nfrag=$frag\n\n"
            if { ! $discard } {
                # figure out if we can break with the pretag chunk 
                if { $break_soft } {
                    if {! $nobr && [expr [string length $pretag] + $out_len] > $break_soft } {
                        # first chop pretag to the right length
                        set pretag [string range $pretag 0 [expr $break_soft - $out_len]]
                        # clip the last word
                        regsub "\[^ \t\n\r]*$" $pretag {} pretag
                        append out [string range $pretag 0 $break_soft]
                        break
                    } elseif { $nobr &&  [expr [string length $pretag] + $out_len] > $break_hard } {
                        # we are in a nonbreaking tag and are past the hard break
                        # so chop back to the point we got the nobr tag...
                        set tagptr $nobr_tagptr 
                        if { $nobr_out_point > 0 } { 
                            set out [string range $out 0 [expr $nobr_out_point - 1]]
                        } else { 
                            # here maybe we should decide if we should keep the tag anyway 
                            # if zero length result would be the result...
                            set out {}
                        }
                        break
                    } 
                }
                
                # tack on pretag
                append out $pretag
                incr out_len [string length $pretag]
            }
            
            # now deal with the tag if we got one...
            if  { $tag == "" } { 
                # if the tag is empty we might have one of the bad matched that are not eating 
                # any of the string so check for them 
                if {[string length $match] == [string length $frag]} { 
                    append out $frag
                    set frag {}
                }
            } else {
                set tag [string toupper $tag]            
                if { ![info exists syn($tag)]} {
                    # if we don't have an entry in our syntax table just tack it on 
                    # and hope for the best.
                    if { ! $discard } {
                        append  out $fulltag
                    }
                } else {
                    if { $close != "/" } {
                        # new tag 
                        # "remove" tags are just ignored here
                        # discard tags 
                        if { $discard } { 
                            if { $syn($tag) == "discard" } {
                                incr discard 
                                incr tagptr 
                                set tagstack($tagptr) $tag
                            }
                        } else {
                            switch $syn($tag) {
                                nobr { 
                                    if { ! $nobr } {
                                        set nobr_out_point [string length $out]
                                        set nobr_tagptr $tagptr
                                        set nobr_len $out_len
                                    }
                                    incr nobr
                                    incr tagptr 
                                    set tagstack($tagptr) $tag
                                    append out $fulltag
                                }
                                discard { 
                                    incr discard 
                                    incr tagptr 
                                    set tagstack($tagptr) $tag
                                }
                                close {                                 
                                    incr tagptr 
                                    set tagstack($tagptr) $tag
                                    append out $fulltag
                                }
                            }
                        }
                    } else { 
                        # we got a close tag
                        if { $discard } { 
                            # if we are in discard mode only watch for 
                            # closes to discarded tags
                            if { $syn($tag) == "discard"} {
                                if {$tagptr > -1} {
                                    if { $tag != $tagstack($tagptr) } {
                                        #puts "/$tag without $tag"
                                    } else {
                                        incr tagptr -1
                                        incr discard -1
                                    }
                                }
                            }
                        } else {
                            if { $syn($tag) != "remove"} {
                                # if tag is a remove tag we just ignore it...
                                if {$tagptr > -1} {
                                    if {$tag != $tagstack($tagptr) } {
                                        # puts "/$tag without $tag"
                                    } else {
                                        incr tagptr -1
                                        if { $syn($tag) == "nobr"} {
                                            incr nobr -1
                                        } 
                                        append out $fulltag
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    # on exit of the look either we parsed it all or we truncated. 
    # we should now walk the stack and close any open tags.

    for {set i $tagptr} { $i > -1 } {incr i -1} { 
        # append out "<!-- autoclose --> </$tagstack($i)>"
        append out "</$tagstack($i)>"
    }
    
    return $out
}


ad_proc util_dbq {
    { 
        -null_is_null_p f
    }
    vars
} {
    Given a list of variable names this routine 
    creates variables named DBQvariable_name which can be used in 
    sql insert and update statements.  
    <p>
    If -null_is_null_p is t then we return the string "null" unquoted
    so that "update foo set var = $DBQvar where ..." will do what we want 
    if we default var to "null".
} {
    foreach var $vars {
	upvar 1 $var val
        if [info exists val] {
            if { $null_is_null_p == "t" 
                 && $val == {null} } {
                uplevel [list set DBQ$var {null}]
            } else {
                uplevel [list set DBQ$var "'[DoubleApos [string trim $val]]'"]
            }
        }
    }
}

proc_doc ad_decode { args } "this procedure is analogus to sql decode procedure. first parameter is the value we want to decode. this parameter is followed by a list of pairs where first element in the pair is convert from value and second element is convert to value. last value is default value, which will be returned in the case convert from values matches the given value to be decoded" {
    set num_args [llength $args]
    set input_value [lindex $args 0]

    set counter 1

    while { $counter < [expr $num_args - 2] } {
	lappend from_list [lindex $args $counter]
	incr counter
	lappend to_list [lindex $args $counter]
	incr counter
    }

    set default_value [lindex $args $counter]

    if { $counter < 2 } {
	return $default_value
    }

    set index [lsearch -exact $from_list $input_value]
    
    if { $index < 0 } {
	return $default_value
    } else {
	return [lindex $to_list $index]
    }
}

proc_doc ad_urlencode { string } "same as ad_urlencode except that dash and underscore are left unencoded." {
    set encoded_string [ns_urlencode $string]
    regsub -all {%2d} $encoded_string {-} encoded_string
    regsub -all {%5f} $encoded_string {_} ad_encoded_string
    return $ad_encoded_string
}

util_report_successful_library_load

# The remainder of the file was merged from:
#
# /tcl/000-aolserver-3-specific.tcl
#
# It defines procs that one only needs for AOLserver 3.0 (necessitated
# by the fact that most of our code base comes from AOLserver 1.x and
# 2.x.
#
# This section was put together by markd@arsdigita.com

if [util_aolserver_2_p] {
    # Nothing below is needed by AOLserver 2.x, so bail out
    return
} else {
    ns_log Notice "00-ad-utilities.tcl loading procs for AOLserver 2.x compatibility" 
}

# these were mostly stolen from various places the AOLserver 2.3.3 release

# ns_dbquotename:
#
# If name contains a space, then it is surrounded by double quotes.
# This is useful for names in SQL statements that may contain spaces.

proc ns_dbquotename {name} {
    if [regexp " " $name] {
	return "\"$name\""
    } else {
	return $name
    }   
}

# ns_dbquotevalue:
#
# Prepares a value string for inclusion in an SQL statement.
# "" is translated into NULL.
# All values of any numeric type are left alone.
# All other values are surrounded by single quotes and any
# single quotes included in the value are escaped (ie. translated
# into 2 single quotes). 

proc ns_dbquotevalue {value {type text}} {

    if [string match $value ""] {
	return "NULL"
    }

    if {$type == "decimal" \
	    || $type == "double" \
	    || $type == "integer" \
	    || $type == "int" \
	    || $type == "real" \
	    || $type == "smallint" \
	    || $type == "bigint" \
	    || $type == "bit" \
	    || $type == "float" \
	    || $type == "numeric" \
	    || $type == "tinyint"} {
	return $value
    }
    regsub -all "'" $value "''" value
    return "'$value'"
}



# -1 = Not there or value was ""
#  0 = NULL, set value to NULL.
#  1 = Got value, set value to it.

proc ns_dbformvalue {formdata column type valuebyref} {

    upvar $valuebyref value

    if {[ns_set get $formdata ColValue.[ns_urlencode $column].NULL] == "t"} {
	set value ""
	return 0
    }

    set value [ns_set get $formdata ColValue.[ns_urlencode $column]]

    if [string match $value ""] {
        switch $type {
	    
	    date      {
		set value [ns_buildsqldate \
			[ns_set get $formdata ColValue.[ns_urlencode $column].month] \
			[ns_set get $formdata ColValue.[ns_urlencode $column].day] \
			[ns_set get $formdata ColValue.[ns_urlencode $column].year]]
	    }
	    
	    time      {
		set value [ns_buildsqltime \
			[ns_set get $formdata ColValue.[ns_urlencode $column].time] \
			[ns_set get $formdata ColValue.[ns_urlencode $column].ampm]]
	    }
	    
            datetime  -
	    timestamp {
		set value [ns_buildsqltimestamp \
			[ns_set get $formdata ColValue.[ns_urlencode $column].month] \
			[ns_set get $formdata ColValue.[ns_urlencode $column].day] \
			[ns_set get $formdata ColValue.[ns_urlencode $column].year] \
			[ns_set get $formdata ColValue.[ns_urlencode $column].time] \
			[ns_set get $formdata ColValue.[ns_urlencode $column].ampm]]
	    }
	    
	    default {
	    }
	}
    }
    if [string match $value ""] {
	return -1
    } else {
	return 1
    }
}

proc ns_dbformvalueput {htmlform column type value} {

    switch $type {

	date {
	    set retval [ns_formvalueput $htmlform ColValue.[ns_urlencode $column].NULL f]
	    set retval [ns_formvalueput $retval ColValue.[ns_urlencode $column].month \
		    [ns_parsesqldate month $value]]
	    set retval [ns_formvalueput $retval ColValue.[ns_urlencode $column].day \
		    [ns_parsesqldate day $value]]
	    set retval [ns_formvalueput $retval ColValue.[ns_urlencode $column].year \
		    [ns_parsesqldate year $value]]
	}

	time {
	    set retval [ns_formvalueput $htmlform ColValue.[ns_urlencode $column].NULL f]
	    set retval [ns_formvalueput $retval ColValue.[ns_urlencode $column].time \
		    [ns_parsesqltime time $value]]
	    set retval [ns_formvalueput $retval ColValue.[ns_urlencode $column].ampm \
		    [ns_parsesqltime ampm $value]]

	}

        datetime  -
	timestamp {
	    set retval [ns_formvalueput $htmlform ColValue.[ns_urlencode $column].NULL f]
	    set retval [ns_formvalueput $retval ColValue.[ns_urlencode $column].month \
		    [ns_parsesqltimestamp month $value]]
	    set retval [ns_formvalueput $retval ColValue.[ns_urlencode $column].day \
		    [ns_parsesqltimestamp day $value]]
	    set retval [ns_formvalueput $retval ColValue.[ns_urlencode $column].year \
		    [ns_parsesqltimestamp year $value]]
	    set retval [ns_formvalueput $retval ColValue.[ns_urlencode $column].time \
		    [ns_parsesqltimestamp time $value]]
	    set retval [ns_formvalueput $retval ColValue.[ns_urlencode $column].ampm \
		    [ns_parsesqltimestamp ampm $value]]
	    
	}

	default {

	    set retval [ns_formvalueput $htmlform ColValue.[ns_urlencode $column] $value]
	}
    }
    return $retval
}

# Special thanks to Brian Tivol at Hearst New Media Center and MIT
# for providing the core of this code.

proc ns_formvalueput {htmlpiece dataname datavalue} {

    set newhtml ""

    while {$htmlpiece != ""} {
	if {[string index $htmlpiece 0] == "<"} {
	    regexp {<([^>]*)>(.*)} $htmlpiece m tag htmlpiece
	    set tag [string trim $tag]
	    set CAPTAG [string toupper $tag]

	    switch -regexp $CAPTAG {

		{^INPUT} {
		    if {[regexp {TYPE=("IMAGE"|"SUBMIT"|"RESET"|IMAGE|SUBMIT|RESET)} $CAPTAG]} {
			append newhtml <$tag>
			
		    } elseif {[regexp {TYPE=("CHECKBOX"|CHECKBOX|"RADIO"|RADIO)} $CAPTAG]} {
			
			set name [ns_tagelement $tag NAME]

			if {$name == $dataname} {

			    set value [ns_tagelement $tag VALUE]

			    regsub -all -nocase { *CHECKED} $tag {} tag

			    if {$value == $datavalue} {
				append tag " CHECKED"
			    }
			}
			append newhtml <$tag>

		    } else {

			## If it's an INPUT TYPE that hasn't been covered
			#  (text, password, hidden, other (defaults to text))
			## then we add/replace the VALUE tag
			
			set name [ns_tagelement $tag NAME]
			
			if {$name == $dataname} {
			    ns_tagelementset tag VALUE $datavalue
			}
			append newhtml <$tag>
		    }
		}

		{^TEXTAREA} {

		    ###
		    #   Fill in the middle of this tag
		    ###

		    set name [ns_tagelement $tag NAME]
		    
		    if {$name == $dataname} {
			while {![regexp -nocase {^<( *)/TEXTAREA} $htmlpiece]} {
			    regexp {^.[^<]*(.*)} $htmlpiece m htmlpiece
			}
			append newhtml <$tag>$datavalue
		    } else {
			append newhtml <$tag>
		    }
		}
		
		{^SELECT} {

		    ### Set flags so OPTION and /SELECT know what to look for:
		    #   snam is the variable name, sflg is 1 if nothing's
		    ### been added, smul is 1 if it's MULTIPLE selection


		    if {[ns_tagelement $tag NAME] == $dataname} {
			set inkeyselect 1
			set addoption 1
		    } else {
			set inkeyselect 0
			set addoption 0
		    }

		    append newhtml <$tag>
		}

		{^OPTION} {
		    
		    ###
		    #   Find the value for this
		    ###

		    if {$inkeyselect} {

			regsub -all -nocase { *SELECTED} $tag {} tag

			set value [ns_tagelement $tag VALUE]

			regexp {^([^<]*)(.*)} $htmlpiece m txt htmlpiece

			if [string match "" $value] {
			    set value [string trim $txt]
			}

			if {$value == $datavalue} {
			    append tag " SELECTED"
			    set addoption 0
			}
			append newhtml <$tag>$txt
		    } else {
			append newhtml <$tag>
		    }
		}

		{^/SELECT} {
		    
		    ###
		    #   Do we need to add to the end?
		    ###
		    
		    if {$inkeyselect && $addoption} {
			append newhtml "<option selected>$datavalue<$tag>"
		    } else {
			append newhtml <$tag>
		    }
		    set inkeyselect 0
		    set addoption 0
		}
		
		{default} {
		    append newhtml <$tag>
		}
	    }

	} else {
	    regexp {([^<]*)(.*)} $htmlpiece m brandnew htmlpiece
	    append newhtml $brandnew
	}
    }
    return $newhtml
}

proc ns_tagelement {tag key} {
    set qq {"([^"]*)"}                ; # Matches what's in quotes
    set pp {([^ >]*)}                 ; # Matches a word (mind yer pp and qq)
    
    if {[regexp -nocase "$key *= *$qq" $tag m name]} {}\
	    elseif {[regexp -nocase "$key *= *$pp" $tag m name]} {}\
	    else {set name ""}
    return $name
}


# Assumes that the final ">" in the tag has been removed, and
# leaves it removed

proc ns_tagelementset {tagvar key value} {

    upvar $tagvar tag

    set qq {"([^"]*)"}                ; # Matches what's in quotes
    set pp {([^ >]*)}                 ; # Matches a word (mind yer pp and qq)
    
    regsub -all -nocase "$key=$qq" $tag {} tag
    regsub -all -nocase "$key *= *$pp" $tag {} tag
    append tag " value=\"$value\""
}




# sorts a list of pairs based on the first value in each pair

proc _ns_paircmp {pair1 pair2} {
    if {[lindex $pair1 0] > [lindex $pair2 0]} {
	return 1
    } elseif {[lindex $pair1 0] < [lindex $pair2 0]} {
	return -1
    } else {
	return 0
    }
}

# ns_htmlselect ?-multi? ?-sort? ?-labels labels? key values ?selecteddata?

proc ns_htmlselect args {

    set multi 0
    set sort 0
    set labels {}
    while {[string index [lindex $args 0] 0] == "-"} {
	if {[lindex $args 0] == "-multi"} {
	    set multi 1
	    set args [lreplace $args 0 0]
	}
	if {[lindex $args 0] == "-sort"} {
	    set sort 1
	    set args [lreplace $args 0 0]
	}
	if {[lindex $args 0] == "-labels"} {
	    set labels [lindex $args 1]
	    set args [lreplace $args 0 1]
	}
    }
    
    set key [lindex $args 0]
    set values [lindex $args 1]
    
    if {[llength $args] == 3} {
	set selecteddata [lindex $args 2]
    } else {
	set selecteddata ""
    }
    
    set select "<SELECT NAME=$key"
    if {$multi == 1} {
	set size [llength $values]
	if {$size > 5} {
	    set size 5
	}
	append select " MULTIPLE SIZE=$size"
    } else {
	if {[llength $values] > 25} {
	    append select " SIZE=5"
	}
    }
    append select ">\n"
    set len [llength $values]
    set lvpairs {}
    for {set i 0} {$i < $len} {incr i} {
	if [string match "" $labels] {
	    set label [lindex $values $i]
	} else {
	    set label [lindex $labels $i]
	}
	regsub -all "\"" $label "" label
	lappend lvpairs [list  $label [lindex $values $i]]
    }
    if $sort {
	set lvpairs [lsort -command _ns_paircmp -increasing $lvpairs]
    }
    foreach lvpair $lvpairs {
	append select "<OPTION VALUE=\"[lindex $lvpair 1]\""
	if {[lsearch $selecteddata [lindex $lvpair 1]] >= 0} {
	    append select " SELECTED"
	}
	append select ">[lindex $lvpair 0]\n"
    }
    append select "</SELECT>"

    return $select
}

proc ns_setexpires args {
    # skip over the optional connId parameter: just use the last arg
    set secondsarg [expr [llength $args] - 1]

    ns_set update [ns_conn outputheaders] Expires \
	    [ns_httptime [expr [lindex $args $secondsarg] + [ns_time]]]
}

proc ns_browsermatch args {
    # skip over the optional connId parameter: just use the last arg
    set globarg [expr [llength $args] - 1]

    return [string match [lindex $args $globarg]  \
	    [ns_set iget [ns_conn headers] user-agent]]
}

proc ns_set_precision {precision} {
    global tcl_precision
    set tcl_precision $precision
}

proc ns_updateheader {key value} {
    ns_set update [ns_conn outputheaders] $key $value
}

ns_share NS
set NS(months) [list January February March April May June \
	July August September October November December]

proc ns_localsqltimestamp {} {
    set time [ns_localtime]

    return [format "%04d-%02d-%02d %02d:%02d:%02d" \
	    [expr [ns_parsetime year $time] + 1900] \
	    [expr [ns_parsetime mon $time] + 1] \
	    [ns_parsetime mday $time] \
	    [ns_parsetime hour $time] \
	    [ns_parsetime min $time] \
	    [ns_parsetime sec $time]]
}

proc ns_parsesqldate {opt sqldate} {
    ns_share NS
    scan $sqldate "%04d-%02d-%02d" year month day

    switch $opt {
	month {return [lindex $NS(months) [expr $month - 1]]}
	day {return $day}
	year {return $year}
	default {error "Unknown option \"$opt\": should be year, month or day"}
    }
}
    
proc ns_parsesqltime {opt sqltime} {

    if {[scan $sqltime "%02d:%02d:%02d" hours minutes seconds] == 2} {
	set seconds 0
    }

    switch $opt {
	time {
	    if {$hours == 0} {
		set hours 12
	    } elseif {$hours > 12} {
		set hours [incr hours -12]
	    }
	    if {$seconds == 0} {
		return [format "%d:%02d" $hours $minutes]
	    } else {
		return [format "%d:%02d:%02d" $hours $minutes $seconds]
	    }
	}
	ampm {
	    if {$hours < 12} {
		return AM
	    } else {
		return PM
	    }
	}

	default {error "Unknown command \"$opt\": should be time or ampm"}
    }
}

proc ns_parsesqltimestamp {opt sqltimestamp} {

    switch $opt {
	month -
	day -
	year {return [ns_parsesqldate $opt [lindex [split $sqltimestamp " "] 0]]}
	time -
	ampm {return [ns_parsesqltime $opt [lindex [split $sqltimestamp " "] 1]]}
	default {error "Unknown command \"$opt\": should be month, day, year, time or ampm"}
    }
}

proc ns_buildsqltime {time ampm} {

    if {[string match "" $time] && [string match "" $ampm]} {
	return ""
    }

    if {[string match "" $time] || [string match "" $ampm]} {
	error "Invalid time: $time $ampm"
    }
    set seconds 0
    set num [scan $time "%d:%d:%d" hours minutes seconds]

    if {$num < 2 || $num > 3 \
	    || $hours < 1 || $hours > 12 \
	    || $minutes < 0 || $minutes > 59 \
	    || $seconds < 0 || $seconds > 61} {
	error "Invalid time: $time $ampm"
    }

    if {$ampm == "AM"} {
	if {$hours == 12} {
	    set hours 0
	}
    } elseif {$ampm == "PM"} {
	if {$hours != 12} {
	    incr hours 12
	}
    } else {
	error "Invalid time: $time $ampm"
    }

    return [format  "%02d:%02d:%02d" $hours $minutes $seconds]
}

proc ns_buildsqldate {month day year} {
    ns_share NS

    if {[string match "" $month] \
	    && [string match "" $day] \
	    && [string match "" $year]} {
	return ""
    }

    if {![ns_issmallint $month]} {
	set month [expr [lsearch $NS(months) $month] + 1]
    }

    if {[string match "" $month] \
	    || [string match "" $day] \
	    || [string match "" $year] \
	    || $month < 1 || $month > 12 \
	    || $day < 1 || $day > 31 \
	    || $year < 1\
            || ($month == 2 && $day > 29)\
            || (($year % 4) != 0 && $month == 2 && $day > 28) \
            || ($month == 4 && $day > 30)\
            || ($month == 6 && $day > 30)\
            || ($month == 9 && $day > 30)\
            || ($month == 11 && $day > 30) } {
	error "Invalid date: $month $day $year"
    }

    return [format "%04d-%02d-%02d" $year $month $day]
}

proc ns_buildsqltimestamp {month day year time ampm} {
    set date [ns_buildsqldate $month $day $year]
    set time [ns_buildsqltime $time $ampm]

    if {[string match "" $date] || [string match "" $time]} {
	return ""
    }

    return "$date $time"
}

# ns_localtime returns a time as a list of elements, and ns_parsetime
# returns one of those elements

proc ns_parsetime {option time} {
    set parts {sec min hour mday mon year wday yday isdst}
    set pos [lsearch $parts $option]
    if {$pos == -1} {
	error "Incorrect option to ns_parsetime: \"$option\" Should be\
               one of \"$parts\""
    }
    return [lindex $time $pos]
}

# ns_findset returns a set with a given name from a list.

proc ns_findset {sets name} {
    foreach set $sets {
	if {[ns_set name $set] == $name} {
	    return $set
	}
    }
    return ""
}

# getformdata - make sure an HTML FORM was sent with the request.
proc getformdata {conn formVar} {
	upvar $formVar form
	set form [ns_conn form $conn]
	if [string match "" $form] {
		ns_returnbadrequest $conn "Missing HTML FORM data"
		return 0
	}
	return 1
}

proc ns_paren {val} {
    if {$val != ""} {
	return "($val)"
    } else {
	return ""
    }
}

proc Paren {val} {
    return [ns_paren $val]
}

proc issmallint {value} {
    return [ns_issmallint $value]
}

proc ns_issmallint {value} {
    return [expr [regexp {^[0-9]+$} $value] && [string length $value] <= 6]
}

proc _ns_updatebutton {db table var} {
    upvar $var updatebutton

    if ![info exists updatebutton] {
	set updatebutton ""
    }
    if [string match "" $updatebutton] {
	set updatebutton [ns_table value $db $table update_button_label]
    }
    if [string match "" $updatebutton] {
	set updatebutton "Update Record"
    }
}

proc ns_findrowbyid {db table rowidset} {

    set sql "select * from [ns_dbquotename $table] where"
    for {set i 0} {$i < [ns_set size $rowidset]} {incr i} {
	if {$i != 0} {
	    append sql " and"
	}
	set column [ns_urldecode [ns_set key $rowidset $i]]
	set value [ns_set value $rowidset $i]
	set type [ns_column type $db $table $column]
	append sql " [ns_dbquotename $column] = [ns_dbquotevalue $value $type]"
    }
    if [catch {
	set row [ns_db 1row $db $sql]
    } errMsg] {
	ns_db setexception $db NSINT "Could not find row"
	error $errMsg
    }
    return $row
}

proc ns_sourceproc {conn ignored} {
	set script [ns_url2file [ns_conn url $conn]]
	if ![file exists $script] {
		ns_returnnotfound $conn
	} else {
		source $script
	}
}

proc ns_putscript {conn ignored} {
	ns_returnbadrequest $conn "Cannot PUT a script file"
}

# open a file with exclusive rights.  This call can fail (if you
# try to open-create-exclusive and the file already exists).  If this
# happens, "" is returned, in which case you need to generate a new
# name and try again
proc ns_openexcl {file} {

    if [catch { set fp [open $file {RDWR CREAT EXCL} ] } err] {

	global errorCode

	if { [lindex $errorCode 1] != "EEXIST"} {
	    return -code error $err
	}

	return ""
    }

    return $fp

}

proc _http_read {timeout sock length} {

    return [_ns_http_read $timeout $sock $length]

} ;# _http_read



# tcl page support

set tcl_pages_enabled [ns_config -bool ns/server/[ns_info server] EnableTclPages]

if {$tcl_pages_enabled == "1"} {
    ns_register_proc GET /*.tcl ns_sourceproc
    ns_register_proc POST /*.tcl ns_sourceproc
    ns_register_proc HEAD /*.tcl ns_sourceproc
    ns_register_proc PUT /*.tcl ns_putscript
}

proc ns_sourceproc {conn ignored} {
	set script [ns_url2file [ns_conn url $conn]]
	if ![file exists $script] {
		ns_returnnotfound $conn
	} else {
		source $script
	}
}

proc ns_putscript {conn ignored} {
	ns_returnbadrequest $conn "Cannot PUT a script file"
}

proc _ns_dateentrywidget {column} {
    ns_share NS

    set output "<SELECT name=ColValue.[ns_urlencode $column].month>\n"
    for {set i 0} {$i < 12} {incr i} {
	append output "<OPTION> [lindex $NS(months) $i]\n"
    }

    append output \
"</SELECT>&nbsp;<INPUT NAME=ColValue.[ns_urlencode $column].day\
TYPE=text SIZE=3 MAXLENGTH=2>&nbsp;<INPUT NAME=ColValue.[ns_urlencode $column].year\
TYPE=text SIZE=5 MAXLENGTH=4>"

    return [ns_dbformvalueput $output $column date [lindex [split [ns_localsqltimestamp] " "] 0]]
}

proc _ns_timeentrywidget {column} {
    
    set output "<INPUT NAME=ColValue.[ns_urlencode $column].time TYPE=text SIZE=9>&nbsp;<SELECT NAME=ColValue.[ns_urlencode $column].ampm>
<OPTION> AM
<OPTION> PM
</SELECT>"

    return [ns_dbformvalueput $output $column time [lindex [split [ns_localsqltimestamp] " "] 1]]
}



