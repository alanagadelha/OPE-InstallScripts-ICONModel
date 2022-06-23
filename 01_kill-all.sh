#!/bin/bash -xl

# The script kill all the process inside each node before run Model!

#kill -9 $(ps -ef | grep icon | grep -v remap | awk '{ print $2 }')



pdsh -w node0[1-7] killall icon

