# list all problems for a given problem set

# set the form variables problemset_id, problemset_name, course_id
set_the_usual_form_variables

set db [ns_db gethandle]

set query "select problem_id, problem_name, maxpoint
           from vu_problem
           where problemset_id = $problemset_id
           order by problem_name"

set selection [ns_db select $db $query] 

set totalmaxpoint 0
set color "lightblue"

set body "<table align=center border=0 bgcolor=silver cellpadding=2 cellspacing=0 width=70%><tr><th>Part<th>Max points<th>&nbsp;"
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr totalmaxpoint $maxpoint
    append body "<tr bgcolor=$color><td align=center> $problem_name <td align=center> $maxpoint
      <td align=center> <a href=\"problem_remove.tcl?course_id=$course_id&problem_id=$problem_id&problemset_id=$problemset_id&problemset_name=[ns_urlencode $problemset_name]\">remove</a>"
    if { $color == "lightblue" } {
	set color "\"#eeeeee\""
    } else {
	set color "lightblue"
    }
}

set navbar "[vu_navbar2 [vu_link user/index.tcl "Your Workspace"] "Admin"]"

vu_returnpage_admheader "Grading item $problemset_name" $db $course_id "
 Add parts to the grading item below. All the parts should add up to 100 points. You need to add parts here to use the system. <p>
 <form action=problem_add.tcl>
 <input type=hidden name=problemset_id value=$problemset_id>
 <input type=hidden name=problemset_name value=\"$problemset_name\">
 <input type=hidden name=course_id value=\"$course_id\">
 $body <p>
 <tr><td align=center> <input type=text size=10 name=problem_name>
 <td align=center><input type=text size=3 name=maxpoint value=[expr 100 - $totalmaxpoint]>
 <td align=center><input type=submit value=Add>
 <tr><th>Total<th>$totalmaxpoint<th>&nbsp;
 </table>
 </form>
" $navbar
