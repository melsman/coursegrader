# set the variables email, cont, name

set_the_usual_form_variables

set db [ns_db gethandle]

# generate a new password
set pw [new_password]

# get a new person_id from Oracle
set person_id [database_to_tcl_string $db "select vu_person_id_sequence.nextval from dual"]

set insert_sql "insert into vu_person (person_id, email, name, password)
                values ($person_id, '$QQemail', '$QQname', '$pw')"

# one could imagine a crash here, if a user with this email address has 
# been added between the check and now!
catch { [ns_db dml $db $insert_sql] } errmsg

#call the continuation
ns_returnredirect "${cont}person_id=$person_id"
