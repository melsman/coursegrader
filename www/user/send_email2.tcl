# set the form variables course_id, from, to, cc, subject, and body
set_form_variables

set person_id [vu_verify_person]

set db [ns_db gethandle]

#---------------------------------------------------------
# check that the page is invoked by an authorised user
#---------------------------------------------------------
if { ![vu_course_teacher $db $course_id $person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    


set cc_set [ns_set new]
ns_set put $cc_set "Cc" $cc

set res [ns_sendmail $to $from $subject $body $cc_set]

if { $res == "" } {

    set body "Your email has been sent - <a href=\"index.tcl\">proceed to workspace</a>"

    set navbar "[vu_navbar2 [vu_link user/index.tcl "Your Workspace"] "Email has been sent"]"

    vu_returnpage_header "Email has been sent" $db $course_id $body $navbar

} else {

  ns_return 200 text/html "I could not send your message - did you provide your full email-address?
                           <p> Use the back-button on your browser to go back!"  

}
