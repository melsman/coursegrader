proc maybe_insert_person { email name db } {
    # see if a person with this email address exists
    set selection [ns_db 0or1row $db "select person_id from vu_person
                                      where email = '$email'"]
    if { $selection == "" } {
	# generate a new password
	set pw [new_password]

	# get a new person_id from Oracle
	set person_id [database_to_tcl_string $db "select vu_person_id_sequence.nextval from dual"]

	set insert_sql "insert into vu_person (person_id, email, name, password)
 	                values ($person_id, '$email', '$name', '$pw')"

	# one could imagine a crash here, if a user with this email address has 
	# been added between the check and now!
	catch { [ns_db dml $db $insert_sql] } errmsg
    } else {
	# set person_id
	set_variables_after_query
    }
    return $person_id
}

proc process_student { email name course_id db } {
    set person_id [maybe_insert_person $email $name $db]

    #associate student with course
    set insert_sql "insert into vu_student (person_id, course_id)
                    values ($person_id, $course_id)"

    # could fail in case of reinserts, I suspect...
    catch { [ns_db dml $db $insert_sql] } errmsg
}

# set the form variables course_id, many_students
set_the_usual_form_variables

set auth_user [vu_verify_person]

set db [ns_db gethandle]

# check that the inserts are done by an authorised user
if { ![vu_course_responsible $db $course_id $auth_user] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

# split input into array of lines
set lines [split $many_students "\n"]

set res ""
foreach l $lines {
   set l [split $l " "]
   set email [lindex $l 0]
   set names [lrange $l 1 [llength $l]]
   set nnames [list]
   foreach n $names {
       set n [string trim $n]
       if { $n != "" } {
	   lappend nnames $n
       }
   }
   set name [join $nnames " "]
   process_student $email $name $course_id $db
#   append res "<li><a href=\"mailto:$email\">$name</a></li>"
}

ns_returnredirect "students.tcl?course_id=$course_id"

#vu_returnpage_admheader "Bulk Student Insert Result" $db $course_id "
#Number of lines: [llength $lines]
#<ol>$res</ol>"
