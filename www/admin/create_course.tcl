
# set the form variables semester, title
set_the_usual_form_variables

if { $title == "" } {
    ns_return 200 text/html "You must enter a course title!"
    return
}

if { ![regexp {^[A-Z][0-9][0-9][0-9][0-9]$} $semester] } {
    ns_return 200 text/html "You must enter a valid semester (e.g, F2007, E2007, S2007, ...)!"
    return
}

set person_id [vu_verify_person]

#-------------------------
# get name and email
#-------------------------
set db [ns_db gethandle]
set selection [ns_db 0or1row $db "select name, email from vu_person where person_id = $person_id"]
if { $selection == "" } {
    ns_returnredirect "../auth_form.tcl"
    return
}
set_variables_after_query

set course_id [database_to_tcl_string $db "select vu_course_id_sequence.nextval from dual"]

set insert_sql "insert into vu_course (course_id, course_name, semester, responsible)
                values ($course_id, '$QQtitle', '$QQsemester', $person_id)"

ns_db dml $db $insert_sql

ns_returnredirect "course_adm.tcl?course_id=$course_id"
