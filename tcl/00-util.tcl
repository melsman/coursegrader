proc mailto { email text } {
    return "<a href=\"mailto:$email\">$text</a>"
}

proc return_page { title body } {
    ns_return 200 text/html "<html>
    <title>$title</title><body bgcolor=white>
    $body
    <hr>
    <address>
    <a href=\"mailto:mael@it.edu\">mael@it.edu</a>
    </address>
    </body>
    </html>
    "
}

proc vp_return_page { title body } {
    ns_return 200 text/html "<html>
    <title>$title</title><body bgcolor=white>
    <table width=100% bgcolor=black border=0 cellpadding=5 cellspacing=0>
      <tr><td><font color=white size=+2><b>Video Projector Reservation System</b></font></td>
          <td align=right><img src=http://linuxlab.dk/itc_logo_black.png></td>
      </tr>
    </table>
    $body
    <hr>
    <address>
    <a href=\"mailto:mael@it.edu\">mael@it.edu</a>
    </address>
    </body>
    </html>
    "
}

proc return_page_with_title { title body } {
    return_page $title "<h2>$title</h2> $body"
}

proc valid_email { email } {
    regexp {^.+@.+\..+$} $email
}

proc vp_check_id { id } {
    if ![regexp {^[1-9][0-9]*$} $id] {
	vp_return_page "Form variable violation" "<p>
           <center>
             <h3>Form variable violation: expecting a number</h3>
           </center>"
	exit
    }
}

proc vp_check_date { date } {
    if ![regexp {^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$} $date] {
	vp_return_page "Form variable violation" "<p>
           <center>
             <h3>Form variable violation: expecting a 
             date on the form YYYY-MM-DD</h3>
           </center>"
	exit
    }
}

proc vp_check_text { text } {
    if ![regexp {^[a-zA-ZÊ¯Â∆ÿ≈ -\_\.,]+$} $text] {
	vp_return_page "Form variable violation" "<p>
           <center>
             <h3>Form variable violation: expecting text</h3>
           </center>"
	exit
    }
}

proc vp_check_email { email } {
    if ![regexp {^.+@.+\..+$} $email] {
	vp_return_page "Form variable violation" "<p>
           <center>
             <h3>Form variable violation: expecting email</h3>
           </center>"
	exit
    }
}

proc new_password_n { n } {    
   
    set res ""
    while { $n > 0 } {
      set i [randomRange 62]

        # get a random character
	if { $i < 10 } {
	    set c $i
        } elseif { $i < 10 + 26 } {
	    set c [format "%c" [expr $i + 65 - 10]]
	} else {
	    set c [format "%c" [expr $i + 97 - 36]]
	}
 
        # don't allow 0,O,o,1, and l in passwords
        
        if { $c != "0" && $c != "O" && $c != "o" && $c != "1" && $c != "l" } {
           append res $c
           incr n -1
        }
    }
    return $res
}

proc new_password {} {
    new_password_n 5
}

proc selectbox { name l } {
    set res "<select name=$name>\n"
    foreach e $l {
	set id [lindex $e 0]
	set text [lindex $e 1]
	append res " <option value=$id>$text\n"
    }
    append res "</select>"
    return $res
}
