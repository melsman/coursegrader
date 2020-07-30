# set the form variable `course_id'
set_form_variables 

set person_id [vu_verify_person]

set db [ns_db gethandle]

#---------------------------------------------------------
# check that the page is inspected by an authorised user
#---------------------------------------------------------
if { ![vu_course_teacher $db $course_id $person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    



set selection [ns_db 0or1row $db "select name as from_name, email as from_email 
                                  from vu_person 
                                  where person_id = $person_id"]
if { $selection == "" } {
    ns_returnredirect "../auth_form.tcl"
    return
}

set_variables_after_query

set course_name [database_to_tcl_string $db "select course_name from vu_course where course_id = $course_id"]

#students
set query "select email
           from vu_person, vu_student
           where vu_student.course_id = $course_id
             and vu_student.person_id = vu_person.person_id"

set selection [ns_db select $db $query]

set students ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $students != "" } {
	append students ", $email"
    } else {
	append students $email
    }
}

# teachers = course_responsible @ course_assistants

set query "select email
           from vu_person, vu_course
           where vu_course.course_id = $course_id
             and vu_course.responsible = vu_person.person_id"

set teachers [database_to_tcl_string $db $query]

set query "select email 
           from vu_person, vu_course_assistant
           where vu_course_assistant.course_id = $course_id
             and vu_course_assistant.person_id = vu_person.person_id"

set selection [ns_db select $db $query]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append teachers ", $email"
}

set body "
<form method=post action=send_email2.tcl>
<input type=hidden name=course_id value=$course_id>
<table align=center>
<tr><th align=left>From:<td>[mailto $from_email $from_name] <input type=hidden name=from value=$from_email>
<tr><th align=left>To: <td> <TEXTAREA NAME=to ROWS=3 COLS=70 wrap=virtual>$students</TEXTAREA>
<tr><th align=left>Cc: <td> <TEXTAREA NAME=cc ROWS=3 COLS=70 wrap=virtual>$teachers</TEXTAREA>
<tr><th align=left>Subject:<td><input type=text name=subject size=70>
<tr><th align=left>Message:<td><TEXTAREA NAME=body ROWS=10 COLS=70 wrap=virtual></TEXTAREA>
<tr><th colspan=2><input type=submit value=\"Send Message\">
</table>
</form>
"

set navbar "[vu_navbar2 [vu_link user/index.tcl "Your Workspace"] "Email Students"]"

vu_returnpage_header "Send Email to Students" $db $course_id $body $navbar

