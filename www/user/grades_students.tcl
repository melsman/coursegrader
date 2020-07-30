# set the form variable `course_id'

set_form_variables 

set auth_person_id [vu_verify_person]

set db [ns_db gethandle]

#---------------------------------------------------------
# check that the page is inspected by an authorised user
#---------------------------------------------------------
if { ![vu_course_teacher $db $course_id $auth_person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

set subdb [ns_db gethandle subquery]

#----------------------------------------------------------------
# How many attend the course (used to setup an array of strings)
#----------------------------------------------------------------
set number_of_persons [database_to_tcl_string $db "select count(*) 
                                                   from vu_student
                                                   where course_id = $course_id"]

#-------------------------------------
# Compute meta headings
#-------------------------------------
set query "select grading_group, weight, count(*) as number_of_items
           from vu_problemset, vu_grading_group
           where vu_problemset.course_id = $course_id
               and vu_grading_group.course_id = $course_id
               and vu_grading_group.name = grading_group
           group by grading_group, weight
           order by grading_group"

set selection [ns_db select $db $query]

set meta_headings "<tr><th colspan=3>&nbsp;"

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append meta_headings "<th colspan=$number_of_items><font size=-1>$grading_group ($weight\%)</font>"
}

#-------------------------------------
# Now compute the table headings
#-------------------------------------
set query "select problemset_name, problemset_id, grading_group, weight, turn_in_service 
           from vu_problemset, vu_grading_group
           where vu_problemset.course_id = $course_id
               and vu_grading_group.course_id = $course_id
               and vu_grading_group.name = grading_group
           order by grading_group, problemset_name"

set selection [ns_db select $db $query]

set heading_ids [list]
set number_of_problemsets 0

set headings ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    lappend heading_ids $problemset_id
    incr number_of_problemsets
    append headings "<th><font size=-1>$problemset_name</font> "
    set turn_in_service_array($problemset_id) $turn_in_service

}

# -----------------------------------------------
# Now, compute the array of problemset columns
# -----------------------------------------------

set query "select vu_person.person_id,
              vu_person.name, 
	      vu_grading_group.name as grading_group, 
	      vu_problemset.problemset_name, 
	      vu_problemset.problemset_id, 
	      sum(vu_problem_solution.grade) as score
       from vu_person, 
	    vu_student,
	    vu_grading_group, 
	    vu_problemset, 
	    vu_problem, 
	    vu_problem_solution
       where vu_person.person_id = vu_problem_solution.person_id (+)
	 and vu_problem.problem_id = vu_problem_solution.problem_id
	 and vu_problemset.problemset_id = vu_problem.problemset_id
	 and vu_problemset.course_id = $course_id
	 and vu_student.person_id = vu_person.person_id
	 and vu_student.course_id = vu_problemset.course_id
	 and vu_grading_group.course_id = vu_student.course_id
       group by vu_person.name, 
                vu_person.person_id, 
		vu_grading_group.name, 
		vu_problemset.problemset_name,
                vu_problemset.problemset_id"

set selection [ns_db select $db $query]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    set person_array("$person_id-$problemset_id") $score
}

# ------------------------------------------------
# Determine who has turned in problemsets
# ------------------------------------------------
set query "select person_id, problemset_id
             from vu_turn_in
            where course_id = $course_id
              and deleted_date is NULL"

set selection [ns_db select $db $query]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    set turned_in_array("$person_id-$problemset_id") "turned-in"
}


#----------------------------------------------------------
# See which problemsets has a flexible problem solution in 
# them or has an incorrect number of problem solutions; store 
# the result in an array for later access
#----------------------------------------------------------
set query "select vu_person.person_id, vu_problemset.problemset_id
           from vu_problem_solution, vu_person, vu_problem, vu_problemset
           where rigid = 'f'
             and vu_person.person_id = vu_problem_solution.person_id
             and vu_problem_solution.problem_id = vu_problem.problem_id
             and vu_problemset.course_id = $course_id
             and vu_problemset.problemset_id = vu_problem.problemset_id 
           union
           select distinct vu_person.person_id, vu_problemset.problemset_id
           from vu_person, vu_problemset, vu_student
           where vu_problemset.course_id = $course_id
             and vu_student.person_id = vu_person.person_id
             and vu_student.course_id = vu_problemset.course_id
             and (select count(*)
                  from vu_problem_solution, vu_problem
                  where vu_problem_solution.problem_id = vu_problem.problem_id
                    and vu_problem.problemset_id = vu_problemset.problemset_id
                    and vu_problem_solution.person_id = vu_person.person_id) !=
                (select count(*)
                 from vu_problem
                 where vu_problem.problemset_id = vu_problemset.problemset_id)"

set selection [ns_db select $db $query]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    set flexible_array("$person_id-$problemset_id") "flexible"
}

# --------------------------------------
# Now, start build the table!
# --------------------------------------

set body "<table bgcolor=silver border=1 cellpadding=2 cellspacing=0 align=center width=90%>
          $meta_headings 
          <tr><th><font size=-1>Name</font>
          <th><font size=-1>Grade</font>
          <th><font size=-1>Total score</font>
          $headings"

#----------------------------------------------------------------------
# The following query gets names, grades, and total scores. We fetch
# problemset scores from the previously built array
#
# The select calculates a total score and a grade for each student; the
# select uses PL/SQL functions vu_course_total and vu_course_grade,
# which are both defined in the file sql/vu_model.sql.
#----------------------------------------------------------------------
set query "select vu_person.person_id, 
		  vu_person.name, 
		  vu_person.email,
		  vu_course_grade(vu_student.course_id, vu_student.person_id) as course_grade,
		  vu_course_total(vu_student.course_id, vu_student.person_id) as total_score
	   from vu_student, 
		vu_person
	   where vu_student.course_id=$course_id
	   and vu_student.person_id = vu_person.person_id
	   order by vu_person.name"

set selection [ns_db select $db $query]

set color [vu_toggle_row_color]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    set cols ""
    set row ""
    set available_count 0
    foreach ps_id $heading_ids {
	set score ""
	set flexible 1
	set turned_in 0
	set turn_in_service "f"

	if { [info exists person_array("$person_id-$ps_id")] } {
	    set score [set person_array("$person_id-$ps_id")]
	    incr available_count
	    if { ! [info exists flexible_array("$person_id-$ps_id")] } {
		set flexible 0
	    }
	}
	
	if { [info exists turn_in_service_array($ps_id)] } {
	    if { [set turn_in_service_array($ps_id)] == "t" } {
		set turn_in_service "t"
	    }
	}
		
	if { [info exists turned_in_array("$person_id-$ps_id")] } {
	    set turned_in 1
	}
	
	append row "<td align=center> 
           [vu_report_item $person_id $ps_id $course_id $score $flexible $turn_in_service $turned_in]"
    }
 
# Commented out to meet request from Fritz Henglein
#    if { $available_count < $number_of_problemsets } {
#	set course_grade "-"
#    }

    if { $course_grade == "" } {
        set course_grade "&nbsp;"
    }

    if { $total_score == "" } {
	set total_score 0
    }

    append body "<tr bgcolor=$color><td> <font size=-1>[mailto $email $name]</font>
                 <th><font size=-1>$course_grade</font><td align=center><font size=-1>$total_score</font>
                 $row"

    set color [vu_toggle_row_color $color]
}


append body "</table> <p>
             [vu_report_grading_policy $db $course_id]"


set navbar "[vu_navbar2 [vu_link user/index.tcl "Your Workspace"] "Student Overview"]"

# number of seconds after 1970
set seconds [clock seconds]
# the date in a nice format
set now [clock format $seconds -format "%Y-%m-%d, %R"]

vu_returnpage_header "Student Overview" $db $course_id "Printed $now<p>$body" $navbar

