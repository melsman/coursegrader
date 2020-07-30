
#set the form variables problemset_id, problem_name, maxpoint, problemset_name, course_id
set_the_usual_form_variables

if { (![regexp {^([1-9][0-9])|0*$} $maxpoint]) || ($maxpoint > 100) } {
    ns_return 200 text/html "You must enter maximum points (0-100) for this problem! 
                             Use the back button on your browser to go back."
    return
}

if { ![regexp {^[A-Za-z0-9\-_]+$} $problem_name ] } {
    ns_return 200 text/html "You must enter a valid name for the problem using characters a-z, A-Z, space, _, and -. 
                             Use the back button on your browser to go back."
    return
}    

set auth_user [vu_verify_person]

set db [ns_db gethandle]

# check that the insert is done by an authorised user
if { ![vu_course_responsible $db $course_id $auth_user] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

set insert_sql "insert into vu_problem (problem_id, problemset_id, problem_name, maxpoint)
                values (vu_problem_id_sequence.nextval, $problemset_id, '$QQproblem_name', $maxpoint)"

catch { [ns_db dml $db $insert_sql] } errmsg 

ns_returnredirect "problemset_show.tcl?course_id=$course_id&problemset_id=$problemset_id&problemset_name=[ns_urlencode $problemset_name]"