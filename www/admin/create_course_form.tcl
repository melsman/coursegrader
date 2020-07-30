

set person_id [vu_verify_person]

#-------------------------
# get name and email
#-------------------------
set db [ns_db gethandle]
set selection [ns_db 0or1row $db "select name, email from vu_person where person_id = $person_id"]
if { $selection == "" } {
    ns_returnredirect "../auth_form.tcl"
    return
}
set_variables_after_query

set navbar "[vu_navbar2 [vu_link user/index.tcl "Your Workspace"] "New Course"]"


vu_returnpage "New Course" "If you are
responsible for a course on a university or some other school, feel
free to use this service to manage student grading for a course. <p> To begin, enter the title and the
semester for the course.<p>

<form action=create_course.tcl> <table align=center>
<tr><th align=left>Course title <td><input type=text size=30 name=title>
<tr><th align=left>Semester (e.g., F2000, E2001) <td><input type=text size=5 name=semester>
<tr><td colspan=2 align=center><input type=submit value=\"Create New Course\">
</table>
</form>" $navbar
