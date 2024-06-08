#!/bin/sh

if [ ! -e "../bin/pseb.exe" ] ; then \
	echo "The main executable was not found as ../bin/pseb.exe" ; \
	exit 1 ; \
fi

../bin/pseb.exe -a -t 0 -l 10 -w 0.05 -i ../dat/pseb-test-tiny.fas
