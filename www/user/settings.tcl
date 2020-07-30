set navbar "[vu_navbar2 [vu_link user/index.tcl "Your Workspace"] Settings]"

vu_returnpage "Settings" "
<ul>
<li><a href=\"../admin/create_course_form.tcl\">Administer a new course</a>
<li><a href=passwd_form.tcl>Change your password</a>
</ul>" $navbar
