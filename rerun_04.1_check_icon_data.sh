#!/bin/bash -xl
#
# Author: CT(T) Alana
# Date: 2021,20OUT
#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 1 - Retrieving parameters
#
if [ $# -ne 2 ];then
	echo "Type in HH (00Z ou 12Z) and the date (yyyymmdd)!!!!!"
     exit 12
fi
#RODADA=Operacional
#AREA=$1
HH=$1
DATE=$2

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 2 - Define areas
#
#case $AREA in
#met)
#AREA1=metarea5
#;;
#ant)
#AREA1=antartica
#;;
#esac

echo "Initiating script 04.1..."
date

current_date=$DATE
datetimeana=${current_date}${HH}
INPUTDIR='/home/opicon/operacional/data/rerun_inputdata'
INPUTDIRREADY='/home/opicon/operacional/data/rerun_inputdataready'

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 3 - Checking the icon_new.bz2 file
#
#if ! [ -s ${ICONDIR}/${AREA}_${HH}/icon_new.bz2 ];then
if ! [ -s ${INPUTDIR}${HH}/icon_new.bz2 ];then
   echo "Arq. icon_new.bz2 is not there!!!"
   exit 12
fi
#if [ -s ${INPUTDIRREADY}${HH}/ICONDATA_${datetimeana} ];then
#   echo "Flag is NOT ready!!!"
#   exit 12
#fi
#
#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 4 -  Checking if the data is arriving  
#
cd ${INPUTDIRREADY}${HH}
cp -f ${INPUTDIR}${HH}/icon_new.bz2 .
bunzip2 -f icon_new.bz2
dataf=`head -n1 icon_new`
hh=`head -n2 icon_new > raw.txt`
echo "$raw.txt" 
progf=`tail -n1 raw.txt`
if [ ${datetimeana} == ${dataf}${hh} ];then
   echo `date` - The data reception has already started > ${INPUTDIRREADY}${HH}/ICONDATA_${datetimeana}
fi
rm -f icon_new.bz2 icon_new # Acho que o icon_new.bz2 nao precisa deletar

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
#Step 5 -  Checking if the data is current

nmax_attempt=180 # 180 cycles of 60s, i.e., 3hrs
cd ${INPUTDIR}${HH}

for infile in `ls igfff*0000.bz2`; do

	attempt=1
	FLAG=1

	while [ $FLAG -eq 1 ]; do

		echo "Checking the reference date of $infile..."

		cp -f $infile ${INPUTDIRREADY}${HH}/
		/usr/bin/bunzip2 -f ${INPUTDIRREADY}${HH}/$infile
		#input_refdate=`/home/devicon/instalacao-gcc7.5.0/libraries/bin/cdo -sinfov ${INPUTDIRREADY}${HH}/${infile:0:13} | grep RefTime | awk {'print $3'}`
		input_refdate=`grib_ls -p dataDate ${INPUTDIRREADY}${HH}/${infile:0:13} | head -3 | tail -1`

		if [ ${input_refdate} == ${current_date} ]; then

			echo "File is up-to-date and has already been copied to ${INPUTDIRREADY}${HH}!"
			FLAG=0

		else
			echo "Reference date is incorrect!"
			echo "Deleting incorrect file in ${INPUTDIRREADY}${HH}..."
			rm ${INPUTDIRREADY}${HH}/${infile:0:13}
			echo "Waiting 60s to try again..."
			sleep 60

		fi

		if [ $attempt -gt $nmax_attempt ]; then

			echo "Check aborted after 3 hours!!!!"
			exit 22

		fi

		attempt=`expr $attempt + 1`

	done

done

date
echo "End of script 04.1!"
