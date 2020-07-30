
#set the form variables problemset_id, course_id
set_the_usual_form_variables

set auth_user [vu_verify_person]

set db [ns_db gethandle]

# check that the delete is done by an authorised user
if { ![vu_course_responsible $db $course_id $auth_user] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

set delete_sql "delete from vu_problemset where problemset_id = $problemset_id"

# execute delete statement
if [ catch { ns_db dml $db $delete_sql } errmsg ] {
    ns_return 200 text/html "Before you can remove a problem set you must remove all its associated problems!"
    return
}

ns_returnredirect "problemsets.tcl?course_id=$course_id"

