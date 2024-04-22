#!/bin/sh

set -e

header='<html><head><title>%title%</title>
<style type="text/css">'

mkdir -p html

for path in `find . -name "*.md"`; do
    rel=`realpath --relative-to . $path`
    dn=`dirname $rel`

    if [ $dn != '.' ]; then
        mkdir -p html/$dn
    fi
    htmlname=`basename $rel .md`

    title=`grep '^# ' $path | sed -r 's/# //g'`
    echo $title

    # Use quotes to allow newlines.
    echo "$header" | sed -r "s/%title%/$title/g" > html/$dn/$htmlname.html
    cat tools/style.css >> html/$dn/$htmlname.html
    echo "</style></head><body>" >> html/$dn/$htmlname.html
    cat tools/page_header.html >> html/$dn/$htmlname.html
    markdown_py -x fenced_code $path >> html/$dn/$htmlname.html
    echo "</body></html>" >> html/$dn/$htmlname.html

    html=`cat html/$dn/$htmlname.html`
    echo "$html" | awk '
    BEGIN {
        extlink = "href=\"https:.*\""
        link = "href=\".*\""
    }
    # Replace internal links to Markdown documents - one per line.
    $0 ~ link && $0 !~ extlink {
        match($0, link)
        t = u = substr($0, RSTART, RLENGTH)
        gsub(".md\"", ".html\"", u)
        gsub(t, u)
        print $0
        next
    }
    $0 {
        print $0
    }' > html/$dn/$htmlname.html
done
