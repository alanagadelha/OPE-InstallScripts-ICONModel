#!/bin/bash -xl
DIRSCRIPTS="/home/opicon/operacional/scripts"

${DIRSCRIPTS}/04.1_check_icon_data.sh 12 > ${DIRSCRIPTS}/logs/04.1_12_`cat /home/opicon/operacional/data/currentdates/currentdate12`.log 2>&1
${DIRSCRIPTS}/04.2_remap-init.sh 12 > ${DIRSCRIPTS}/logs/04.2_12_`cat /home/opicon/operacional/data/currentdates/currentdate12`.log 2>&1
${DIRSCRIPTS}/04.3_remap-lbc.sh 12 > ${DIRSCRIPTS}/logs/04.3_12_`cat /home/opicon/operacional/data/currentdates/currentdate12`.log 2>&1
${DIRSCRIPTS}/05_run-iconlam.sh 12 > ${DIRSCRIPTS}/logs/05_12_`cat /home/opicon/operacional/data/currentdates/currentdate12`.log 2>&1

