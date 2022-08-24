#!/bin/bash -xl
#
# Script to kill all ICON process before running the model,
# including those within each node.
#
# 'pgrep' returns the PID of any EXECUTABLE containing 'iconlam'
# and 'pkill' kills the main and child processes associated with
# those PIDs, including processes within the nodes.
#
# Author: CT Neris, adaptado de 01_mata_new.sh.

# Killing any process related to the "iconlam" run.
pkill -P `pgrep iconlam`

# Killing any process with "icon" within each node used for the grid
#pdsh -w node0[1-7] killall icon # CONFIRMAR SE NÓS SERÃO IGUAIS!!!

