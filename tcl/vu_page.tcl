proc vu_button { link text } {
    return "<table border=0 cellspacing=0 cellpadding=4 bgcolor=silver>
    <td align=center><a href=\"[vu_home_url]$link\" style=\"text-decoration:none\"><font size=-1><b>$text</b></font></td></tr></table>"
}
    
proc vu_home_url {} {
    return "http://cg.itu.dk:8000/"
}

proc vu_link { link text } {
    return "<a href=\"[vu_home_url]$link\">$text</a>"
}

proc vu_navbar2 { n1 n2 } {
    return "$n1 : $n2"
}

proc vu_navbar3 { n1 n2 n3 } {
    return "$n1 : $n2 : $n3"
}

proc vu_navbar4 { n1 n2 n3 n4 } {
    return "$n1 : $n2 : $n3 : $n4"
}

proc vu_page_footer {} {
    return "<hr>
    <center>
    Copyright 2000 The IT-University of Copenhagen, All Rights Reserved. <br>
    [vu_link index.tcl Home] | <a href=\"mailto:mael@it.edu\">Contact</a> | [vu_link about.tcl About] 
    </center>
    </body>
    </html>

    "
}

# All pages begin the same with html and body tags, and a table tag
proc vu_page_begin { title } {
    return "<html><title>$title</title><body bgcolor=white>
    <table cellspacing=0 cellpadding=1 bgcolor=\"#eeeeee\" border=0 width=100%>"
}

proc vu_page { title body {navbar ""}} { 
    return "[vu_page_begin $title]
    <tr><th align=left width=70%>[vu_link index.tcl "<img border=0 src=[vu_home_url]coursegrader.png>"]
    <th align=center width=10%>[vu_button user/settings.tcl SETTINGS]
    <th align=center width=10%>[vu_button about.tcl ABOUT]  
    <th align=center width=10%>[vu_button logout.tcl LOGOUT]
    </table>
    $navbar <p>
    <h2>$title</h2>
    $body
    [vu_page_footer]
    "
}

proc vu_page_header_no_logout { title } { 
    return "[vu_page_begin $title]
    <tr><th align=left width=70%>[vu_link index.tcl "<img border=0 src=[vu_home_url]coursegrader.png>"]
    <th width=10%>&nbsp;
    <th align=center width=10%>[vu_button about.tcl ABOUT]
    <th width=10%>&nbsp;
    </table>"
}

proc vu_page_no_logout { title body {navbar ""}} { 
    return "[vu_page_header_no_logout $title]
    $navbar <p>
    <h2>$title</h2>
    $body
    [vu_page_footer]
    "
}

proc vu_page3header { title title2 {navbar ""} {admbar ""}} {
    return "[vu_page_begin $title]
    <tr>
    <th align=left width=70%>[vu_link index.tcl "<img border=0 src=[vu_home_url]coursegrader.png>"]
    <th align=center width=10%>[vu_button user/settings.tcl SETTINGS]
    <th align=center width=10%>[vu_button about.tcl ABOUT]
    <th align=center width=10%>[vu_button logout.tcl LOGOUT]
    </table><p>
    <table width=100% cellpadding=0 cellspacing=0> <tr><td>$navbar
        <td align=right>$title2
    </table> $admbar
    <h2>$title</h2>"
}

proc vu_page3 { title title2 body {navbar ""} {admbar ""}} { 
    return "[vu_page3header $title $title2 $navbar $admbar]
    $body
    [vu_page_footer]"
}

proc vu_returnpage { title body {navbar ""}} {
    ns_return 200 text/html [vu_page $title $body $navbar]
}

proc vu_returnpage_no_logout { title body {navbar ""}} {
    ns_return 200 text/html [vu_page_no_logout $title $body $navbar]
}

proc vu_returnpage_header { title db course_id body {navbar ""}} {
    set query "select course_name, course_url, semester
               from vu_course where course_id = $course_id" 
    set selection [ns_db 1row $db $query]
    set_variables_after_query

    ns_return 200 text/html [vu_page3 $title "<a href=\"$course_url\">$course_name, $semester</a>" $body $navbar]
}

proc vu_page_header { title db course_id {navbar ""}} {
    set query "select course_name, course_url, semester
               from vu_course where course_id = $course_id" 
    set selection [ns_db 1row $db $query]
    set_variables_after_query

    vu_page3header $title "<a href=\"$course_url\">$course_name, $semester</a>" $navbar
}


proc vu_barlink { title course_id tclfile text } {
    if { $title == $text } {
	return "&nbsp; $text &nbsp;"
    } else {
	return "&nbsp; <a href=\"${tclfile}?course_id=$course_id\">$text</a> &nbsp;"
    }
}

proc vu_returnpage_admheader { title db course_id body {navbar ""}} {
    set query "select course_name, course_url, semester
               from vu_course where course_id = $course_id" 
    set selection [ns_db 1row $db $query]
    set_variables_after_query
    set admbar "<center>
             \[ [vu_barlink $title $course_id "course_adm.tcl" "Profile"] 
              | [vu_barlink $title $course_id "assistants.tcl" "Assistants"] 
              | [vu_barlink $title $course_id "students.tcl" "Students"] 
              | [vu_barlink $title $course_id "problemsets.tcl" "Grading Items"] 
              | [vu_barlink $title $course_id "grading_policy_form.tcl" "Grading Policy"] 
             \]
             </center>"

    ns_return 200 text/html [vu_page3 "$title" "<a href=\"$course_url\">$course_name, $semester</a>" $body $navbar $admbar]
}

proc vu_border_table { color title body } {
    return "
     <table><tr><td>
       <table border=0 bgcolor=$color cellpadding=1 cellspacing=0 width=100%>
        <tr><td>
           <table border=0 bgcolor=white cellpadding=3 cellspacing=0 width=100%>
              <tr><td bgcolor=$color align=center> $title </td></tr>
              <tr><td> $body </tr>
           </table></td></tr>
       </table></td></tr>
     </table>"
}
