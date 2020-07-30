
set about_body "
CourseGrader is an ongoing effort to create a web-site for managing
and teaching university and college courses. <p>

<h2>What CourseGrader can do for you</h2> CourseGrader can be used
by any lecturer or other course responsible on the internet to manage
gradings of problem sets and exams for a course. CourseGrader is free
to use (see the copyright and disclaimer notice below). <p>

CourseGrader supports three kinds of users, the course
responsible, the course assistant, and the student. The <i>course
responsible</i> has the authority to manage course properties such as
the number and the names of problem sets, which students attend the
course, and which assistants are associated with the course.  <p>

The <i>course assistant</i> has the authority to grade problem
solutions that have not been locked by the course
responsible. Further, the course assistant can see grading information
for all students attending the course.<p>

Finally, the <i>student</i> can access grade information about each
problem set, including comments on a problem solution provided by the
assistants and the course responsible. The students of a course can
access grading information about themselves, only.


<h2>Contact</h2> The author of this software is <a
href=\"http://www.dina.kvl.dk/~mael/\">Martin Elsman</a>. Feel free to
<a href=\"mailto: mael@it.edu\">contact the author</a>, if you have
any questions or comments about this software. If you want to learn
how to create web-sites like this, go check out the course <a
href=\"http://www.it.edu/courses/W2\">Database-based Web-publishing</a> at the
<a href=\"http://www.it.edu/\">IT-University of Copenhagen</a>.

<h2>Copyright and Disclaimer</h2>
Copyright(c) 2000 The IT-University of Copenhagen. All rights reserved.<p>

THIS SOFTWARE IS USED ON YOUR OWN RISK.<p>

IN NO EVENT SHALL THE IT-UNIVERSITY OF COPENHAGEN BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND
ITS DOCUMENTATION, EVEN IF THE IT-UNIVERSITY OF COPENHAGEN HAS BEEN ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE.<p>

THE IT-UNIVERSITY OF COPENHAGEN SPECIFICALLY DISCLAIMS ANY WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE
PROVIDED HEREUNDER IS ON AN \"AS IS\" BASIS, AND THE IT-UNIVERSITY OF
COPENHAGEN HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
ENHANCEMENTS, OR MODIFICATIONS.

"

set about_title "About CourseGrader" 

set person_id [vu_verify_person]


if { $person_id == 0 } {
    set navbar "[vu_navbar2 [vu_link index.tcl Home] About]"
    vu_returnpage_no_logout $about_title $about_body $navbar
} else {
    set navbar "[vu_navbar2 [vu_link user/index.tcl "Your Workspace"] About]"
    vu_returnpage $about_title $about_body $navbar
}