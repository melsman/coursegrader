
# -------------------------------------------------------------------
# procedure to list the problem sets for a course; the 
# procedure takes as argument a database handle and a course id and 
# returns HTML-code for an unordered list of problem sets.
# -------------------------------------------------------------------
proc list_problemsets { db course_id } {

    set query "select problemset_id, problemset_name, grading_group from vu_problemset
               where course_id = $course_id
               order by problemset_name" 

    set selection [ns_db select $db $query]

    set color "\"#dddddd\""

    set res "<form action=problemset_add.tcl>  
             <input type=hidden name=course_id value=$course_id>
             <table bgcolor=silver border=0 cellpadding=2 cellspacing=0 align=center width=70%><tr><th>Grading Item<th>Grading Group<th>&nbsp;"
    while { [ns_db getrow $db $selection] } {
	# we have a row from the table, now turn the column
	# names into tcl-variables
	set_variables_after_query
	append res "<tr bgcolor=$color><td align=center> 
            <a href=\"problemset_show.tcl?course_id=$course_id&problemset_id=$problemset_id&problemset_name=[ns_urlencode $problemset_name]\">$problemset_name</a> 
          <td align=center> $grading_group
          <td align=center> 
        <a href=\"problemset_remove.tcl?problemset_id=$problemset_id&course_id=$course_id\">remove</a>"

	if { $color == "\"#dddddd\"" } {
	    set color "\"#eeeeee\""
	} else {
	    set color "\"#dddddd\""
	}
    }
    append res "<tr bgcolor=silver><td align=center><input type=text size=10 name=problemset_name>
                <td align=center><input type=text size=10 name=grading_group>
                <td align=center><input type=submit value=Add>
                </table></form>"
    return $res
}


# set the form variable course_id
set_form_variables

set person_id [vu_verify_person]

set db [ns_db gethandle]

if { ![vu_course_responsible $db $course_id $person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    


set navbar "[vu_navbar2 [vu_link user/index.tcl "Your Workspace"] "Admin"]"

# Return page

vu_returnpage_admheader "Grading Items" $db $course_id "
A <i>grading item</i> is comprised by a set of item parts, each of
which has associated with them a maximum score, which add up to
100. Each grading item belongs to a grading group. It is possible to
configure that for each student only a number of the best grading
items (e.g., problem sets) count in the grade computation. A problem
set and an exam are examples of grading items. <p>

To configure (and setup) a particular grading item, click on the name
of the grading item.

[list_problemsets $db $course_id]
" $navbar
