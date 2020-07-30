# set vu_email and vu_password
set_the_usual_form_variables

if { ! [philg_email_valid_p $vu_email] } {
    ns_return 200 text/html "You must enter a valid email address - use the back-button on your browser to correct your input."
    return
}

set db [ns_db gethandle]

set query "select person_id from vu_person where email = '$vu_email'"

set selection [ns_db 0or1row $db $query]
if { $selection == "" } {
    ns_return 200 text/html "The email address that you entered is not in the database - use the back-button on your browser to correct your input."
    return
}

set_variables_after_query

# set host_header [ns_set iget [ns_conn headers] "Host"]
# ns_log Notice "auth.tcl: returning a redirect to user/index.tcl with a cookie! vu_home_url = [vu_home_url] - email = $vu_email - "
# ns_log Notice "host_header = $host_header"

# return a redirect with a cookie!
ns_write "HTTP/1.0 302 Found
Location: [vu_home_url]user/index.tcl
MIME-Version: 1.0
Set-Cookie: vu_person_id=expired; path=/; expires=Fri, 01-Jan-1990 01:00:00 GMT
Set-Cookie: vu_password=expired; path=/; expires=Fri, 01-Jan-1990 01:00:00 GMT
Set-Cookie: vu_person_id=$person_id; path=/;
Set-Cookie: vu_password=[ns_urlencode $vu_password]; path=/;


You should not be seeing this!
"
