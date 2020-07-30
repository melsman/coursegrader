set pid [vu_verify_person]

#set old, new1 and new2
set_the_usual_form_variables

set db [ns_db gethandle]

set old0 [database_to_tcl_string $db "select password from vu_person where person_id = $pid"]

if { [string compare $old0 $old] != 0 } {
    ns_return 200 text/html "Old password is incorrect - use your browser's back-button to go back and change your input"
    return
}

if { [string compare $new1 $new2] != 0 } {
    ns_return 200 text/html "New passwords are different - use your browser's back-button to go back and change your input"
    return
}

ns_db dml $db "update vu_person set password = '$QQnew1'
               where person_id = $pid"

set navbar "[vu_navbar3 [vu_link user/index.tcl "Your Workspace"] [vu_link user/settings.tcl "Settings"] "Password Changed"]"

vu_returnpage "Password Changed" "You must now <a href=../index.tcl>login with your new password</a>." $navbar
