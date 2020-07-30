#set the variables course_id, problemset_id, person_id
set_the_usual_form_variables

set auth_user [vu_verify_person]

set db [ns_db gethandle]

# check that the inserts are done by an authorised user
if { ![vu_course_responsible $db $course_id $auth_user] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

set query "select problem_id 
           from vu_problem
           where problemset_id = $problemset_id"

set selection [ns_db select $db $query]

set l [list]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    lappend l $problem_id
    ns_log Notice "yes"
}

foreach pid $l {
    ns_log Notice "so far"
    set insert_sql "insert into vu_problem_solution (problem_id, person_id, text, grade, 
                                                     rigid, last_changed_by, last_changed_date)
                    values ($pid, $person_id, 'Not turned in', 
                            0, 't', $auth_user, sysdate)"
    catch { ns_db dml $db $insert_sql } res
}

ns_log Notice "got here"

ns_returnredirect "grades_problemset_student.tcl?problemset_id=$problemset_id&course_id=$course_id&person_id=$person_id"
