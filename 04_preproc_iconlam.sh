#!/bin/bash -xl
#
# Script for checking if each icon input file is of current date
# and generating initial and latbc conditions for ICONLAM
#
# Author: CT(T) Neris
#
#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 1 - Retrieving parameters
if [ $# -ne 4 ];then
	echo "Enter the run (00, 12), grid (sam6.5, sse2.2, ant6.5), initial and final prog!"
	echo "script 00 sam6.5 00 120"
	exit 11
fi

HH=$1
GRID=$2
IPROG=$3
FPROG=$4

# ----------------------------------------------------------------------
# Loading date args and scripts path
echo "Loading current date info..."
currdate=`cat /home/opicon/operacional/currentdates/currentdate${HH}`
datetimeana=${currdate}${HH}
scriptsdir="/home/opicon/operacional/scripts"

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 2 - Defining grid specifics vars

case $GRID in
	sam6.5)
	workdir="/home/opicon/operacional/data/SAM6.5"
	datadir="$workdir/inputdataready$HH"
	indir="$workdir/inputdata${HH}"
	;;
	sse2.2)
	workdir="/home/opicon/operacional/data/SSE2.2"
	datadir="$workdir/inputdataready$HH"
	indir="$workdir/inputdata${HH}"
	;;
	ant6.5)
	workdir="/home/opicon/operacional/data/ANT6.5"
	datadir="$workdir/inputdataready$HH"
	indir="$workdir/inputdata${HH}"
	;;
esac

echo "Initiating script 04.1..."
date

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 3 -  Checking if the data is current

cd ${datadir}

nmax_attempt=180 # 180 cycles of 60s, i.e., 3hrs

# Checking icon_new
attempt=1
FLAG=1

while [ $FLAG -eq 1 ]; do

	echo Checking icon_new date/run...

	# Copying initial file to local dir
	cp -f ${indir}/icon_new.bz2 ${datadir}/

	# Checking if the data is of current date
	bunzip2 -f icon_new.bz2
	dataf=`head -1 icon_new`
	run=`head -2 icon_new | tail -1`

	if [ ${dataf}${run} == ${datetimeana} ];then
		echo The data reception has already started.
		echo Proceeding to initial/boundary data check...
		echo `date` - The data reception has already started > ${datadir}/ICONDATA_${datetimeana}
		FLAG=0
	else
		echo "Reference date/run is incorrect!"
		echo "Deleting incorrect file in ${datadir}..."
		rm -f ${datadir}/icon_new
		echo "Waiting 60s to try again..."
		sleep 60
		attempt=`expr $attempt + 1`
	fi

	if [ $attempt -gt $nmax_attempt ]; then
		echo "ERROR! icon_new check aborted after 3 hours!!!!"
		exit 22
	fi
done

# Checking initial/boundary data

for prog in `seq $IPROG 3 $FPROG` ; do # loop progs

	attempt=1
	FLAG=1

	# Writting input file name
	dd=$(printf "%02d" `expr $prog / 24`) # sets 2 digs day
	hh=$(printf "%02d" `expr $prog % 24`) # sets 2 digs hour
	filen="igfff${dd}${hh}0000"

	while [ $FLAG -eq 1 ]; do # loop tries

		echo "Checking flag ${datadir}/${filen}_${currdate}_OK..."

		if [ -f ${datadir}/${filen}_${currdate}_OK ];then
			echo "Flag ${datadir}/${filen}_${currdate}_OK found!"
			echo "Proceeding to running preproc..."
			FLAG=0

			# Running scripts
			if [ $filen == "igfff00000000" ];then
				echo "Running iconremap for IC file $filen..."
				${scriptsdir}/04.1_create_ic.sh $HH $GRID # Test with "&"!!

				echo "Running iconsub and/or iconremap for LBC file $filen..."
				${scriptsdir}/04.2_create_lbc.sh $HH $GRID ${filen}

			else
				echo "Running ONLY iconremap for LBC file $filen..."
				${scriptsdir}/04.2_create_lbc.sh $HH $GRID ${filen}
			fi
		else
			echo "Checking the reference date of $filen..."

			cp -f $indir/${filen}.bz2 ${datadir}/
			/usr/bin/bunzip2 -f ${datadir}/${filen}.bz2
			input_refdate=`grib_ls -p dataDate ${datadir}/${filen} | head -3 | tail -1`

			if [ ${input_refdate} == ${currdate} ]; then

				echo "File $filen is up-to-date and has already been copied to ${datadir}!"
				echo "Creating flag in ${datadir}/${filen}..."
				touch ${datadir}/${filen}_${currdate}_OK
			else
				echo "Reference date is incorrect!"
				echo "Deleting incorrect file in ${datadir}..."
				rm ${datadir}/${filen}
				echo "Waiting 60s to try again..."
				sleep 60
				attempt=`expr $attempt + 1`
			fi

			if [ $attempt -gt $nmax_attempt ]; then
				echo "Check aborted after 3 hours!!!!"
				exit 22
			fi
		fi

	done # loop tries

done # loop progs

date
echo "End of script 04!"
