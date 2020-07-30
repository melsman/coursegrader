set person_id [vu_verify_person]

if { $person_id == 0 } {
    set enter_text ""
} else {
    set db [ns_db gethandle]
    set name [database_to_tcl_string $db "select name from vu_person where person_id = $person_id"]
    set enter_text "<tr><td colspan=2>You can go directly to [vu_link "user/index.tcl" "$name's Workspace"]"
}

set form "
  <form action=auth.tcl method=post>
   <table>
     <tr><td><b>Email</b></td>
         <td><input type=text name=vu_email size=20></td>
     </tr>
     <tr><td><b>Password</b></td>
         <td><input type=password name=vu_password size=20></td>
     </tr>
     <tr><td colspan=2 align=center><input type=submit value=Login></td>
     </tr>
     $enter_text
   </table>
  </form>"

set body "
<table width=100% border=0 cellpadding=10 cellspacing=0>

<tr> <td><font size=+2><b>Students:</b></font> Login to turn-in your
home work or to see your home-work scores - you can <a
href=\"forgot_password.tcl\">get your password</a> by email in case
you have not received a password or in case you forgot it.

<td valign=top align=right rowspan=3>
[vu_border_table darkblue "<font color=white><b>LOGIN</b></font>" $form]

<tr><td> <font size=+2><b>Assistants:</b></font> Enter the site and
grade the newest problem sets submitted by the students - you can <a
href=\"forgot_password.tcl\">get your password</a> by email.

<tr><td> <font size=+2><b>Course Administrators:</b></font> Login and
administer a course - it is free! If you are new to this site, go ahead and <a
href=\"new_user_form.tcl\">register</a>. You can <a
href=\"forgot_password.tcl\">get your password</a> by email in case
you have forgotten it.

</table>"

if { $person_id == 0 } {
    vu_returnpage_no_logout "" $body
} else {
    vu_returnpage "" $body    
}