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
if [ $# -ne 3 ];then
        echo "Enter the run (00, 12), grid (sam6.5, sse2.2, ant6.5) and "
	echo "the input data prog file (igfff00000000)!"
	echo
        echo "Ex.: script 00 sam6.5 igfff04210000"
        exit 11
fi

HH=$1
GRID=$2
INPROGF=$3

#-----------------------------------------------------------------------------
# DWD icon tools binaries
ICONTOOLS_DIR=/home/opicon/operacional/binaries/icontools
BINARY_ICONSUB=iconsub
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
	tmpl_sub="$workdir/const/tmpl_create_lbc_nml_ir_sub_sam6.5"
	tmpl="$workdir/const/tmpl_create_lbc_nml_ir_sam6.5"
	;;
	sse2.2)
	workdir="/home/opicon/operacional/data/SSE2.2"
	ingrid="$workdir/const/grid/external_parameter_icon_ICON-SSE2.2_DOM01_tiles.nc"
	localgrid="$workdir/const/grid/ICON-SSE2.2_DOM01.nc"
	datadir="$workdir/inputdataready$HH"
	indir="$workdir/inputdata${HH}"
	outdir="$workdir/initialcond$HH"
	tmpl_sub="$workdir/const/tmpl_create_lbc_nml_ir_sub_sse2.2"
	tmpl="$workdir/const/tmpl_create_lbc_nml_ir_sse2.2"
	;;
	ant6.5)
	workdir="/home/opicon/operacional/data/ANT6.5"
	ingrid="$workdir/const/grid/external_parameter_icon_ICON-ANT6.5_DOM01_tiles.nc"
	localgrid="$workdir/const/grid/ICON-ANT6.5_DOM01.nc"
	datadir="$workdir/inputdataready$HH"
	indir="$workdir/inputdata${HH}"
	outdir="$workdir/initialcond$HH"
	tmpl_sub="$workdir/const/tmpl_create_lbc_nml_ir_sub_ant6.5"
	tmpl="$workdir/const/tmpl_create_lbc_nml_ir_ant6.5"
	;;
esac

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Step 3 - Generating and running script to create:
#	NAMELIST_ICONSUB and NAMELIST_ICONREMAP_FIELDS

if ! [ -f ${outdir}/lateral_boundary ]; then

	#----------------------------------------------------------------------
	# Creating script for generating NAMELISTS_ICONSUB
	cat $tmpl_sub							> raw2_$GRID
	cat raw2_$GRID | sed -e 's|GRIDNAME_ARG|'$GRID'|g'		> raw_$GRID
	cat raw_$GRID | sed -e 's|INGRID_ARG|'$ingrid'|g'		> raw2_$GRID
	cat raw2_$GRID | sed -e 's|LOCALGRID_ARG|'$localgrid'|g'	> raw_$GRID
	cat raw_$GRID | sed -e 's|DATADIR_ARG|'$datadir'|g'		> raw2_$GRID
	cat raw2_$GRID | sed -e 's|OUTDIR_ARG|'$outdir'|g'		> raw_$GRID

	# Renaming and running script to create NAMELISTS_ICONSUB
	mv raw_$GRID temp_tmpl_create_lbc_nml_ir_sub_$GRID.sh
	chmod 755 temp_tmpl_create_lbc_nml_ir_sub_$GRID.sh

	./temp_tmpl_create_lbc_nml_ir_sub_$GRID.sh

	# Running iconsub
	/opt/intel/intel_2019.5/compilers_and_libraries_2019.5.281/linux/mpi/intel64/bin/mpirun -np 1 ${ICONTOOLS_DIR}/${BINARY_ICONSUB}  --nml NAMELIST_ICONSUB 2>&1

	#----------------------------------------------------------------------
	# Creating script for generating NAMELISTS_ICONREMAP
	cat $tmpl						> raw2_$GRID
	cat raw2_$GRID | sed -e 's|FILENAME_ARG|'$INPROGF'|g'	> raw_$GRID
	cat raw_$GRID | sed -e 's|GRIDNAME_ARG|'$GRID'|g'	> raw2_$GRID
	cat raw2_$GRID | sed -e 's|INGRID_ARG|'$ingrid'|g'	> raw_$GRID
	cat raw_$GRID | sed -e 's|LOCALGRID_ARG|'$localgrid'|g'	> raw2_$GRID
	cat raw2_$GRID | sed -e 's|DATADIR_ARG|'$datadir'|g'	> raw_$GRID
	cat raw_$GRID | sed -e 's|OUTDIR_ARG|'$outdir'|g'	> raw2_$GRID

	# Renaming and running script to create NAMELISTS_ICONSUB
	mv raw2_$GRID temp_tmpl_create_lbc_nml_ir_$GRID.sh
	chmod 755 temp_tmpl_create_lbc_nml_ir_$GRID.sh

	./temp_tmpl_create_lbc_nml_ir_$GRID.sh

	# Running iconremap
	/opt/intel/intel_2019.5/compilers_and_libraries_2019.5.281/linux/mpi/intel64/bin/mpirun -np 1 ${ICONTOOLS_DIR}/${BINARY_REMAP} -q --remap_nml NAMELIST_ICONREMAP --input_field_nml NAMELIST_ICONREMAP_FIELDS  2>&1

	# clean-up
	#rm -f temp_tmpl_create_lbc_nml_ir_sub_$GRID.sh temp_tmpl_create_lbc_nml_ir_$GRID.sh raw_$GRID raw2_$GRID ncstorage.tmp* ml.log NAMELIST_ICONREMAP NAMELIST_ICONREMAP_FIELDS

else
	#----------------------------------------------------------------------
	# Creating ONLY script for generating NAMELISTS_ICONREMAP
	cat $tmpl						> raw2_$GRID
	cat raw2_$GRID | sed -e 's|FILENAME_ARG|'$INPROGF'|g'	> raw_$GRID
	cat raw_$GRID | sed -e 's|GRIDNAME_ARG|'$GRID'|g'	> raw2_$GRID
	cat raw2_$GRID | sed -e 's|INGRID_ARG|'$ingrid'|g'	> raw_$GRID
	cat raw_$GRID | sed -e 's|LOCALGRID_ARG|'$localgrid'|g'	> raw2_$GRID
	cat raw2_$GRID | sed -e 's|DATADIR_ARG|'$datadir'|g'	> raw_$GRID
	cat raw_$GRID | sed -e 's|OUTDIR_ARG|'$outdir'|g'	> raw2_$GRID

	# Renaming and running script to create NAMELISTS_ICONSUB
	mv raw2_$GRID temp_tmpl_create_lbc_nml_ir_$GRID.sh
	chmod 755 temp_tmpl_create_lbc_nml_ir_$GRID.sh

	./temp_tmpl_create_lbc_nml_ir_$GRID.sh

	# Running iconremap
	/opt/intel/intel_2019.5/compilers_and_libraries_2019.5.281/linux/mpi/intel64/bin/mpirun -np 1 ${ICONTOOLS_DIR}/${BINARY_REMAP} -q --remap_nml NAMELIST_ICONREMAP --input_field_nml NAMELIST_ICONREMAP_FIELDS  2>&1

	# clean-up
	#rm -f temp_tmpl_create_lbc_nml_ir_$GRID.sh raw_$GRID raw2_$GRID ncstorage.tmp* ml.log NAMELIST_ICONREMAP NAMELIST_ICONREMAP_FIELDS

fi

#-----------------------------------------------------------------------------
# Removing NAMELIST_ICONSUB for the last prog
if [ $INPROGF == "igfff05000000" ];then
	echo Removing NAMELIST_ICONSUB for cleanliness..
	#rm NAMELIST_ICONSUB
fi

exit
