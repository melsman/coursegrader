# -------------------------------------------------------------------
# procedure to list the assistants of a course; the procedure
# takes as argument a database handle and a course id and returns
# HTML-code for a table containing the assistants.
# -------------------------------------------------------------------
proc list_assistants { db course_id } {

    set query "select email, name, vu_person.person_id
               from vu_course_assistant, vu_person
               where vu_course_assistant.course_id = $course_id
                 and vu_course_assistant.person_id = vu_person.person_id
               order by name" 

    set selection [ns_db select $db $query]
    
    set color "\"#dddddd\""

    set res "<form action=assistant_add.tcl>  
             <input type=hidden name=course_id value=$course_id>
             <table width=70% bgcolor=silver cellpadding=2 cellspacing=0 border=0 align=center><tr><th width=40%>Name<th width=40%>Email<th width=20%>&nbsp;"
    while { [ns_db getrow $db $selection] } {
	# we have a row from the table, now turn the column
	# names into tcl-variables

	set_variables_after_query
	append res "<tr bgcolor=$color><td>$name 
                        <td>[mailto $email $email]
                        <td align=center><a href=\"assistant_remove.tcl?course_id=$course_id&person_id=$person_id\">remove</a>"

	if { $color == "\"#dddddd\"" } {
	    set color "\"#eeeeee\""
	} else {
	    set color "\"#dddddd\""
	}
    }
    append res "<tr bgcolor=silver><td>&nbsp<td align=center><input type=text size=20 name=email>
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

vu_returnpage_admheader "Assistants" $db $course_id "
[list_assistants $db $course_id]" $navbar
