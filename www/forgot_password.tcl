set navbar "[vu_navbar2 [vu_link index.tcl Home] "Obtain Password"]"

vu_returnpage_no_logout "Don't Have Your Password?" "
Write your email address and CourseGrader will send you your password by email.<p>
<center>
<form action=email_password.tcl>
<input type=text name=email size=40><p>
<input type=submit value=\"Obtain Password\">
</center>" $navbar