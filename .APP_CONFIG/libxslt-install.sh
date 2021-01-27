#!/bin/bash
sed -e 's@http://cdn.docbook.org/release/xsl@https://cdn.docbook.org/release/xsl-nons@' \
    -e 's@\$Date\$@31 October 2019@' -i doc/xsltproc.xml &&
xsltproc/xsltproc --nonet doc/xsltproc.xml -o doc/xsltproc.1