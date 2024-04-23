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
    #markdown_py -x fenced_code $path >> html/$dn/$htmlname.html
    awk -f tools/makedocs.awk $path >> html/$dn/$htmlname.html
    echo "</body></html>" >> html/$dn/$htmlname.html
done
