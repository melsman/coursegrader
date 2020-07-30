# --------------------------------------------------------------------------------
# Add a person to the database, if not already registered
# --------------------------------------------------------------------------------

proc vu_person_add { email cont } {
    vu_returnpage "Email unknown" "No person is registered with the email address `$email'. <p>
                               You must provide a full name for the person.
                               <form action=person_add.tcl>
                               <input type=hidden name=email value=\"$email\">
                               <input type=hidden name=cont value=\"$cont\">
                               <table><th align=left>Full name<td>
                                <input type=text size=30 name=name>
                               </table></form>"
}


# --------------------------------------------------------------------------------
# Generic function to obtain a mailtag from a person_id
# --------------------------------------------------------------------------------
proc vu_mailtag { db person_id } {
    set selection [ns_db 1row $db "select email, name from vu_person where person_id = $person_id"]
    set_variables_after_query
    return [mailto $email $name]
}

# --------------------------------------------------------------------------------
# Functions to pretty-print ranges
# --------------------------------------------------------------------------------

proc vu_left_range { i } {
    set fi [expr floor($i)]
    if { $i == $fi } {
	return "\[ [expr int($i)]"
    } elseif { ($fi + 0.5) == $i } {
	return "\] [expr int($fi)]"
    } else {
	return "ERROR"
    }
}

proc vu_right_range { i } {
    set ci [expr ceil($i)]
    if { $i == $ci } {
	return "[expr int($i)] \]"
    } elseif { ($i + 0.5) == $ci } {
	return "[expr int($ci)] \["
    } else {
	return "ERROR"
    }
}

proc vu_range {left right} {
    return "[vu_left_range $left] - [vu_right_range $right]"
}


#----------------------------------------------------
# Utility procedure to add a new person to the database 
# and associate the person to a course as a student.
# Don't fail if the person is already in the database!
# Use this procedure with care!
# ---------------------------------------------------
proc vu_new_student { db name email course_id } {
    set sql "insert into vu_person (person_id, email, name, password)
             values (vu_person_id_sequence.nextval, '$email', '$name', '[new_password]')"
    catch { ns_db dml $db $sql } errmsg
    set person_id [database_to_tcl_string $db "select person_id from vu_person where email='$email'"]
    set sql "insert into vu_student (person_id, course_id)
             values ($person_id, $course_id)"
    catch { ns_db dml $db $sql } errmsg
    return
}

proc vu_new_students { db l course_id } {
    foreach pair $l {
	set name [lindex $pair 0]
	set email [lindex $pair 1]
	vu_new_student $db $name $email $course_id
    }
    return
}

#-------------------------------------------------------
# Procedure to report the grading item for a 
# person/problemset/course
#-------------------------------------------------------

# if the turn-in service is enabled and the student has not turned in the item
# show ``Not Turned-In'', else if the student has turned it in
# show ``Not Graded'' else show ``N/A''

proc vu_report_item { person_id ps_id course_id score flexible turn_in_service turned_in } {
    if { $score != "" } {
#	if { $turn_in_service == "t" && ! $turned_in } {
#	    set text "$score (Not Turned-In)"
#	} else {
	    set text $score
#	}
    } elseif { $turn_in_service == "t" } {
	if { $turned_in } {
	    set text "Not Graded"
	} else {
	    set text "Not Turned-In"
	}
    } else {
# change to accomodate request by Fritz Henglein
#	set text "N/A"
	set text "&nbsp;&nbsp;&nbsp;"
    }
    if { $flexible } {
	set text "<font color=red size=-1>$text</font>"
    } else {
	set text "<font size=-1>$text</font>"
    }
    return "<a href=\"grades_problemset_student.tcl?problemset_id=$ps_id&course_id=$course_id&person_id=$person_id\">$text</a>"
}	



#-------------------------------------------------------
# Procedure to report the grading policy for a course
#-------------------------------------------------------

proc vu_report_grading_table { db course_id } {
    set res ""
    set query "select first, last, grade 
               from vu_grade_range
               where course_id = $course_id
               order by first"
    set selection [ns_db select $db $query]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	if { $last == $first } {
	    append res "The grade $grade is given for the total score $last. "
	} else {
	    append res "The grade $grade is given for total scores in the range [vu_range $first $last]. "
	}
    }
    return $res
}


proc vu_report_grading_groups { db course_id } {
    set n [database_to_tcl_string $db "select count(*) 
                                       from vu_grading_group 
                                       where vu_grading_group.course_id = $course_id"]
    if { $n == 1 } {	
	set text "There is one grading group. "
    } else {
	set text "There are $n grading groups. "
    }
    
    set query "select name, weight, items_that_counts
               from vu_grading_group 
               where vu_grading_group.course_id = $course_id"
    set selection [ns_db select $db $query]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	if { $items_that_counts == 0 } {
	    set counts "no grading items counts"
	} elseif { $items_that_counts == 1 } {
	    set counts "the grading item with the highest score counts"
	} elseif { $items_that_counts == "" } {
            set counts "all grading items counts"
        } else {
	    set counts "the grading items with the $items_that_counts highest scores count"
	}
	append text "The grading group `$name', in which $counts, has a grading weight of $weight\%. "
	
    }
    return $text
}

proc vu_report_grading_policy { db course_id } {
    set query "select text
               from vu_problemsets_grade
               where course_id = $course_id"
    set selection [ns_db 0or1row $db $query]
    if { $selection != "" } {
	set_variables_after_query
	set text "<li>$text"
    } else {
	set text ""
    }

    set grading_table [vu_report_grading_table $db $course_id]
    if { $grading_table != "" } {
	set $grading_table "<li> $grading_table"
    }

    return "<h3>Grading Policy</h3><ul>
	<li> For each person a grade is shown only when scores are available for all grading items.
	$grading_table
        <li> [vu_report_grading_groups $db $course_id]
	$text
	</ul>"
}   
 
#------------------------------------------------------------
# Procedure to show comments provided by the student when
# turning in a problem set
# -----------------------------------------------------------

proc vu_show_text { text } {
    set text [ns_quotehtml $text]
    return "<textarea rows=30 cols=80 readonly=readonly>$text</textarea>"
}

proc vu_student_comments { db course_id person_id problemset_id } {

    set query "select text, insdate, deleted_date, name, email, pg_num
               from vu_turn_in, vu_person
               where vu_turn_in.person_id = $person_id
                 and vu_person.person_id = $person_id
                 and course_id = $course_id
                 and problemset_id = $problemset_id
               order by insdate, pg_num"              
    
    set selection [ns_db select $db $query]

    set res [list]
    
    set acctext [list]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
        if { $pg_num == 0 } {
	    if { [llength $acctext] != 0 } { # finish block
		lappend acctext "</textarea></td></tr></table><p>"
		lappend res [join $acctext]
	    }
	    # start accumulation
	    if { $deleted_date == "" } {
		set deleted ""
	    } else {
		set deleted "DELETED by course responsible on $deleted_date!!"
	    }
	    set text [ns_quotehtml $text]		
	    # reset accumulation
	    set acctext [list]
	    lappend acctext "<table cellpadding=5 cellspacing=0 width=95% align=center border=0 bgcolor=\"#eeeeee\"> 
   	                     <tr bgcolor=silver> <th align=left>$deleted Text entered on $insdate by [mailto $email $name] 
                             <tr><td><textarea rows=30 cols=80 readonly=readonly>$text"
	} else {   
	    # append page to acctext
	    set text [ns_quotehtml $text]
	    lappend acctext $text
	}
    }
    lappend acctext "</textarea></td></tr></table><p>"
    lappend res [join $acctext]
    return [join $res]
}
    

# --------------------------------------
# Procedure to toggle a row-color for
# a table; given no argument the procedure
# returns a new color
# --------------------------------------

proc vu_toggle_row_color {{color "\"#dddddd\""}} {
    if { $color == "\"#dddddd\"" } {
	return "\"#eeeeee\""
    } else {
	return "\"#dddddd\""
    }
}

# -----------------------------------------------------------
# vu_verify_person; return person_id if happy, 0 otherwise
# -----------------------------------------------------------

proc vu_verify_person {} {

    # ns_log Notice "vu_verify_person: entering vu_verify_person"

    # get http-headers
    set headers [ns_conn headers]

    # extract Cookie from headers
    set cookie [ns_set get $headers Cookie]

    # extract vu_person_id and vu_password from Cookie

    # ns_log Notice "cookie = $cookie"

    if { [regexp {vu_person_id=([^;]+)} $cookie {} person_id] } {
	# ns_log Notice "got person_id = $person_id from cookie"
        if { [regexp {vu_password=([^;]+)} $cookie {} urlencoded_password] } {

            # got person_id and password, let's check it 
            # we urlencode/decode passwords so that users are free to
            # put in semicolons and other special characters that might
            # mess up a cookie header

	    # ns_log Notice "vu_verify_person: got password and person_id from cookie"

            set password_from_cookie [ns_urldecode $urlencoded_password]

	    # ns_log Notice "got password = $password_from_cookie from cookie"

            # we need to talk to Oracle
            set db [ns_db gethandle]
	    set query "select password from vu_person where person_id = '$person_id'"
	    set selection [ns_db 0or1row $db $query]
	    if { $selection == "" } {
		ns_db releasehandle $db
                # ns_log Notice "vu_verify_person: we failed to get a password from the database for user with person_id $person_id"
		return 0
	    }
	    set_variables_after_query

            # we explicitly release the database connection in case
            # another filter or the thread itself needs to use one
            # from this pool
            ns_db releasehandle $db

            if { [string compare $password $password_from_cookie] == 0 } {
		# passwords match
                # ns_log Notice "vu_verify_person: passwords match"
		return $person_id
	    } else {
                # ns_log Notice "vu_verify_person: passwords don't match"
                return 0
            }
        } else {
           # ns_log Notice "vu_verify_person: no password in cookie"
           return 0
        }
    } 
    
    # ns_log Notice "vu_verify_person: no person_id in cookie!"
    return 0
}


# ---------------------------------------------------
# vu_verify_person_filter; procedure to filter if a
# person is authenticated to request a page
# ---------------------------------------------------

proc vu_verify_person_filter {args why} {
    set person_id [vu_verify_person] 
    if { $person_id == 0 } {
	# ns_log Notice "vu_verify_person_filter: person_id = 0 - now returning to index.tcl"
        ns_returnredirect "[vu_home_url]index.tcl"
        # returning "filter_return" causes AOLserver to abort
        # processing of this thread
        return filter_return
    } else {
	# ns_log Notice "vu_verify_person_filter: person_id = $person_id - filter_ok"
        # got a member_id and the password matched
        # returning "filter_ok" causes AOLserver to proceed
        return filter_ok
    }
}

#-------------------------------------------------------
# procedure to check that a person is indeed responsible for a course
# and is thus permitted to alter course properties
#-------------------------------------------------------
proc vu_course_responsible { db course_id person_id } {
    set selection [ns_db 0or1row $db "select responsible
                                      from vu_course where course_id = $course_id"]
    if { $selection == "" } {
	return 0
    } else {
	set_variables_after_query
	if { $person_id == $responsible } {
	    return 1
	} else {
	    return 0
	}
    }
}


#-------------------------------------------------------
# procedure to check that a person is indeed an assistant 
# for a course, and is thus permitted to do grading
#-------------------------------------------------------
proc vu_course_assistant { db course_id person_id } {
    set selection [ns_db 0or1row $db "select *
                                      from vu_course, vu_course_assistant
                                      where vu_course.course_id = $course_id
                                        and vu_course.course_id = vu_course_assistant.course_id
                                        and vu_course_assistant.person_id = $person_id"]
    if { $selection == "" } {
	return 0
    } else {
	return 1
    }
}

#-------------------------------------------------------
# procedure to check that a person is indeed a student
# of a course, and is thus permitted to see gradings
#-------------------------------------------------------
proc vu_course_student { db course_id person_id } {
    set selection [ns_db 0or1row $db "select * from vu_student
                                      where vu_student.course_id = $course_id
                                        and vu_student.person_id = $person_id"]
    if { $selection == "" } {
	return 0
    } else {
	return 1
    }
}

#-------------------------------------------------------
# procedure to check that a person is indeed a teacher 
# for a course (i.e., course responsible or assistant)
# and is thus permitted to do grading
#-------------------------------------------------------
proc vu_course_teacher { db course_id person_id } {
    expr [vu_course_assistant $db $course_id $person_id] || [vu_course_responsible $db $course_id $person_id]
}



# we tell AOLserver to run our cookie checker procedure before
# serving any request for a URL that starts with "/vu/user/" 
ns_register_filter preauth GET /vu/user/* vu_verify_person_filter
ns_register_filter preauth POST /vu/user/* vu_verify_person_filter
