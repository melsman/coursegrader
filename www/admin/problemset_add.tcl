
#set the form variables 'course_id', 'problemset_name', 'grading_group?'
set_the_usual_form_variables

if { ![regexp {^[ A-Za-z0-9\-_]+$} $problemset_name ] } {
    ns_return 200 text/html "You must enter a valid name for the problem 
         set using characters a-z, A-Z, space, _, and -. Use the back 
         button on your browser to go back."
    return
}

if { $QQgrading_group == "" } {
    set QQgrading_group $QQproblemset_name
} else {
    if { ![regexp {^[ A-Za-z0-9\-_]+$} $grading_group ] } {
	ns_return 200 text/html "You must enter a valid name for the problem 
            set using characters a-z, A-Z, space, _, and -. Use the back 
            button on your browser to go back."
	return
    }
}
    

set auth_user [vu_verify_person]

set db [ns_db gethandle]

# check that the insert is done by an authorised user
if { ![vu_course_responsible $db $course_id $auth_user] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

set insert_sql "insert into vu_problemset (problemset_id, course_id, problemset_name, grading_group)
                values (vu_problemset_id_sequence.nextval, $course_id, '$QQproblemset_name', '$QQgrading_group')"

catch { [ns_db dml $db $insert_sql] } errmsg 

set insert_sql "insert into vu_grading_group (name, course_id, weight, turn_in_service)
                values ('$QQgrading_group', $course_id, 0, 'f')"

catch { [ns_db dml $db $insert_sql] } errmsg 

ns_returnredirect "problemsets.tcl?course_id=$course_id"
