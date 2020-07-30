set navbar "[vu_navbar3 [vu_link user/index.tcl "Your Workspace"] [vu_link user/settings.tcl "Settings"] "Change Password"]"

vu_returnpage "Change Password" "
<form action=passwd.tcl>
<table align>
<tr><td>Old password:</td> <td><input type=password name=old></td></tr>
<tr><td>New password:</td> <td><input type=password name=new1></td></tr>
<tr><td>New password - again:</td> <td><input type=password name=new2></td></tr>
<tr><td colspan=2 align=center><input type=submit value=\"Change Password\"></td></tr></table>
</form>
" $navbar
