#!/bin/bash -xl
#
# Script for checking if each icon input file is of current date.
#
# Author: CT(T) Alana
# Date: 2021,20OUT
#
#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 1 - Retrieving parameters
if [ $# -ne 2 ];then
	echo "Enter the grid (sam6.5, sse2.2, ant6.5) and the run (00, 12)!"
	exit 11
fi

GRID=$1
HH=$2

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 2 - Defining grid specifics vars

case $GRID in
	sam6.5)
	workdir="/home/opicon/operacional/data/SAM6.5"
	;;
	sse2.2)
	workdir="/home/opicon/operacional/data/SSE2.2"
	;;
	ant6.5)
	workdir="/home/opicon/operacional/data/ANT6.5"
	;;
esac

echo "Initiating script 04.1..."
date

echo "Loading current date and other directories..."
indir="${workdir}/inputdata${HH}"
inreadydir="${workdir}/inputdataready${HH}"
current_date=`cat /home/opicon/operacional/currentdates/currentdate${HH}`
datetimeana=${current_date}${HH}

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 3 - Checking the icon_new.bz2 file
#
if ! [ -s ${indir}/icon_new.bz2 ];then
	echo "Arq. icon_new.bz2 is not there!!!"
	exit 12
fi

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 4 -  Checking if the data is arriving  
#
cd ${inreadydir}
cp -f ${indir}/icon_new.bz2 .
bunzip2 -f icon_new.bz2
dataf=`head -n1 icon_new`
hh=`head -n2 icon_new > raw.txt`
echo "$raw.txt" 
progf=`tail -n1 raw.txt`
if [ ${datetimeana} == ${dataf}${hh} ];then
   echo `date` - The data reception has already started > ${inreadydir}/ICONDATA_${datetimeana}
fi
rm -f icon_new.bz2 icon_new # Acho que o icon_new.bz2 nao precisa deletar

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
#Step 5 -  Checking if the data is current

nmax_attempt=180 # 180 cycles of 60s, i.e., 3hrs
cd ${indir}

for infile in `ls igfff*0000.bz2`; do

	attempt=1
	FLAG=1

	while [ $FLAG -eq 1 ]; do

		echo "Checking the reference date of $infile..."

		cp -f $infile ${inreadydir}/
		/usr/bin/bunzip2 -f ${inreadydir}/$infile
		input_refdate=`grib_ls -p dataDate ${inreadydir}/${infile:0:13} | head -3 | tail -1`

		if [ ${input_refdate} == ${current_date} ]; then

			echo "File is up-to-date and has already been copied to ${inreadydir}!"
			FLAG=0

		else
			echo "Reference date is incorrect!"
			echo "Deleting incorrect file in ${inreadydir}..."
			rm ${inreadydir}/${infile:0:13}
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
