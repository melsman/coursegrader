# Set the form variable 'course_id', 'weight', 'items_that_counts', 'grading_group', 'turn_in_service'
set_the_usual_form_variables

set person_id [vu_verify_person]

set db [ns_db gethandle]

if { ![vu_course_responsible $db $course_id $person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

set update_sql "update vu_grading_group 
                set weight=$weight,
                    items_that_counts=$items_that_counts,
                    turn_in_service='$turn_in_service'
                where course_id = $course_id 
                and name='$QQgrading_group'"

catch [ns_db dml $db $update_sql] errmsg

ns_returnredirect "grading_policy_form.tcl?course_id=$course_id"

