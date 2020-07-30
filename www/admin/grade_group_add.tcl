# Set the form variable 'course_id', 'QQtext', 'weight'
set_the_usual_form_variables

if { ![regexp {^[ A-Za-z0-9\-_]+$} $QQtext ] } {
    ns_return 200 text/html "You must enter a valid name for the grading group using characters a-z, A-Z, space, _, and -. 
                             Use the back button on your browser to go back."
    return
}    

set person_id [vu_verify_person]

set db [ns_db gethandle]

if { ![vu_course_responsible $db $course_id $person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

set grading_group_id [database_to_tcl_string $db "select vu_grading_group_id.nextval from dual"]

set insert_sql "insert into vu_grading_group (grading_group_id, course_id, text, weight) 
                values ($grading_group_id, $course_id, '$QQtext', $weight)"

if { [catch { [ns_db dml $db $insert_sql] } errmsg] == 0 } { 
    ns_returnredirect "grading_policy_form2.tcl?course_id=$course_id"
    return
} else {
    ns_returnredirect "grade_group_edit.tcl?course_id=$course_id&grading_group_id=$grading_group_id"
    return
}