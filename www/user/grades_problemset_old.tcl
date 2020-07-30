# set the form variable `course_id', 'problemset_id'
set_form_variables 

set db [ns_db gethandle]

set query "select vu_person.person_id, name, email
           from vu_person, vu_student
           where vu_person.person_id = vu_student.person_id     
           and vu_student.course_id = $course_id"

set selection [ns_db select $db $query]

set body "<table bgcolor=lightgreen cellpadding=5><tr><th>Name<th>&nbsp;"

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append body "<tr><td align=left>[mailto $email $name]
                     <td align=center><a href=\"grades_problemset_student.tcl?problemset_id=$problemset_id&course_id=$course_id&person_id=$person_id\">grade</a>"
}
append body </table>

set query "select problemset_name from vu_problemset where problemset_id = $problemset_id"
set selection [ns_db 1row $db $query]
set_variables_after_query

vu_returnpage_header "Problem set $problemset_name" $db $course_id $body
