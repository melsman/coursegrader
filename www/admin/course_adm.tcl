# set the form variable course_id
set_form_variables

set person_id [vu_verify_person]

set db [ns_db gethandle]

if { ![vu_course_responsible $db $course_id $person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

set name [database_to_tcl_string $db "select name from vu_person where person_id = $person_id"]

set course_url [database_to_tcl_string $db "select course_url from vu_course where course_id = $course_id"]

if { $course_url == "" } {
    set course_url "http://"
}

set course_name [database_to_tcl_string $db "select course_name from vu_course where course_id = $course_id"]

set grading_visibility [database_to_tcl_string $db "select grading_visibility from vu_course 
                                                    where course_id = $course_id"]

if { [string compare $grading_visibility "responsible"] == 0 } {
    set checked_responsible checked
    set checked_assistant ""
} else {
    set checked_responsible ""
    set checked_assistant checked
}    


set navbar "[vu_navbar2 [vu_link user/index.tcl "Your Workspace"] "Admin"]"

# Return a page

vu_returnpage_admheader "Profile" $db $course_id "

<b>Course responsible</b><br> $name <p>

<form action=url_update.tcl bgcolor=white>
<input type=hidden name=course_id value=$course_id>

<b>Course name</b><br>
<input type=text size=50 name=course_name value=\"$course_name\"> <p>

<b>Course URL</b><br>
<input type=text size=50 name=course_url value=\"$course_url\"> <p>

<b>When should problem set gradings become visible to students</b><br>
<table bgcolor=white border=0>
<tr>
<td><INPUT TYPE=RADIO NAME=grading_visibility VALUE=responsible $checked_responsible></td>
<td>after course responsible has approved (locked) grading</td>
</tr>
<tr>
<td><INPUT TYPE=RADIO NAME=grading_visibility VALUE=assistant $checked_assistant></td>
<td>after problem set is graded by teaching assistant</td>
</tr>
</table><p>
<center>
<input type=submit value=\"Update Profile\">
</center>
</form>" $navbar

