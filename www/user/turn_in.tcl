# set the form variable `course_id', 'problemset_id'
set_form_variables 

set person_id [vu_verify_person]

set db [ns_db gethandle]

# Check that the page is inspected by an authorised user
if { ![vu_course_student $db $course_id $person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

set course_name [database_to_tcl_string $db "select course_name from vu_course 
                                                 where course_id = $course_id"]

set navbar [vu_navbar3 [vu_link user/index.tcl "Your Workspace"] [vu_link "user/view_problemsets_student.tcl?course_id=$course_id" "Status"] "Turn-In"]

set problemset_name [database_to_tcl_string $db "select problemset_name from vu_problemset 
                                                 where problemset_id = $problemset_id"]

vu_returnpage_header "Turn-in $problemset_name" $db $course_id "
<form method=post action=turn_in2b.tcl>
<table align=center>
<input type=hidden name=course_id value=$course_id>
<input type=hidden name=problemset_id value=$problemset_id>
<tr><td><textarea wrap=virtual cols=70 rows=15 name=text>I finished $problemset_name.</textarea>
<tr><td align=center><input type=submit value=\"Turn in $problemset_name\">
</table>
</form>

What you write in the text-box above become visible to the
course responsible and the course assistants.

" $navbar

