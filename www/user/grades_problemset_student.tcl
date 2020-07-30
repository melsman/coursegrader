# quick-buttons for the course responsible
proc quick_ok { lcb auth_responsible course_id problemset_id problem_id maxpoint person_id } {
    if { $auth_responsible && ($lcb == "<font color=red>Not graded yet</font>") } {
	return "<a href=\"save_problem_solution.tcl?course_id=$course_id&problemset_id=$problemset_id&problem_id=$problem_id&maxpoint=$maxpoint&person_id=$person_id&rigid=t&text=Ok&grade=$maxpoint\">quick ok</a>"
    } else {
	return "&nbsp;"
    }
}

proc quick_zero { auth_responsible course_id problemset_id person_id } {
    if { $auth_responsible } {
	return "(<a href=\"zero_problemset_solution.tcl?course_id=$course_id&problemset_id=$problemset_id&person_id=$person_id\">quick zero</a>)"
    } else {
	return ""
    }
}

proc rigid_text { rigid auth_responsible} {
    if { $auth_responsible } {
	if { $rigid == "f" } {
	    append body "Changeable by assistants: <input type=radio name=rigid value=f checked> yes - 
                                                   <input type=radio name=rigid value=t> no"
	} else {	
	    append body "Changeable by assistants: <input type=radio name=rigid value=f> yes - 
                                                   <input type=radio name=rigid value=t checked> no"
	}
    } else {
	if { $rigid == "f" } {
	    append body "<font color=green>Changeable by assistants</font>"
	} else {	
	    append body "<font color=red>Not changeable by assistants</font>"
	}
	append body "<input type=hidden name=rigid value=$rigid>"
    }
}

# set the form variable `course_id', 'problemset_id', 'person_id'
set_form_variables 

set auth_person_id [vu_verify_person]

set db [ns_db gethandle]

# check that the page is inspected by an authorised user
if { ![vu_course_teacher $db $course_id $auth_person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

set auth_responsible [vu_course_responsible $db $course_id $auth_person_id]

set subdb [ns_db gethandle subquery]

set query "select problem_id, problem_name, maxpoint
           from vu_problem 
           where problemset_id = $problemset_id
           order by problem_name"

set selection [ns_db select $db $query]

set body ""
set totalgrade 0

while { [ns_db getrow $db $selection] } {
    #set the variables 'problem_id', 'problem_name', 'maxpoint', 'rigid'
    set_variables_after_query
    append body "<form method=post action=save_problem_solution.tcl>
    <input type=hidden name=course_id value=$course_id>
    <input type=hidden name=problemset_id value=$problemset_id>
    <input type=hidden name=problem_id value=$problem_id>
    <input type=hidden name=maxpoint value=$maxpoint>
    <input type=hidden name=person_id value=$person_id>"
    set selection_save $selection
    #extract data for the student
    set subquery "select text, grade, rigid, vu_person.name as lcb_name, vu_person.email as lcb_email, last_changed_date 
                  from vu_problem_solution, vu_person 
                  where vu_person.person_id = vu_problem_solution.last_changed_by 
                  and vu_problem_solution.person_id = $person_id
                  and problem_id = $problem_id"
    set selection [ns_db 0or1row $subdb $subquery]
    if { $selection == "" } {
	set grade 0
	set text ""
	set rigid "f"
	set lcb "<font color=red>Not graded yet</font>"
    } else {
	set_variables_after_query
	set lcb "Last changed $last_changed_date by [mailto $lcb_email $lcb_name]"
    }
    set selection $selection_save

    incr totalgrade $grade

    append body "<table width=95% align=center border=0 cellspacing=0 cellpadding=3 bgcolor=\"#eeeeee\">
    <tr><th align=left colspan=2>$problem_name (Max. $maxpoint points) &nbsp; - &nbsp; $lcb 
    <tr><td>[rigid_text $rigid $auth_responsible]
    <td align=center>[quick_ok $lcb $auth_responsible $course_id $problemset_id $problem_id $maxpoint $person_id]
    <tr><td><textarea name=text rows=4 cols=70 wrap=virtual>$text</textarea>
    <td align=center><table border=0><tr><td><input type=text name=grade value=$grade size=3> points <tr><td align=center>
    <input type=submit value=Update></table>
    </table></form>"
}

append body "<p><table width=95% align=center border=0 cellspacing=0 cellpadding=3 bgcolor=\"#eeeeee\">
             <tr><th align=left>Total score<th align=right>$totalgrade
             </table>"

set query "select problemset_name, name, email
           from vu_problemset, vu_person 
           where problemset_id = $problemset_id
             and person_id = $person_id"
set selection [ns_db 1row $db $query]
set_variables_after_query

set navbar [vu_navbar4 [vu_link index.tcl "Your Workspace"] [vu_link "user/grades_problemsets.tcl?course_id=$course_id" "Grading Items"] [vu_link "user/grades_problemset.tcl?problemset_id=$problemset_id&course_id=$course_id" $problemset_name] "Grading"] 

# Show comments provided by student
set student_comments [vu_student_comments $db $course_id $person_id $problemset_id]

if { $student_comments != "" } {
    append body "<h2>Text entered by [mailto $email $name]</h2>$student_comments"
}

# -------------------------------------------
# Warn teacher if student have not yet turned
# in the problem set
# -------------------------------------------

set warn [database_to_tcl_string $db "
  select count(*)
    from vu_grading_group, vu_problemset
   where vu_grading_group.course_id = $course_id
    and vu_problemset.course_id = $course_id
    and name = grading_group
    and problemset_id = $problemset_id
    and turn_in_service = 't'
    and 0 = (select count(*)
               from vu_turn_in
              where person_id = $person_id
                and course_id = $course_id
                and problemset_id = $problemset_id
                and deleted_date is NULL)"]

if { $warn != 0 } {
    set body "<h2><font color=red>WARNING: The student has not yet turned-in the item!</font> [quick_zero $auth_responsible $course_id $problemset_id $person_id]</h2> $body "
}


vu_returnpage_header "Grading of $problemset_name for $name" $db $course_id $body $navbar


