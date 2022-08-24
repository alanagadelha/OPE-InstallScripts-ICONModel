#!/bin/bash -xl
#
# Script for creating the NAMELIST_ICONREMAP and 
# NAMELIST_ICONREMAP_FIELDS files for the analysis data.
#
# Author: CT(T) Neris
# 
#
#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 1 - Retrieving parameters
if [ $# -ne 2 ];then
        echo "Enter the run (00, 12) and grid (sam6.5, sse2.2, ant6.5)!"
        echo "script 00 sam6.5"
        exit 11
fi

HH=$1
GRID=$2

# Analysis file is always the same, switch if it ever changes!
icfile="igfff00000000"

#-----------------------------------------------------------------------------
# DWD icon tools binaries
ICONTOOLS_DIR=/home/opicon/operacional/binaries/icontools
BINARY_REMAP=iconremap

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 2 - Defining grid specifics vars

case $GRID in
	sam6.5)
	workdir="/home/opicon/operacional/data/SAM6.5"
	ingrid="$workdir/const/grid/icon_grid_bras_n2_R03B07_20180625_tiles.nc"
	localgrid="$workdir/const/grid/ICON-SAM6.5_DOM01.nc"
	datadir="$workdir/inputdataready$HH"
	indir="$workdir/inputdata${HH}"
	outdir="$workdir/initialcond$HH"
	tmpl="$workdir/const/tmpl_create_ic_nml_ir_sam6.5"
	;;
	sse2.2)
	workdir="/home/opicon/operacional/data/SSE2.2"
	ingrid="$workdir/const/grid/external_parameter_icon_ICON-SSE2.2_DOM01_tiles.nc"
	localgrid="$workdir/const/grid/ICON-SSE2.2_DOM01.nc"
	datadir="$workdir/inputdataready$HH"
	indir="$workdir/inputdata${HH}"
	outdir="$workdir/initialcond$HH"
	tmpl="$workdir/const/tmpl_create_ic_nml_ir_sse2.2"
	;;
	ant6.5)
	workdir="/home/opicon/operacional/data/ANT6.5"
	ingrid="$workdir/const/grid/external_parameter_icon_ICON-ANT6.5_DOM01_tiles.nc"
	localgrid="$workdir/const/grid/ICON-ANT6.5_DOM01.nc"
	datadir="$workdir/inputdataready$HH"
	indir="$workdir/inputdata${HH}"
	outdir="$workdir/initialcond$HH"
	tmpl="$workdir/const/tmpl_create_ic_nml_ir_ant6.5"
	;;
esac

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 3 - Generating and running script to create NAMELISTS_ICONREMAP

cat $tmpl							> raw2_$GRID
cat raw2_$GRID | sed -e 's|GRIDNAME_ARG|'$GRID'|g'		> raw_$GRID
cat raw_$GRID | sed -e 's|INGRID_ARG|'$ingrid'|g'		> raw2_$GRID
cat raw2_$GRID | sed -e 's|LOCALGRID_ARG|'$localgrid'|g'	> raw_$GRID
cat raw_$GRID | sed -e 's|DATADIR_ARG|'$datadir'|g'		> raw2_$GRID
cat raw2_$GRID | sed -e 's|ICFILE_ARG|'$icfile'|g'		> raw_$GRID
cat raw_$GRID | sed -e 's|OUTDIR_ARG|'$outdir'|g'		> raw2_$GRID

# Renaming and running script to create NAMELISTS_ICONREMAP
mv raw2_$GRID temp_tmpl_create_ic_nml_ir_$GRID.sh
chmod 755 temp_tmpl_create_ic_nml_ir_$GRID.sh

./temp_tmpl_create_ic_nml_ir_$GRID.sh

# Running iconremap
/opt/intel/intel_2019.5/compilers_and_libraries_2019.5.281/linux/mpi/intel64/bin/mpirun -np 1 ${ICONTOOLS_DIR}/${BINARY_REMAP} -vvv --remap_nml NAMELIST_ICONREMAP --input_field_nml NAMELIST_ICONREMAP_FIELDS  2>&1

#-----------------------------------------------------------------------------
# clean-up
#rm -f temp_*.sh raw_$GRID raw2_$GRID ncstorage.tmp* ml.log NAMELIST_ICONREMAP NAMELIST_ICONREMAP_FIELDS
#-----------------------------------------------------------------------------
date
echo "End of script 04.1!"
#-----------------------------------------------------------------------------
exit
