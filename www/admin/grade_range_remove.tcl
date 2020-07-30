# set the form variables course_id, first, last
set_form_variables

set person_id [vu_verify_person]

set db [ns_db gethandle]

if { ![vu_course_responsible $db $course_id $person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

if { (![regexp {^0|([1-9][0-9]*)$} $first]) || ($first > 100) || (![regexp {^0|([1-9][0-9]*)$} $last]) || ($last > 100) || ($last - $first < 0) } {
    ns_returnredirect "../auth_form.tcl"
    return
}

set remove_sql "delete from vu_grade_range 
                where course_id = $course_id
                  and first = $first
                  and last = $last"

ns_db dml $db $remove_sql

ns_returnredirect "grading_policy_form.tcl?course_id=$course_id"
