# set the form variables person_id, course_id
set_form_variables

set auth_user [vu_verify_person]

set db [ns_db gethandle]

# check that the remove is done by the authorised user
if { ![vu_course_responsible $db $course_id $auth_user] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

set delete_sql "delete from vu_student 
                where person_id = $person_id
                  and course_id = $course_id"

# could fail, I suspect...
if [ catch { ns_db dml $db $delete_sql } errmsg ] {
    ns_return 200 text/html "Could not remove student from course!"
    return
}

# try to delete a person from the vu_person table, but 
# don't scream if it doesn't work
set delete_sql "delete from vu_person
                where person_id = $person_id"
catch { [ns_db dml $db $delete_sql] } errmsg

ns_returnredirect "students.tcl?course_id=$course_id"
