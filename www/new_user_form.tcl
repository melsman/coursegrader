set navbar "[vu_navbar2 [vu_link index.tcl Home] "New User"]"

set body "  
  To administer a course, first, enter your email address and your full name. When 
  you press submit, a password is sent to you by email.

  <form action=new_user.tcl>
  <table>
  <tr><th align=left>Your email address<td>
  <input type=text name=email size=20>
  <tr><th align=left>Your name<td>
  <input type=text name=name size=20>
  <input type=submit value=Submit>
  </table>
  </form>"

vu_returnpage_no_logout "Registration" $body $navbar
