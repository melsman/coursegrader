# set the form variable `course_id', 'problemset_id', 'text'
set_the_usual_form_variables 

set person_id [vu_verify_person]

set db [ns_db gethandle]

# Check that the page is inspected by an authorised user
if { ![vu_course_student $db $course_id $person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

if { $text == "" } {
    ns_return 200 text/html "You must enter some text!"
    return
}

set insert_sql "insert into vu_turn_in (person_id, course_id, problemset_id, text, insdate, pg_num)
                values ($person_id, $course_id, $problemset_id, '$QQtext', sysdate, 0)"

ns_db dml $db $insert_sql

ns_returnredirect "view_problemsets_student.tcl?course_id=$course_id"
