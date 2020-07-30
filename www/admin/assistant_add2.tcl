# set the form variables person_id, course_id
set_form_variables

set auth_user [vu_verify_person]

set db [ns_db gethandle]

# check that the insert is done by an authorised user
if { ![vu_course_responsible $db $course_id $auth_user] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

set insert_sql "insert into vu_course_assistant (person_id, course_id)
                values ($person_id, $course_id)"

# could fail in case of reinserts, I suspect...
catch { [ns_db dml $db $insert_sql] } errmsg

ns_returnredirect "assistants.tcl?course_id=$course_id"
