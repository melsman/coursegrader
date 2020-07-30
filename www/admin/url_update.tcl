# set the form variables course_id, course_url, course_name, grading_visibility
set_the_usual_form_variables

set person_id [vu_verify_person]

set db [ns_db gethandle]

if { ![vu_course_responsible $db $course_id $person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

if { ![regexp {^http://[0-9a-zA-Z?=&/\-\.]+$} $course_url] } {
    ns_return 200 text/html "You must enter a valid url! Use your back-buttom on your browser..."
    return
}

if { ![regexp {^[,0-9a-zA-ZæøåÆØÅ/\-_\.'"()\[\] ]+$} $course_name] } {
    ns_return 200 text/html "You must enter a valid course name! Use your back-buttom on your browser..."
    return
}

if { ([string compare $grading_visibility "assistant"] != 0) && ([string compare $grading_visibility "responsible"] != 0) } {
    ns_return 200 text/html "Grading visibility is not assistant or responsible! Don't mess with the url..."
    return
}

set update_sql "update vu_course 
                set course_url = '$QQcourse_url',
                    grading_visibility = '$QQgrading_visibility',
                    course_name = '$QQcourse_name'
                where course_id = $course_id"

ns_db dml $db $update_sql

ns_returnredirect "course_adm.tcl?course_id=$course_id"