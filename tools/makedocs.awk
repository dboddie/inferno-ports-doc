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
        table_colw[n] = l
        i += l
        s = substr(s, l + 1)
    }
}

function seek_line(arg) {
    l = quote_line
    while (l <= quote_lines["last"]) {
        if (quote_lines[l] ~ arg)
            break
        else
            l++
    }
    return l
}

function highlight(line) {
    for (i in highlight_words)
        sub("\\y" highlight_words[i] "\\y", "<b>" highlight_words[i] "</b>", line)
    return line
}

function quote_lines_from_file() {

    print "<pre>"

    # Read and process commands until a blank line or the end of file.
    while (getline > 0) {
        if ($0 != "" && $0 !~ whitespace_re) {
            at = index($0, ":")
            if (at == 0)
                break
            arg = substr($0, at + 1)
            sub("[ \t]+", "", arg)
            if ($1 == "from:") {
                quote_line = seek_line(arg)
            } else if ($1 == "to:") {
                quote_to = seek_line(arg)
            } else if ($1 == "line:") {
                quote_line = quote_to = seek_line(arg)
            } else if ($1 == "before:") {
                quote_line = seek_line(arg) - 1
            } else if ($1 == "until:") {
                quote_to = seek_line(arg) - 1
            } else if ($1 == "highlight:") {
                for (i in highlight_words)
                    delete highlight_words[i]
                for (i = 2; i <= NF; i++)
                    highlight_words[i] = $i
            }
        } else
            break

        while (quote_line <= quote_to && quote_line > 0)
            print highlight(html(quote_lines[quote_line++]))
    }

    print "</pre>"
}

BEGIN {
    heading_re = "^(#)+( *)(.*)"
    whitespace_re = "^( \t)+$"
    label_re = "\\[[^]]+\\]"
    url_re = "\\([^)]+\\)"
    link_re = label_re url_re
    list_re = "^\\* "
    table_re = "^="
    table_rule_re = "^-"
    table_el = ""
    pre_re = "^```$"
    quote_re = "^<<<"

    in_sec = ""
    quote_file = ""
    quote_line = 0
}

$0 ~ heading_re && in_sec != "pre" {
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
        table_el = "th"
    } else {
        end_sec()
        for (i in table_cols)
            delete table_cols[i]
    }
    next
}

$0 ~ table_rule_re {
    if (in_sec == "table")
        next
}

$0 ~ pre_re {
    if (in_sec != "pre")
        begin_sec("pre")
    else
        end_sec()
    next
}

$0 ~ quote_re {
    qpath = $2

#    print "path='" qpath "'"

    if (qpath != "") {
        for (i in quote_lines)
            delete quote_lines[i]

        i = 1
        while (getline line <qpath > 0)
            quote_lines[i++] = line

        quote_file = qpath
        quote_line = 0
        quote_to = 0
        quote_lines["last"] = i
    }

    quote_lines_from_file()
    next
}

$0 && $0 !~ whitespace_re {
    if (in_sec == "table") {
        # Split the line at the original field positions.
        s = ""
        for (i in table_cols)
            s = s "<" table_el ">" html(substr($0, table_cols[i], table_colw[i])) "</" table_el ">"
        print "<tr>" s "</tr>"
        table_el = "td"
        next
    } else if (in_sec == "")
        begin_sec("p")
    print html($0)
    next
}

# Handle empty lines.
{
    if (in_sec != "" && in_sec != "pre")
        end_sec()
    print html($0)
}

END {
    end_sec()
}
