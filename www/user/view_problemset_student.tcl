proc vu_txt_to_html { arg } {
    # change & to &amp; and " to &quot;
    regsub -all {&} $arg {&amp;} arg
    # regsub -all {"} $arg {&quot;} arg
    # change < to &lt; and > to &gt;
    regsub -all {<} $arg \\&lt\; arg
    regsub -all {>} $arg \\&gt\; arg
    # change \n to <br>
    regsub -all \n $arg {<br>} arg
    return "<code>$arg</code>"
}

proc vu_txt_to_html2 { arg } {
    return $arg
}

# set the form variable `course_id', 'problemset_id'
set_form_variables 

set person_id [vu_verify_person]

set db [ns_db gethandle]

# check that the page is inspected by an authorised user
if { ![vu_course_student $db $course_id $person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

set grading_visibility [database_to_tcl_string $db "select grading_visibility from vu_course 
                                                    where course_id = $course_id"]


set subdb [ns_db gethandle subquery]

set query "select problem_id, problem_name, maxpoint
           from vu_problem where problemset_id = $problemset_id"

set selection [ns_db select $db $query]

set body "<table align=center width=95% cellpadding=5 cellspacing=0 border=0 bgcolor=silver>
          <tr><th width=10%>Part<th width=70%>Comments by grader<th width=10%>Max Score<th width=10%>Score"
set totalgrade 0

set color [vu_toggle_row_color]

while { [ns_db getrow $db $selection] } {
    #set the variables 'problem_id', 'problem_name', 'maxpoint', 'rigid'
    set_variables_after_query
    set selection_save $selection
    #extract data for the student
    set subquery "select text, grade, rigid, vu_person.name as lcb_name, vu_person.email as lcb_email, last_changed_date 
                  from vu_problem_solution, vu_person 
                  where vu_person.person_id = vu_problem_solution.last_changed_by 
                  and vu_problem_solution.person_id = $person_id
                  and problem_id = $problem_id"
    set selection [ns_db 0or1row $subdb $subquery]
    if { $selection == "" } {
	set grade "-"
	set text "Not graded yet"
	set rigid "f"
    } else {
	set_variables_after_query
	set lcb "Graded $last_changed_date by [mailto $lcb_email $lcb_name]"
	if { $rigid == "f" } {
	    if { [string compare $grading_visibility "responsible"] == 0 } {
		set grade "-"
		set text "$lcb - not yet verified by course responsible"
	    } else {
		# the util_striphtml procedure is from philg's 00-ad-utilities.tcl
		# the vu_txt_to_html is better because it preserves tags..
		set text "[vu_txt_to_html $text]. $lcb"
		incr totalgrade $grade
	    }
	} else {
	    # the util_striphtml procedure is from philg's 00-ad-utilities.tcl
	    # the vu_txt_to_html is better because it preserves tags..
	    set text "[vu_txt_to_html $text]. $lcb - verified by course responsible"
	    incr totalgrade $grade
	}
    }
    set selection $selection_save

    append body "<tr bgcolor=$color><td align=center> $problem_name
                     <td>$text
                     <td align=center>$maxpoint
                     <td align=center>$grade"

    set color [vu_toggle_row_color $color]
}

append body "<tr><th colspan=3 align=left>Total score<th align=center>$totalgrade
             </table>"


# Show comments provided by student
set student_comments [vu_student_comments $db $course_id $person_id $problemset_id]

if { $student_comments != "" } {
    append body "<h2>Text entered by student</h2>$student_comments"
}

set query "select problemset_name, name, course_name
           from vu_problemset, vu_person, vu_course
           where problemset_id = $problemset_id
             and person_id = $person_id
             and vu_course.course_id = $course_id"
set selection [ns_db 1row $db $query]
set_variables_after_query

set navbar [vu_navbar3 [vu_link user/index.tcl "Your Workspace"] [vu_link "user/view_problemsets_student.tcl?course_id=$course_id" "Status for $course_name"] "One Grading"]

vu_returnpage_header "Grading of $problemset_name for $name" $db $course_id $body $navbar


