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
    markdown_py -x fenced_code $path >> html/$dn/$htmlname.html
    echo "</body></html>" >> html/$dn/$htmlname.html

    html=`cat html/$dn/$htmlname.html`
    echo "$html" | awk '
    BEGIN {
        extlink = "href=\"https:.*\""
        link = "href=\".*\""
    }
    $0 ~ link && $0 !~ extlink {
        match($0, link)
        t = substr($0, RSTART, RLENGTH)
        gsub(".md\"", ".html\"", t)
        print substr($0, 1, RSTART - 1) t substr($0, RSTART + RLENGTH, length($0) - RSTART - RLENGTH + 1)
        next
    }
    $0 {
        print $0
    }' > html/$dn/$htmlname.html
done
