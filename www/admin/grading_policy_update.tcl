# Set the form variable course_id, text, which_to_grade
set_the_usual_form_variables

set person_id [vu_verify_person]

set db [ns_db gethandle]

if { ![vu_course_responsible $db $course_id $person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

if { $which_to_grade == "" } { 
    set which_to_grade NULL
}

set delete_sql "delete from vu_problemsets_grade
                where course_id = $course_id"
set insert_sql "insert into vu_problemsets_grade (course_id, text, which_to_grade)
                values ($course_id, '$QQtext', $which_to_grade)"
               
ns_db dml $db "begin transaction"
ns_db dml $db $delete_sql
if { ($which_to_grade != "NULL") || ($text != "") } {
    ns_db dml $db $insert_sql
}
ns_db dml $db "end transaction"

ns_returnredirect "grading_policy_form.tcl?course_id=$course_id"