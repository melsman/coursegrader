
# return a redirect with a cookie!
ns_write "HTTP/1.0 302 Found
Location: [vu_home_url]index.tcl
MIME-Version: 1.0
Set-Cookie: vu_person_id=expired; path=/; expires=Fri, 01-Jan-1990 01:00:00 GMT
Set-Cookie: vu_password=expired; path=/; expires=Fri, 01-Jan-1990 01:00:00 GMT


You should not be seeing this!
"
