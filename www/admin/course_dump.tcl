# set the form variable course_id
set_form_variables

set person_id [vu_verify_person]

set db [ns_db gethandle]

if { ![vu_course_responsible $db $course_id $person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

set name [database_to_tcl_string $db "select name from vu_person where person_id = $person_id"]

set course_url [database_to_tcl_string $db "select course_url from vu_course where course_id = $course_id"]

if { $course_url == "" } {
    set course_url "http://"
}

set course_name [database_to_tcl_string $db "select course_name from vu_course where course_id = $course_id"]

set semester [database_to_tcl_string $db "select semester from vu_course where course_id = $course_id"]

set navbar "[vu_navbar2 [vu_link user/index.tcl "Your Workspace"] "Admin"]"

ReturnHeaders

ns_write [vu_page_header "Dump of Course Data for $course_name ($semester)" $db $course_id $navbar]

# number of seconds after 1970
set seconds [clock seconds]
# the date in a nice format
set now [clock format $seconds -format "%Y-%m-%d, %R"]

ns_write "
<table>
<tr align=left><th>Course responsible:</th><td>$name</td></tr>
<tr align=left><th>Course URL:</th><td>$course_url</td></tr>
<tr align=left><th>Printed:</th><td>$now</td></tr>
</table><hr>"

set query "select vu_person.person_id, name, email
           from vu_person, vu_student
           where vu_person.person_id = vu_student.person_id     
           and vu_student.course_id = $course_id
           order by name"

set selection [ns_db select $db $query]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    set stud_info($person_id) [list $name $email]
}

set query "select problemset_id, problemset_name, grading_group, weight
           from vu_problemset, vu_grading_group
           where vu_problemset.course_id = $course_id
             and vu_grading_group.name = grading_group
             and vu_grading_group.course_id = $course_id
           order by grading_group,problemset_name"

set selection [ns_db select $db $query]

set problemset_info [list]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    lappend problemset_info [list $problemset_id $problemset_name]
}

proc write_problemset { db person_id problemset_id } {
    
    set query "select problem_name, maxpoint, text, grade, vu_person.name as lcb_name, 
                      vu_person.email as lcb_email, last_changed_date 
               from vu_problem_solution, vu_problem, vu_person 
               where vu_person.person_id = vu_problem_solution.last_changed_by 
               and vu_problem_solution.person_id = $person_id
               and vu_problem_solution.problem_id = vu_problem.problem_id
               and vu_problem.problemset_id = $problemset_id
               order by problem_name"

    set selection [ns_db select $db $query]

    set total 0
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	incr total $grade
	ns_write "<table width=90% align=center><tr><td><b>$problem_name ($grade / $maxpoint)</b>
                                    - graded by [mailto $lcb_email $lcb_name] ($last_changed_date)</td></tr>
                         <tr><td><code>[ns_quotehtml $text]</code></td></tr>
                  </table>"
    }
    ns_write "<table width=90% align=center><tr><td><b>Total: $total</b></td></tr></table>"
}

foreach person_id [array names stud_info] {
    set l $stud_info($person_id)
    set name [lindex $l 0]
    ns_write "<h3>$name ([lindex $l 1])</h3>"
    foreach p $problemset_info {
	set problemset_id [lindex $p 0]
	set pname [lindex $p 1]
	ns_write "<h4>Grading of $pname for $name</h4>"
	write_problemset $db $person_id $problemset_id
    }
}

ns_write [vu_page_footer]
