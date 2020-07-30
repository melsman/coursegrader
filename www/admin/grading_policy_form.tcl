# Set the form variable 'course_id'
set_form_variables

set person_id [vu_verify_person]

set db [ns_db gethandle]

if { ![vu_course_responsible $db $course_id $person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

proc switch_color { color } {
    if { $color == "\"#dddddd\"" } {
	return "\"#eeeeee\""
    } else {
	return "\"#dddddd\""
    }
}

# -------------------------------------------------
#  Computation of grade_groups
# -------------------------------------------------

set query "select name, weight, items_that_counts, turn_in_service, count(*) as grading_items
           from vu_grading_group, vu_problemset
           where vu_grading_group.course_id = vu_problemset.course_id
             and vu_grading_group.name = vu_problemset.grading_group
             and vu_grading_group.course_id = $course_id
           group by name, weight, items_that_counts, turn_in_service
           order by weight"

set selection [ns_db select $db $query]

set rows ""
set total 0
set color "\"#dddddd\""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $grading_items == 0 } {
	set items_text "SOMETHING IS WRONG"
    } elseif { $grading_items == 1 } {
	set items_text "1 item"
    } else {
	set items_text "$grading_items items"
    }

    if { $items_that_counts == "" } {
	set items_that_counts $grading_items
    }
	
    incr total $weight

    if { $turn_in_service == "t" } {
	set turn_in_false "f"
	set turn_in_true "t selected"
    } else {
	set turn_in_false "f selected"
	set turn_in_true "t"
    }

    append rows "<tr bgcolor=$color><td> <a href=\"problemsets.tcl?course_id=$course_id\">$name</a> ($items_text)</td>
      <td align=center> 
         <form action=grade_group_edit.tcl>
          <input type=hidden name=course_id value=$course_id>
          <input type=hidden name=grading_group value=\"$name\">
          <input type=text size=4 value=$weight name=weight>
      </td>
      <td align=center>
          <input type=text size=4 value=$items_that_counts name=items_that_counts> of $items_text
      </td>
      <td align=center> 
          <SELECT NAME=turn_in_service>
             <OPTION VALUE=$turn_in_false>No
             <OPTION VALUE=$turn_in_true>Yes
          </SELECT></td>
      <td align=center> 
          <input type=submit value=\"Modify\">
      </td></tr>
      </form>"

    set color [switch_color $color]
}

set grade_group_form "
<table width=90% align=center cellpadding=5 cellspacing=0 border=0><tr bgcolor=silver><th>Grading group<th>Weight (\%)<th> Which best items count <th> Turn-in service<th> &nbsp;
$rows
<tr bgcolor=silver><th align=left>Total
<th>$total
<td align=center>&nbsp;<td>&nbsp;<td>&nbsp;
</table>"


# -------------------------------------------------
#  Computation of grade_mapping_form
# -------------------------------------------------
	
set query "select first, last, grade 
           from vu_grade_range
           where course_id = $course_id
           order by first"

set selection [ns_db select $db $query]

set position 0
set rows ""
set color "\"#dddddd\""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $first != $position } {
	append rows "<tr bgcolor=$color><td align=center><font color=red>[vu_range $position [expr $first - 0.5]]</font> 
          <td align=center> <font color=red>Undefined </font> <td>&nbsp;"
	set color [switch_color $color]
    }
    set position [expr $last + 0.5]
    append rows "<tr bgcolor=$color><td align=center> [vu_range $first $last]
      <td align=center> $grade 
      <td align=center> <a href=\"grade_range_remove.tcl?course_id=$course_id&first=$first&last=$last\">remove</a>"
    set color [switch_color $color]
}

if { $position != 100.5 } {
    append rows "<tr bgcolor=$color><td align=center><font color=red>[vu_range $position 100]</font> 
             <td align=center> <font color=red>Undefined</font> <td>&nbsp;"
}


set grade_mapping_form "<form action=grade_range_add.tcl>
<input type=hidden name=course_id value=$course_id>
<table align=center bgcolor=silver cellpadding=5 cellspacing=0 border=0><tr><th>Range<th>Grade<th>&nbsp;
$rows
<tr><td align=center>
<SELECT NAME=left>
<OPTION VALUE=include>\[
<OPTION VALUE=exclude>\]
</SELECT>
<input type=text size=3 name=first> - 
<input type=text size=3 name=last>
<SELECT NAME=right>
<OPTION VALUE=exclude>\[
<OPTION VALUE=include>\]
</SELECT>
<td><input type=text size=15 name=grade>
<td align=center><input type=submit value=Add>
</table></form>"

# Get grading policy text etc. from database
set query "select text, which_to_grade
           from vu_problemsets_grade
           where course_id = $course_id"
set selection [ns_db 0or1row $db $query]

if { $selection == "" } {
    set text ""
    set which_to_grade ""
} else {
    set_variables_after_query
}

set navbar "[vu_navbar2 [vu_link user/index.tcl "Your Workspace"] "Admin"]"

# ----------------------------------------------
#   Return the resulting page
# ----------------------------------------------

vu_returnpage_admheader "Grading Policy" $db $course_id "

The <i>grading policy</i> for a course is made up of a
configuration of grading groups and a mapping from total scores to grades.  

<h2>Grading groups</h2>

The final grade for a student is computed on the basis of one or more
<i>grading groups</i>. You, as a course administrator, can add and
delete grading groups and define the weight of each group. For
example, you can define that an exam weights 40\%, problem sets 30\%
and class participation 30\%. <p>  A grading group is associated with zero
or more grading items. It is possible to configure that for each
student only a number of the grading items (e.g., problem sets) with the highest scores
count in the grade computation.<p>

$grade_group_form

<h2>Mapping of total scores to grades</h2>
Using the remove and add facilities below, you can define the mapping of total scores to 
grades (e.g., you can define that the total-score range \[ 85-95 \[ maps to the grade B). 
You must specify non-overlapping ranges.

The mapping is used in the calculation of student grades. Students
can see their own grades and the grading policy.<p>

$grade_mapping_form


<h2>Grading policy text</h2> 

Here you can provide a paragraph to complement the grading policy. The
grading policy, including grading groups, the mapping of percentages
to grades, and the grading policy text, can be seen by assistants and
students.<p>

<form action=grading_policy_update.tcl>
<table align=center>
<input type=hidden name=course_id value=$course_id>
<input type=hidden name=which_to_grade value=$which_to_grade>
<tr><th>Grading policy text
<tr><td><textarea wrap=virtual cols=70 rows=5 name=text>$text</textarea>
<tr><td align=center><input type=submit value=\"Submit grading policy text\">
</table>
</form>
" $navbar
