# set the form variable `course_id'
set_form_variables 

set db [ns_db gethandle]

set query "select problemset_id, problemset_name, grading_group, weight
           from vu_problemset, vu_grading_group
           where vu_problemset.course_id = $course_id
             and vu_grading_group.name = grading_group
             and vu_grading_group.course_id = $course_id
           order by grading_group,problemset_name"

set selection [ns_db select $db $query]

set body "<table bgcolor=\"#eeeeee\" cellpadding=5 cellspacing=0 border=0 align=center width=50%>
              <tr bgcolor=silver><th width=50%>Grading Item<th width=50%>Grading Group"
set tmp ""
set color [vu_toggle_row_color]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $tmp != $grading_group } {
	set tmp $grading_group
	set group_text "<td align=center>$grading_group ($weight\%)"
    } else {
	set group_text "<td>&nbsp;"
    }
    append body "<tr bgcolor=$color><td align=center><a href=\"grades_problemset.tcl?problemset_id=$problemset_id&course_id=$course_id\">$problemset_name</a> $group_text"
    set color [vu_toggle_row_color $color]
}
append body "</table>"

set navbar "[vu_navbar2 [vu_link "user/index.tcl" "Your Workspace"] "Grading Items"]"

vu_returnpage_header "Grading Items" $db $course_id $body $navbar
