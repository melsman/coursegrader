# set the variables course_id, problemset_id, problem_id, maxpoint, person_id, rigid, text, grade
set_the_usual_form_variables

# check grade
if { ![regexp {^(0|([1-9][0-9]*))$} $grade] || $maxpoint < $grade } {
    ns_returnredirect "grades_problemset_student.tcl?problemset_id=$problemset_id&course_id=$course_id&person_id=$person_id"
    return
}

if { $text == "" } {
    ns_return 200 text/html "You must enter some text!"
    return
}

set auth_person_id [vu_verify_person]

set db [ns_db gethandle]

ns_db dml $db "begin transaction"

# check that the insert is done by an authorised user
if { ![vu_course_teacher $db $course_id $auth_person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

if { [vu_course_assistant $db $course_id $auth_person_id] } {
    # look in the database to see if the problem solution is rigid; if so, 
    # return an error to the assistant 
    set selection [ns_db 0or1row $db "select rigid from vu_problem_solution
                                      where problem_id = $problem_id 
                                        and person_id = $person_id"]
    if { $selection != "" } {
	set_variables_after_query
	if { $rigid == "t" } {
	    ns_return 200 text/html "The course responsible has deemed this grading to 
                                     be rigid, which means that assistants cannot alter
	                             the grading. Sorry..."
	    return
	}
    }
}


# possible transactions
set delete_sql "delete from vu_problem_solution
                where person_id = $person_id
                  and problem_id = $problem_id"

set insert_sql "insert into vu_problem_solution (problem_id, person_id, text, grade, rigid, last_changed_by, last_changed_date)
                values ($problem_id, $person_id, '$QQtext', $grade, '$rigid', $auth_person_id, sysdate)"

# look in the database for an entry
set query "select text as text_old, grade as grade_old 
           from vu_problem_solution
           where person_id = $person_id and problem_id = $problem_id"

set selection [ns_db 0or1row $db $query]

if { $selection == "" } {
    ns_db dml $db $insert_sql
} else {
    set_variables_after_query
    if { ($text_old == $text) && ($grade_old == $grade) } {
	set update_sql "update vu_problem_solution set rigid = '$rigid'
                        where person_id = $person_id and problem_id = $problem_id"
	ns_db dml $db $update_sql
    } else {
	ns_db dml $db $delete_sql
	ns_db dml $db $insert_sql
    }
}

ns_db dml $db "end transaction"

ns_returnredirect "grades_problemset_student.tcl?problemset_id=$problemset_id&course_id=$course_id&person_id=$person_id"
