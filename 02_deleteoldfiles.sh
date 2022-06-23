#!/bin/bash -xl

if [ $# -ne 2 ]; then
	echo " Enter the grid (sam6.5, sse2.2, ant6.5) and the run (00, 12)"
	exit 11
fi

GRID=$1
HH=$2

# Setting workdir for each area.
case $GRID in
	sam6.5)
	WORKDIR="/home/opicon/operacional/data/SAM6.5"
	;;
	sse2.2)
	WORKDIR="/home/opicon/operacional/data/SSE2.2"
	;;
	ant6.5)
	WORKDIR="/home/opicon/operacional/data/ANT6.5"
	;;
esac

# Deleting old files
rm -f ${WORKDIR}/inputdataready${HH}/ICON*
rm -f ${WORKDIR}/inputdataready${HH}/igf*
rm -f ${WORKDIR}/inputdataready${HH}/raw*
rm -f ${WORKDIR}/outputdata${HH}/out*
rm -f ${WORKDIR}/outputdata${HH}/nml*
rm -f ${WORKDIR}/outputdata${HH}/NAMELIST*
rm -f ${WORKDIR}/outputdata${HH}/icon*
rm -f ${WORKDIR}/outputdata${HH}/finish*
rm -f ${WORKDIR}/initialcond${HH}/igfff*
rm -f ${WORKDIR}/initialcond${HH}/lateral*
