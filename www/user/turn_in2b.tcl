# set the form variable `course_id', 'problemset_id', 'text'
set_the_usual_form_variables 

set person_id [vu_verify_person]

set db [ns_db gethandle]

# Check that the page is inspected by an authorised user
if { ![vu_course_student $db $course_id $person_id] } {
    ns_returnredirect "../auth_form.tcl"
    return
}    

if { $text == "" } {
    ns_return 200 text/html "You must enter some text!"
    return
}

# split text into pages, each of 2000 characters
# ns_log Notice "Splitting text into pages"
set pages [list]
set l 0
set sz [string length $text]
while { $l < $sz } {
    # ns_log Notice " splitting text $l/$sz"
    if { [expr $l + 2000 < $sz] } {
	set r [expr $l + 2000]
    } else {
	set r [expr $sz - 1]
    }
    lappend pages [string range $text $l $r]
    set l [expr $r + 1]
}

set pg 0
ns_db dml $db "begin transaction"
foreach p $pages {
  # escape ' in $p
  # ns_log Notice "Inserting text of size [string length $p] in DB" 
  set p [ns_dbquotevalue $p]
  set insert_sql "insert into vu_turn_in (person_id, course_id, problemset_id, text, insdate, pg_num)
                  values ($person_id, $course_id, $problemset_id, $p, sysdate, $pg)"
  ns_db dml $db $insert_sql
  incr pg
}
ns_db dml $db "end transaction"

ns_returnredirect "view_problemsets_student.tcl?course_id=$course_id"
