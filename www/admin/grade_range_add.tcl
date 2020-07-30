# set the form variables course_id, first, last, grade, left, right
set_the_usual_form_variables

set person_id [vu_verify_person]

set db [ns_db gethandle]

if { ![vu_course_responsible $db $course_id $person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

if { $grade == "" } {
    ns_return 200 text/html "You must enter a grade"
    return
}

if { (($left != "include") && ($left != "exclude")) ||
     (($right != "include") && ($right != "exclude"))  } {
    ns_returnredirect "grading_policy_form.tcl?course_id=$course_id"
    return
}

if { (![regexp {^0|([1-9][0-9]*)$} $first]) || (![regexp {^0|([1-9][0-9]*)$} $last]) } {
    ns_return 200 text/html "You must enter a range between 0 and 100"
    return
}

if { $left == "exclude" } {
    set first [expr $first + 0.5]
}

if { $right == "exclude" } {
    set last [expr $last - 0.5]
}

if { ($first > 100) || ($last > 100) || ($last - $first < 0) } {
    ns_return 200 text/html "The range you entered is invalid. You must enter a range between 0 and 100"
    return
}

set select_sql "select count(*) from
                vu_grade_range
                where course_id = $course_id
                  and ((last >= $first and last <= $last) or
                      (first >= $first and first <= $last) or
                      ($last >= first and $last <= last) or
                      ($first >= first and $first <= last))"
                     
set count [database_to_tcl_string $db $select_sql]

if { $count > 0 } {
    ns_return 200 text/html "It seems that the range you're defining overlaps with existing ranges.
                 You must remove conflicting ranges before you can add this one!"
    return
}    


set insert_sql "insert into vu_grade_range (course_id, first, last, grade)
                values ($course_id, $first, $last, '$QQgrade')"

if [ catch {ns_db dml $db $insert_sql} errmsg ] {
    ns_return 200 text/html "It seems that what you are definining is not a 
                             range between 0 and 100. Back up and try again!"
    return
}

ns_returnredirect "grading_policy_form.tcl?course_id=$course_id"
