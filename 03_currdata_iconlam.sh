#!/bin/bash
#
# Script for generating files with current data in specific
# formats.
#
# Author CT Neris, adapted from 03_ledata_corr.sh (admcosmo)
# 
# ---------------------------------------------------------
# Checking args passed
if [ $# -ne 1 ]; then
	echo "Enter reference data (00, 12)!!!!!"
	exit 11
fi

HH=$1

# ---------------------------------------------------------
# Cleaning directory
rm -f /home/opicon/operacional/currentdates/currentdate$HH
rm -f /home/opicon/operacional/currentdates/icon_start_time$HH
rm -f /home/opicon/operacional/currentdates/icon_stop_time$HH

#  Read and copy 
date +%Y%m%d > /home/opicon/operacional/currentdates/currentdate$HH
date +%Y-%m-%dT${HH}:00:00Z > /home/opicon/operacional/currentdates/icon_start_time${HH}
date --date='+5day' +%Y-%m-%dT${HH}:00:00Z > /home/opicon/operacional/currentdates/icon_stop_time${HH}

echo "Currentdate is `cat /home/opicon/operacional/currentdates/currentdate$HH`!"
