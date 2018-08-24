#!/bin/sh

# inc=`perl -we 'print join ":", "lib", @INC'`
inc="lib:deplib.skip/lib/perl5:deplib.skip/lib/perl5/x86_64-linux"

for pod in `find lib -name \*.pm`; do
    html=`echo $pod | sed 's#^#html.skip/#; s/\.pm$/.html/;'`
    mkdir -p `dirname "$html"`
    pod2html\
        --infile "$pod" --outfile "$html"\
        --htmlroot "$PWD/html.skip" --podpath "$inc"\
        --poderrors --backlink
done
