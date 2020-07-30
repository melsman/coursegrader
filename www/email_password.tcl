# set the form variable email
set_the_usual_form_variables

#check email
if { ![regexp {^.+@.+\..+$} $email] } {
    ns_return 200 text/html "You must provide a valid email address!"
    return
}

set db [ns_db gethandle]

set query "select password, name from vu_person where email = '$QQemail'"

set selection [ns_db 0or1row $db $query]

if { $selection == "" } {
    ns_return 200 text/html "You do not appear in the database!"
    return
}

set_variables_after_query

set subject "Your CourseGrader password"

set body "
Dear $name,

You can access CourseGrader from

  [vu_home_url]index.tcl

  Username: $email
  Password: $password

Best Regards,

The CourseGrader System"
 
if [ catch {ns_sendmail "$email" "anonymous@itu.dk"  "$subject" "$body"} errmsg ] {
    ns_return 200 text/html "I could not send you a message; did you provide a valid email address?"
    return
}

set navbar [vu_navbar2 [vu_link index.tcl Home] "Email has been sent"]

vu_returnpage_no_logout "Email has been sent" "In a short time, you'll receive an email with your password to CourseGrader.<p>
<a href=\"index.tcl\">Go to the main page</a>" $navbar
