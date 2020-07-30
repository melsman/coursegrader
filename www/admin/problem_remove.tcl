#set the form variables problem_id, problemset_id, problemset_name, course_id
set_the_usual_form_variables

set auth_user [vu_verify_person]

set db [ns_db gethandle]

# check that the delete is done by an authorised user
if { ![vu_course_responsible $db $course_id $auth_user] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

set delete_sql "delete from vu_problem where problem_id = $problem_id"

# execute delete statement

if { [catch { ns_db dml $db $delete_sql } errmsg] } {
    ns_return 200 text/html "You cannot delete a part of a grading item for which there are gradings in the database."
    return
}

ns_returnredirect "problemset_show.tcl?course_id=$course_id&problemset_id=$problemset_id&problemset_name=[ns_urlencode $problemset_name]"

