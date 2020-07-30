#ns_log Notice "Now in user/index.tcl!"

# How administrators and assistants see each course
proc course_row { course_id title url sem color} {
    return "<tr bgcolor=$color>
    <td align=left> <a href=\"$url\">$title</a>
    <td align=center> $sem
    <td align=center> <a href=\"grades_problemsets.tcl?course_id=$course_id\">gradings</a>
    <td align=center> <a href=\"grades_students.tcl?course_id=$course_id\">students</a>
    <td align=center> <a href=\"send_email.tcl?course_id=$course_id\">email</a>"
}

# Students see courses a bit different
proc course_row_stud { person_id course_id title url sem color} {
    return "<tr bgcolor=$color>
    <td align=left> <a href=\"$url\">$title</a>
    <td align=center> $sem
    <td align=center> <a href=\"view_problemsets_student.tcl?course_id=$course_id\">status</a>"
}

proc courses_table { rows {endcols ""}} {
    return "<table align=center cellspacing=0 border=0 bgcolor=silver cellpadding=5 width=90%><tr><th width=35%>Course title<th width=15%>Semester $endcols\n
    $rows\n
    </table>"
}

set person_id [vu_verify_person]

set db [ns_db gethandle]
set selection [ns_db 0or1row $db "select name, email from vu_person where person_id = $person_id"]
if { $selection == "" } {
    ns_return 200 text/html "vu_verify_person returned $person_id"
    # ns_returnredirect "../auth_form.tcl"
    return
}

set_variables_after_query

#---------------------------------------------
# courses for which the person is responsible
#---------------------------------------------
set query "select vu_course.course_id, course_name, course_url, semester 
           from vu_course, vu_person
           where vu_person.person_id = vu_course.responsible
           and vu_person.person_id = $person_id"

set selection [ns_db select $db $query]

set courses_responsible ""
set color [vu_toggle_row_color]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append courses_responsible "[course_row $course_id $course_name $course_url $semester $color]
         <td align=center> <a href=\"../admin/course_dump.tcl?course_id=$course_id\">dump</a>
         <td align=center> <a href=\"../admin/course_adm.tcl?course_id=$course_id\">admin</a>"
    set color [vu_toggle_row_color $color]
}

#---------------------------------------------
# courses for which the person is assistant
#---------------------------------------------
set query "select vu_course.course_id, course_name, course_url, semester 
           from vu_course, vu_person, vu_course_assistant
           where vu_person.person_id = vu_course_assistant.person_id
           and vu_person.person_id = $person_id
           and vu_course_assistant.course_id = vu_course.course_id"

set selection [ns_db select $db $query]

set courses_assistant ""
set color [vu_toggle_row_color]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append courses_assistant [course_row $course_id $course_name $course_url $semester $color]
    set color [vu_toggle_row_color $color]
}

#---------------------------------------------
# courses for which the person is a student
#---------------------------------------------
set query "select vu_course.course_id, course_name, course_url, semester 
           from vu_course, vu_person, vu_student
           where vu_person.person_id = vu_student.person_id
           and vu_person.person_id = $person_id
           and vu_student.course_id = vu_course.course_id"

set selection [ns_db select $db $query]

set courses_student ""
set color [vu_toggle_row_color]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append courses_student [course_row_stud $person_id $course_id $course_name $course_url $semester $color]
    set color [vu_toggle_row_color $color]
}


#---------------------------------------------
# construction of the body
#---------------------------------------------

set body ""

if { $courses_responsible != "" } {
    append body "<h3>Courses for which you are responsible</h3>
                 [courses_table $courses_responsible "<th width=10%>&nbsp;<th width=10%>&nbsp;<th width=10%>&nbsp;<th width=10%>&nbsp;"]\n"
}

if { $courses_assistant != "" } {
    append body "<h3>Courses you are assisting</h3>
                 [courses_table $courses_assistant "<th width=20%>&nbsp;<th width=15%>&nbsp;<th width=15%>&nbsp;"]\n"
}

if { $courses_student != "" } {
    append body "<h3>Courses for which you are a student</h3>
                 [courses_table $courses_student "<th width=50%>&nbsp;"]\n"
}

if { ( $courses_responsible == "" ) && ( $courses_assistant == "") && ( $courses_student == "") } {
    append body "[mailto $email $name] is not responsible for any course, is not assisting any course, and is not
                 a student on any course!" 
}

vu_returnpage "$name's Workspace" $body
