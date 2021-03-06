#!/usr/bin/env bash
export SAXON_CP="saxon/saxon9he.jar:saxon/xmlresolver-1.2.jar"
FAIL=0
for testfile in *.xspec; do
    xspec-master/bin/xspec.sh -catalog catalog.xml $testfile
    FAIL=$(expr $FAIL + $?)
    RESULTFILE=xspec/${testfile/.xspec/}-result.html
    test -f $RESULTFILE
    FAIL=$(expr $FAIL + $?)
    grep 'class="failed"' $RESULTFILE >/dev/null 2>&1
    test ! $? -eq 0
    FAIL=$(expr $FAIL + $?)
done
exit $FAIL
