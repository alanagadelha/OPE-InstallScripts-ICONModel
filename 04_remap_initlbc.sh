#!/bin/bash -x
# Author: CT(T) Alana
# Date: 20OUT2021

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 1 - Retrieving parameters
#
if [ $# -ne 1 ];then
     echo "Enter the run HH (00Z or 12Z)!!!!!"
     exit 12
fi
#RODADA=Operacional
#AREA=$1
HH=$1

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

current_date=`cat /home/opicon/operacional/data/currentdates/currentdate${HH}`
datetimeana=${current_date}${HH}
INPUTDIR='/home/opicon/operacional/data/inputdata'
INPUTDIRREADY='/home/opicon/operacional/data/inputdataready'

########################### FUNCTIONS ################################
# Fucntion for checking ICON INPUT DATA INFO
icon_new_check()
{
if [ -s ${INPUTDIR}${HH}/icon_new.bz2 ];then

	echo "Is icon_new.bz2 there? YES!"
	echo

	# Retrieving input data INFO
	cd ${INPUTDIRREADY}${HH}
	cp ${INPUTDIR}${HH}/icon_new.bz2 ${INPUTDIRREADY}${HH}
	bunzip2 ${INPUTDIRREADY}${HH}/icon_new.bz2
	dataf=`head -1 ${INPUTDIRREADY}${HH}/icon_new`
	hh=`head -2 ${INPUTDIRREADY}${HH}/icon_new`

	if [ ${datetimeana} == ${dataf}${hh} ];then

		echo "Is icon_new.bz2 from the right date/run? YES!"
		echo
		touch ${INPUTDIRREADY}${HH}/ICONDATA_${datetimeana}_OK
	else
		echo "Is icon_new.bz2 from the right date/run? NO! Waiting 60s..."
		echo
	fi
	rm -f ${INPUTDIRREADY}${HH}/icon_new
	
else
	echo "Is icon_new.bz2 there? NO! Waiting 60s..."
	echo
	sleep 60
fi
}

# Function Input check
input_data_check()
{
infile=$1

echo "Checking the reference date of $infile..."

cp -f $infile ${INPUTDIRREADY}${HH}/
/usr/bin/bunzip2 -f ${INPUTDIRREADY}${HH}/$infile
input_refdate=`grib_ls -p dataDate ${INPUTDIRREADY}${HH}/${infile:0:13} | head -3 | tail -1`

if [ ${input_refdate} == ${current_date} ]; then

	echo "File is up-to-date and has already been copied to ${INPUTDIRREADY}${HH}!"
	touch ${INPUTDIRREADY}${HH}/ICONDATA_${infile}_OK
	FLAG=0

else
	echo "Reference date is incorrect!"
	echo "Deleting incorrect file in ${INPUTDIRREADY}${HH}..."
	rm ${INPUTDIRREADY}${HH}/${infile:0:13}
	echo "Waiting 60s to try again..."
	sleep 60

fi
}

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 3 - Checking the icon_new.bz2 file
#

c1=1
in_limit=180 # 3 hours, 60s each cycle

while $c1 -le $in_limit ;do

	icon_new_check

	if [ $counter -eq $in_limit ];then

		echo "Script waited for 3 hours, but no icon_new.bz2 arrived. Aborting..."
		exit 11
	fi

	c1=$((c1+1))
done

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 4 -  Checking if each data is current

# Sleep checking

for infile in `ls igfff*0000.bz2`; do

	c2=1
	in_limit=180 # 3 hours, 60s each cycle

	while $c2 -le $in_limit ;do

        	icon_input_check $infile

		if [ $c2 -gt $in_limit ]; then

			echo "Check aborted after 3 hours!!!! ERROR in file $infile..."
			exit 22

		fi

		c2=$((c2+1))
	done
done


date
echo "End of script 04.1!"
