# set the form variable `course_id', 'problemset_id'

set_form_variables 

set db [ns_db gethandle]
set subdb [ns_db gethandle subquery]

set problems_in_set [database_to_tcl_string $db "
  select count(*) from vu_problem
  where vu_problem.problemset_id = $problemset_id"]

set turn_in_service [database_to_tcl_string $db "select turn_in_service from vu_grading_group, vu_problemset
                                                 where vu_grading_group.name = grading_group
                                                   and problemset_id = $problemset_id
                                                   and vu_grading_group.course_id = $course_id
                                                   and vu_problemset.course_id = $course_id"]

set query "select vu_person.person_id, name, email
           from vu_person, vu_student
           where vu_person.person_id = vu_student.person_id     
           and vu_student.course_id = $course_id
           order by name"

set selection [ns_db select $db $query]

set body "<table width=80% bgcolor=silver cellpadding=5 cellspacing=0 border=0 align=center><tr><th>Name<th>Status"

set color [vu_toggle_row_color]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    set selection_tmp $selection

    set subquery "select sum(vu_problem_solution.grade) as score,
                      count(*) as problems_graded
                  from vu_problem_solution, vu_problem
                  where vu_problem_solution.person_id = $person_id
                    and vu_problem.problem_id = vu_problem_solution.problem_id
                    and vu_problem.problemset_id = $problemset_id"

    set selection [ns_db 1row $subdb $subquery]
    set_variables_after_query

    if { $score != "" } {
	set score "Score: $score"
    }

    # See whether some of the gradings are flexible, which 
    # should cause the score to come out red!
    set subquery "select count(*) as flexible
                  from vu_problem_solution, vu_problem
                  where vu_problem_solution.person_id = $person_id
                    and vu_problem.problem_id = vu_problem_solution.problem_id
                    and vu_problem.problemset_id = $problemset_id
                    and vu_problem_solution.rigid = 'f'"
    set selection [ns_db 1row $subdb $subquery]
    set_variables_after_query

    if { ($flexible > 0) || ($problems_graded < $problems_in_set) } {
	set flexible "t"
    } else {
	set flexible "f"
    }

    set turned_in [database_to_tcl_string $subdb "select count(*) from vu_turn_in
                                                  where course_id = $course_id
                                                    and person_id = $person_id
                                                    and problemset_id = $problemset_id
                                                    and deleted_date is NULL"]

    set selection $selection_tmp

    append body "<tr bgcolor=$color><td>[mailto $email $name]
        <td align=center>[vu_report_item $person_id $problemset_id $course_id $score $flexible $turn_in_service $turned_in]"

    set color [vu_toggle_row_color $color]
}
append body "</table>"

set problemset_name [database_to_tcl_string $db "select problemset_name from vu_problemset 
                                                 where problemset_id = $problemset_id"]

set navbar [vu_navbar3 [vu_link "user/index.tcl" "Your Workspace"] [vu_link "user/grades_problemsets.tcl?course_id=$course_id" "Grading Items"] "One Item"]

vu_returnpage_header "Grading Item $problemset_name" $db $course_id $body $navbar
