#!/usr/bin/env bash

for i in 1 2 3 4 5 6 7
do
	xvfb-run ~/flashplayerdebugger bin/buddy.swf
	test $? -eq 0 && exit 0 
done
exit 1
