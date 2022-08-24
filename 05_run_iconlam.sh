#!/bin/bash -xl
#
# Script for running ICONLAM.
#
# Author: CT(T) Neris
#
#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 1 - Retrieving parameters
if [ $# -ne 2 ];then
	echo "Enter the run (00, 12) and the grid (sam6.5, sse2.2, ant6.5)!!!"
	echo 
	echo "Ex.: script 00 sam6.5"
	exit 11
fi

HH=$1
GRID=$2

echo "Initiating ipt 05..."
date

# ----------------------------------------------------------------------
# Loading date args
echo "Loading current date info..."
currdate=`cat /home/opicon/operacional/currentdates/currentdate${HH}`
hstart=`cat /home/opicon/operacional/currentdates/icon_start_time${HH}`
hstop=`cat /home/opicon/operacional/currentdates/icon_stop_time${HH}`

# ----------------------------------------------------------------------
# Loading icon binary with full path
MODEL=/home/opicon/operacional/binaries/iconmodel/icon

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 2 - Defining grid specifics vars

case $GRID in
	sam6.5)
	workdir="/home/opicon/operacional/data/SAM6.5"
	icfile="$workdir/initialcond$HH/igfff00000000.grb2"
	lbcdir="$workdir/initialcond$HH"
	lbcgrid="$workdir/initialcond$HH/lateral_boundary.grid.nc"
	localgrid="$workdir/const/grid/ICON-SAM6.5_DOM01.nc"
	extpargrid="$workdir/const/grid/external_parameter_icon_ICON-SAM6.5_DOM01_tiles.nc"
	radgrid="$workdir/const/grid/ICON-SAM6.5_DOM01.parent.nc"
	cldoptprop="$workdir/const/ECHAM6_CldOptProps.nc"
	lwabscff="$workdir/const/rrtmg_lw.nc"
	tmpl="$workdir/const/tmpl_create_icon_nml_sam6.5"
	;;
	sse2.2)
	workdir="/home/opicon/operacional/data/SSE2.2"
	icfile="$workdir/initialcond$HH/igfff00000000.grb2"
	lbcdir="$workdir/initialcond$HH"
	lbcgrid="$workdir/initialcond$HH/lateral_boundary.grid.nc"
	localgrid="$workdir/const/grid/ICON-SSE2.2_DOM01.nc"
	extpargrid="$workdir/const/grid/external_parameter_icon_ICON-SSE2.2_DOM01_tiles.nc"
	radgrid="$workdir/const/grid/ICON-SSE2.2_DOM01.parent.nc"
	cldoptprop="$workdir/const/ECHAM6_CldOptProps.nc"
	lwabscff="$workdir/const/rrtmg_lw.nc"
	tmpl="$workdir/const/tmpl_create_icon_nml_sse2.2"
	;;
	ant6.5)
	workdir="/home/opicon/operacional/data/ANT6.5"
	icfile="$workdir/initialcond$HH/igfff00000000.grb2"
	lbcdir="$workdir/initialcond$HH"
	lbcgrid="$workdir/initialcond$HH/lateral_boundary.grid.nc"
	localgrid="$workdir/const/grid/ICON-ANT6.5_DOM01.nc"
	radgrid="$workdir/const/grid/ICON-ANT6.5_DOM01.parent.nc"
	extpargrid="$workdir/const/grid/external_parameter_icon_ICON-ANT6.5_DOM01_tiles.nc"
	cldoptprop="$workdir/const/ECHAM6_CldOptProps.nc"
	lwabscff="$workdir/const/rrtmg_lw.nc"
	tmpl="$workdir/const/tmpl_create_icon_nml_ant6.5"
	;;
esac

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 3 -  Checking if all conditions to run have been met.

# absolute path to directory with plenty of space
cd ${workdir}/outputdata$HH

# ----------------------------------------------------------------------
# Checking conditions to run
nmax_attempt=360 # 360 cycles of 60s, i.e., 6h.
attempt=1
FLAG=1

while [ $FLAG -eq 1 ]; do

	echo Checking if todays lateral_boundary.grid.nc exists...
	
	if [ -f ${lbcgrid} ] && [ `date -r ${lbcgrid} "+%Y%m%d"` == $currdate ];then
		echo The ${lbcgrid} file exists and it is todays. Proceeding...
		touch ${lbcgrid}_OK
	else
		echo WARNING! The ${lbcgrid} file is NOT todays!!!
	fi

	echo Checking if todays igfff00000000.grb2 exists...

	if [ -f ${icfile} ] && [ `date -r ${icfile} "+%Y%m%d"` == $currdate ];then
		echo The ${icfile} file exists and it is todays. Proceeding...
		touch ${icfile}_OK
	else
		echo WARNING! The ${icfile} file is NOT todays!!!
	fi

	echo Checking if todays igfff00000000_lbc.grb2 exists...

	if [ -f ${lbcdir}/igfff00000000_lbc.grb2 ] && [ `date -r ${lbcdir}/igfff00000000_lbc.grb2 "+%Y%m%d"` == $currdate ];then
		echo The ${lbcdir}/igfff00000000_lbc.grb2 file exists and it is todays. Proceeding...
		touch ${lbcdir}/igfff00000000_lbc.grb2_OK
	else
		echo WARNING! The ${lbcdir}/igfff00000000_lbc.grb2 file is NOT todays!!!
	fi

	echo Checking if todays igfff00030000_lbc.grb2 exists...

	if [ -f ${lbcdir}/igfff00030000_lbc.grb2 ] && [ `date -r ${lbcdir}/igfff00030000_lbc.grb2 "+%Y%m%d"` == $currdate ];then
		echo The ${lbcdir}/igfff00030000_lbc.grb2 file exists and it is todays. Proceeding...
		touch ${lbcdir}/igfff00030000_lbc.grb2_OK
	else
		echo WARNING! The ${lbcdir}/igfff00030000_lbc.grb2 file is NOT todays!!!
	fi
	
	echo Checking if todays igfff00060000_lbc.grb2 exists...

	if [ -f ${lbcdir}/igfff00060000_lbc.grb2 ] && [ `date -r ${lbcdir}/igfff00060000_lbc.grb2 "+%Y%m%d"` == $currdate ];then
		echo The ${lbcdir}/igfff00060000_lbc.grb2 file exists and it is todays. Proceeding...
		touch ${lbcdir}/igfff00060000_lbc.grb2_OK
	else
		echo WARNING! The ${lbcdir}/igfff00060000_lbc.grb2 file is NOT todays!!!
	fi
	
	if [ -f ${lbcgrid}_OK  ] && \
	   [ -f ${icfile}_OK  ] && \
	   [ -f ${lbcdir}/igfff00000000_lbc.grb2_OK  ] && \
	   [ -f ${lbcdir}/igfff00030000_lbc.grb2_OK  ] && \
	   [ -f ${lbcdir}/igfff00060000_lbc.grb2_OK  ]
   	then
		#-------------------------------------------------------------
		# Creating script for generating NAMELIST_ICONLAM* and icon_master*
		FLAG=0

		echo All conditions have been met. Creating icon namelists...
		cat $tmpl						> raw3_$GRID
		cat raw3_$GRID | sed -e 's|HH_ARG|'$HH'|g'	> raw4_$GRID
		cat raw4_$GRID | sed -e 's|GRIDNAME_ARG|'$GRID'|g'	> raw3_$GRID
		cat raw3_$GRID | sed -e 's|DATE_ARG|'$currdate'|g'	> raw4_$GRID
		cat raw4_$GRID | sed -e 's|HSTART_ARG|'$hstart'|g' > raw3_$GRID
		cat raw3_$GRID | sed -e 's|HSTOP_ARG|'$hstop'|g'	> raw4_$GRID
		cat raw4_$GRID | sed -e 's|ICFILE_ARG|'$icfile'|g'	> raw3_$GRID
		cat raw3_$GRID | sed -e 's|LBCDIR_ARG|'$lbcdir'|g'	> raw4_$GRID
		cat raw4_$GRID | sed -e 's|LBCGRID_ARG|'$lbcgrid'|g'	> raw3_$GRID
		cat raw3_$GRID | sed -e 's|LOCALGRID_ARG|'$localgrid'|g'	> raw4_$GRID
		cat raw4_$GRID | sed -e 's|RADGRID_ARG|'$radgrid'|g'	> raw3_$GRID
		cat raw3_$GRID | sed -e 's|CLDOPTPROP_ARG|'$cldoptprop'|g'	> raw4_$GRID
		cat raw4_$GRID | sed -e 's|LWABSCFF_ARG|'$lwabscff'|g'	> raw3_$GRID
		cat raw3_$GRID | sed -e 's|EXTPAR_ARG|'$extpargrid'|g'	> raw4_$GRID

		# Renaming and running script to create NAMELISTS_ICONSUB
		echo Renaming and running script to create NAMELISTS_ICONSUB...
		mv raw4_$GRID temp_tmpl_create_icon_nml_$GRID.sh
		chmod 755 temp_tmpl_create_icon_nml_$GRID.sh

		./temp_tmpl_create_icon_nml_$GRID.sh

		# Running icon in lam mode
		/home/devicon/instalacao-intel2019.5/libraries/bin/mpiexec -f ${workdir}/const/icon_model_nodes.txt -n 672 $MODEL

		# clean-up
		#rm temp_tmpl_create_icon_nml_$GRID.sh raw3_$GRID raw4_$GRID

	else # if any condition has NOT been met
		echo WARNING! One or more conditions have NOT been met!
		echo Waiting 60s to try again...
		sleep 60

		attempt=`expr $attempt + 1`
	fi
done

date
echo "End of script 05!"
