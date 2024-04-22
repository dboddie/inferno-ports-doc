#!/usr/bin/awk -f

function html(s) {
    gsub("&", "&amp;", s)
    gsub("<", "&lt;", s)
    gsub(">", "&gt;", s)
    return s
}

function begin_sec(s) {
    if (in_sec != s) {
        print "<" s ">"
        in_sec = s
    }
}

function end_sec() {
    if (in_sec != "") {
        print "</" in_sec ">"
        in_sec = ""
    }
}

function fields(n) {
    s = ""
    for (i = n; i <= NF; i++)
        s = s $i (i < NF ? OFS : "")
    return s
}

BEGIN {
    heading_re = "^(#)+( *)(.*)"
    whitespace_re = "^( )+$"
    list_re = "^\\* "
    in_sec = ""
}

$0 ~ heading_re {
    n = length($1)
    print "<h" n ">" html(fields(2)) "</h" n ">"
    #print match($0, "[^# ]+(.*)")
    in_sec = ""
    next
}

$0 ~ list_re {
    begin_sec("ul")
    print "<li>" html(fields(2))
    next
}

$0 && $0 !~ whitespace_re {
    if (in_sec == "")
        begin_sec("p")
    print html($0)
    next
}

# Handle empty lines.
{
    if (in_sec != "")
        end_sec()
    print html($0)
}

END {
    end_sec()
}
