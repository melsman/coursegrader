# set the form variable `course_id'
set_form_variables 

set person_id [vu_verify_person]

set db [ns_db gethandle]

# Check that the page is inspected by an authorised user
if { ![vu_course_student $db $course_id $person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

set grading_visibility [database_to_tcl_string $db "select grading_visibility from vu_course 
                                                    where course_id = $course_id"]

set responsible [database_to_tcl_string $db "select responsible from vu_course 
                                             where course_id = $course_id"]

if { [string compare $grading_visibility "responsible"] == 0 } {
    set body "Only grading items that are graded and verified
    by the course responsible (i.e., [vu_mailtag $db $responsible]) appear with a 
    score in the table. <p>"
} else {
    set body "Only grading items that are graded by a teaching assistant or the 
    the course responsible (i.e., [vu_mailtag $db $responsible]) appear with a 
    score in the table. <p>"
}    

# get a second database handle
set subdb [ns_db gethandle subquery]

set query "select problemset_id, problemset_name, grading_group, weight, turn_in_service
           from vu_problemset, vu_grading_group
           where vu_problemset.course_id = $course_id
            and vu_grading_group.course_id = $course_id
            and vu_grading_group.name = grading_group 
           order by grading_group, problemset_name"

set selection [ns_db select $db $query]

append body "<table bgcolor=silver cellspacing=0 border=0 cellpadding=5 align=center width=90%><th>Grading Group<th>Grading item<th>Status"

set color [vu_toggle_row_color]
set prev_group_text ""

if { [string compare $grading_visibility "responsible"] == 0 } {
    set rigid_clause "and vu_problem_solution.rigid = 't'"
} else {
    set rigid_clause ""
}

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    # get the number of problems in a given problem set
    set problems_in_set [database_to_tcl_string $subdb "select count(*) from vu_problem
                                                        where vu_problem.problemset_id = $problemset_id"]

    # perform subquery, but first save the selection variable
    set selection_tmp $selection

    set subquery "select sum(vu_problem_solution.grade) as score,
                      count(*) as problems_graded
                  from vu_problem_solution, vu_problem
                  where vu_problem_solution.person_id = $person_id
                    and vu_problem.problem_id = vu_problem_solution.problem_id
                    and vu_problem.problemset_id = $problemset_id
                    $rigid_clause"

    set selection [ns_db 1row $subdb $subquery]

    set_variables_after_query

    if { $problems_in_set != $problems_graded } {
	if { $turn_in_service == "t" } {
	    set subquery "select count(*)
	                  from vu_turn_in
	                  where deleted_date is NULL
                            and course_id = $course_id
                            and person_id = $person_id
                            and problemset_id = $problemset_id"
            set n_rows [database_to_tcl_string $subdb $subquery]
            if { $n_rows == 0 } {
		set status "Not Turned In ([vu_link "user/turn_in.tcl?problemset_id=$problemset_id&course_id=$course_id" "turn-in"])"
	    } else {
		set status "[vu_link "user/view_problemset_student.tcl?problemset_id=$problemset_id&course_id=$course_id" "Not Graded"]
                            ([vu_link "user/turn_in.tcl?problemset_id=$problemset_id&course_id=$course_id" "turn-in-again"])"
	    }
	} else {
	    set status "<font color=red>N/A</font>"
	}
    } else {
	set status "<a href=\"view_problemset_student.tcl?problemset_id=$problemset_id&course_id=$course_id\">Score: $score</a>"
        if { $turn_in_service == "t" } {
           set status "$status
                       ([vu_link "user/turn_in.tcl?problemset_id=$problemset_id&course_id=$course_id" "turn-in-again"])"
        }
    }

    # restore the selection variable after the subquery
    set selection $selection_tmp

    set group_text "$grading_group ($weight \%)"

    if { $prev_group_text == $group_text } {
	set group_text "&nbsp;"
    } else {
	set prev_group_text $group_text
    }
    append body "<tr bgcolor=$color><td width=34% align=center> $group_text
                     <td width=33% align=center> $problemset_name
                 <td width=33% align=center> $status"
    set color [vu_toggle_row_color $color]
}

append body "</table>"



# ------------------------------------
# Compute the total score
# ------------------------------------

if { [string compare $grading_visibility "responsible"] == 0 } {
    set total_function "vu_course_total_rigid"
} else {
    set total_function "vu_course_total"
}

set total_score [database_to_tcl_string $db "select $total_function ($course_id, $person_id) 
                                             from dual"]

if { $total_score == "" } {
    set total_score "-"
}

# ---------------------------------------------------------------------
# See if there are any non-rigid problem solutions - if so, we don't
# return a grade!
# ---------------------------------------------------------------------

if { [string compare $grading_visibility "responsible"] == 0 } {
    set flexible_solutions [database_to_tcl_string $db "
      select count(*)
      from vu_problem_solution, vu_problemset, vu_problem
      where rigid = 'f'
        and vu_problem_solution.person_id = $person_id
        and vu_problemset.problemset_id = vu_problem.problemset_id
        and vu_problemset.course_id = $course_id
        and vu_problem.problem_id = vu_problem_solution.problem_id"]
} else {
    set flexible_solutions 0
}

if { $flexible_solutions == 0 } {
    set grade [database_to_tcl_string $db "select vu_course_grade($course_id, $person_id) from dual"]
    if { $grade == "" } {
	set grade "-"
    }
} else {
    set grade "-"
}

set navbar [vu_navbar2 [vu_link index.tcl "Your Workspace"] "Student Status"]

set name [database_to_tcl_string $db "select name from vu_person where person_id = $person_id"]

# ------------------------------------
# Return a page
# ------------------------------------

vu_returnpage_header "Student status for $name" $db $course_id "

$body

<h3>Grading</h3>
  <table bgcolor=silver cellspacing=0 border=0 cellpadding=5 align=center width=90%>
  <tr><th>Grade
    <th>Total score
    <tr bgcolor=\"#eeeeee\"><td align=center>$grade<td align=center>$total_score
  </table> 
[vu_report_grading_policy $db $course_id]" $navbar
