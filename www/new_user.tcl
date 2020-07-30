# set the form variable email, name
set_the_usual_form_variables

if { ![regexp {^.+@.+\..+$} $email] } { 
    ns_return 200 text/html "You must enter a valid email address - `$email' is not one!"
    return
}

if { ![regexp {^[a-zA-ZÊ¯Â∆ÿ≈ '\-]+$} $name] } {
    ns_return 200 text/html "You must enter a valid full name!"
    return
}

set password [new_password]

set db [ns_db gethandle]

set person_id [database_to_tcl_string $db "select vu_person_id_sequence.nextval from dual"]

set insert_sql "insert into vu_person (person_id, email, name, password)
                values ($person_id, '$QQemail', '$QQname', '$password')"

if [ catch { ns_db dml $db $insert_sql } errmsg ] {
    set name [database_to_tcl_string $db "select name from vu_person 
                                          where email = '$QQemail'"]
    vu_returnpage "User `$email' already exists!" "A user `$name'
      with email address `$email' is already in the database! <p> Press the button below to send yourself
      an email message with your password.
      <center><form action=email_password.tcl><input type=hidden name=email value=\"$email\">
        <input type=submit value=\"Send Email\"></form></center>"
    return
}

ns_returnredirect "email_password.tcl?email=[ns_urlencode $email]"
