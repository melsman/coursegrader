# set the form variables course_id, email
set_the_usual_form_variables

if { ![regexp {^.+@.+\..+$} $email] } {
    ns_return 200 text/html "You must provide a valid email address!"
    return
}

set db [ns_db gethandle]

# see if a person with this email address exists
set selection [ns_db 0or1row $db "select person_id from vu_person
                                  where email = '$QQemail'"]
if { $selection == "" } {
    # nope; the function call below redirects us to assistant_add2.tcl 
    # after requesting a person name from the user 
    vu_person_add $email "assistant_add2.tcl?course_id=$course_id&"
    return
}

set_variables_after_query

ns_returnredirect "assistant_add2.tcl?course_id=$course_id&person_id=$person_id"
