#!/usr/bin/awk -f

function trim(s) {
    gsub(" ", "", s)
    return s
}

function links(s) {
    if (match(s, link_re) != 0) {
        t = substr(s, RSTART, RLENGTH + 1)
        rest = substr(s, RSTART + RLENGTH, length(s))
        s = substr(s, 1, RSTART - 1)
        match(t, url_re)
        u = trim(substr(t, RSTART + 1, RLENGTH - 2))
        if (u !~ "https://")
            sub("\\.md", ".html", u)
        s = s "<a href=\"" u "\">"
        l = match(t, label_re)
        s = s substr(t, RSTART + 1, RLENGTH - 2) "</a>" rest
    }
    return s
}

function markup(s) {
    while (match(s, "`[^`]+`") != 0) {
        t = substr(s, RSTART + 1, RLENGTH - 2)
        rest = substr(s, RSTART + RLENGTH, length(s))
        s = substr(s, 1, RSTART - 1) "<tt>" t "</tt>" rest
    }
    return s
}

function html(s) {
    gsub("&", "\\&amp;", s)
    gsub("<", "\\&lt;", s)
    gsub(">", "\\&gt;", s)
    s = links(s)
    s = markup(s)
    return s
}

function begin_sec(s) {
    if (in_sec != s) {
        end_sec()
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

function field_positions() {
    s = $0
    i = 1
    for (n = 1; n <= NF; n++) {
        j = index(s, $n)
        s = substr(s, j)
        i += j - 1
        table_cols[n] = i

        l = length($n)
        i += l
        s = substr(s, l + 1)
    }
}

BEGIN {
    heading_re = "^(#)+( *)(.*)"
    whitespace_re = "^( )+$"
    label_re = "\\[[^]]+\\]"
    url_re = "\\([^)]+\\)"
    link_re = label_re url_re
    list_re = "^\\* "
    table_re = "^="
    table_rule_re = "^-"
    in_sec = ""
}

$0 ~ heading_re {
    n = length($1)
    print "<h" n ">" html(fields(2)) "</h" n ">"
    in_sec = ""
    next
}

$0 ~ list_re {
    begin_sec("ul")
    print "<li>" html(fields(2))
    next
}

$0 ~ table_re {
    if (in_sec != "table") {
        begin_sec("table")
        field_positions()
#        for (c in table_cols)
#            print table_cols[c]
    } else {
        end_sec("table")
    }
}

$0 && $0 !~ whitespace_re {
    if (in_sec == "table") {
        print "<tr>" html($0) "</tr>"
        next
    } else if (in_sec == "")
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