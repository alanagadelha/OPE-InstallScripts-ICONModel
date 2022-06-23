#! /bin/bash -xl
#-----------------------------------------------------------------------------
# Run script template for interpolation of inital data onto 
# limited area grid
# 01/2017 : F. Prill, DWD
#
# Usage: Submit this PBS runs script with "qsub"
#        Do not forget to fill in the file name settings below!
#-----------------------------------------------------------------------------

echo "Initiating script 04.2!"
date

#export MPI_SHEPHERD=true
export MPI_GROUP_MAX=1024
export MPI_IB_RECV_MSGS=2048
export LIBDWD_BITMAP_TYPE=ASCII
export MPI_BUFS_PER_PROC=1024
export MPI_BUFS_PER_HOST=1024
export LIBDWD_FORCE_CONTROLWORDS=1

HH=$1

workdir="/home/opicon/operacional/data/SAM6.5"
current_date=`cat //home/opicon/operacional/currentdates/currentdate${HH}`
datetimeana=${current_date}${HH}
INPUTDIR="${workdir}/inputdata"
INPUTDIRREADY="${workdir}/inputdataready"

nmax_attempts=180 # 180 cycles of 60s, i.e., 3hrs
attempt=1
FLAG=1

while [ $FLAG -eq 1 ]; do

	echo "Checking initial data file..."

	if [ -e ${INPUTDIRREADY}${HH}/igfff00000000 ]; then

		echo Initial data file igfff00000000 is available. Proceeding...
		FLAG=0
	else
		echo WARNING!
		echo Initial data file igfff00000000 is NOT available yet. Waiting 60s...
		sleep 60
	fi

	if [ $attempt -gt $nmax_attempts ]; then

		echo "Check aborted after 3 hours!!!!"
		exit 22

	fi

	attempt=`expr $attempt + 1`

done


# SETTINGS: DIRECTORIES AND INPUT/OUTPUT FILE NAMES --------------------------

# directory containing DWD icon tools binaries
ICONTOOLS_DIR=/home/opicon/operacional/binaries/icontools

# file name of input grid
INGRID=$workdir/const/icon_grid_bras_n2_R03B07_20180625_tiles.nc

# file name of limited-area (output) grid
LOCALGRID=$workdir/const/ICON-AS_DOM01.nc

# directory containing data files which shall be mapped to limited-area grid
DATADIR=$workdir/inputdataready$HH
DATAFILELIST=$(find ${DATADIR}/igfff00000000)

# output directory for extracted boundary data
OUTDIR=$workdir/initialcond$HH

#-----------------------------------------------------------------------------
BINARY_REMAP=iconremap
#-----------------------------------------------------------------------------
# Remap inital data onto local (limited-area) grid
#-----------------------------------------------------------------------------

mkdir -p ${OUTDIR}

set +x
cat > NAMELIST_ICONREMAP_FIELDS << EOF_2A
&input_field_nml
 inputname      = "HHL"         
 outputname     = "z_ifc"          
 intp_method    = 3
/
EOF_2A

# NOTE: soil moisture is converted directly. To avoid unecessary artefacts 
# it is suggested to remap the soil moisture index (SMI) and then transfer 
# it back to W_SO.
for field in U V W T P QV QC QI QR QS T_G T_ICE H_ICE T_MNW_LK T_WML_LK H_ML_LK T_BOT_LK C_T_LK QV_S T_SO W_SO W_SO_ICE ALB_SEAICE EVAP_PL SMI; do
cat >> NAMELIST_ICONREMAP_FIELDS << EOF_2B
!
&input_field_nml
 inputname      = "${field}"         
 outputname     = "${field}"          
 intp_method    = 3
/
EOF_2B
done

#for field in param198.0.2; do
#cat >> NAMELIST_ICONREMAP_FIELDS << EOF_2Y
#!
#&input_field_nml
# inputname      = "${field}"
# outputname     = "${field}"
# intp_method    = 3
# loptional      = .TRUE.
#/
#EOF_2Y
#done

for field in RHO_SNOW T_SNOW W_SNOW H_SNOW W_I; do
cat >> NAMELIST_ICONREMAP_FIELDS << EOF_2C
!
&input_field_nml
 inputname      = "${field}"         
 outputname     = "${field}"
 intp_method    = 3
/
EOF_2C
done

cat >> NAMELIST_ICONREMAP_FIELDS << EOF_2D
&input_field_nml
 inputname      = "Z0"         
 outputname     = "gz0"          
 intp_method    = 3
/
&input_field_nml
 inputname      = "FR_ICE"         
 outputname     = "fr_seaice"          
 intp_method    = 3
/
&input_field_nml
 inputname      = "FRESHSNW"         
 outputname     = "freshsnow"          
 intp_method    = 3
/
EOF_2D

set -x
cat NAMELIST_ICONREMAP_FIELDS

#-----------------------------------------------------------------------------
# loop over file list:

echo ${DATAFILELIST}
for datafilename in ${DATAFILELIST} ; do

datafile="${datafilename##*/}"  # get filename without path
outdatafile=${datafile%.*}      # get filename without suffix

cat > NAMELIST_ICONREMAP << EOF_2E
&remap_nml
 in_grid_filename  = '${INGRID}'
 in_filename       = '${DATADIR}/${datafile}'
 in_type           = 2
 out_grid_filename = '${LOCALGRID}'
 out_filename      = '${OUTDIR}/${outdatafile}.grb2'
 out_type          = 2
 out_filetype      = 2
 l_have3dbuffer    = .false.
 ncstorage_file    = "ncstorage.tmp"
/
EOF_2E

/opt/intel/intel_2019.5/compilers_and_libraries_2019.5.281/linux/mpi/intel64/bin/mpirun -np 1 ${ICONTOOLS_DIR}/${BINARY_REMAP} -vvv --remap_nml NAMELIST_ICONREMAP --input_field_nml NAMELIST_ICONREMAP_FIELDS  2>&1
#/opt/intel/intel_2019.5/compilers_and_libraries_2019.5.281/linux/mpi/intel64/bin/mpirun -machine /home/opicon/operacional/data/const/icon_preproc_nodes.txt ${ICONTOOLS_DIR}/${BINARY_REMAP} -vvv --remap_nml NAMELIST_ICONREMAP --input_field_nml NAMELIST_ICONREMAP_FIELDS  2>&1
done

#-----------------------------------------------------------------------------
# clean-up
rm -f ncstorage.tmp*
rm -f nml.log  NAMELIST_SUB NAMELIST_ICONREMAP NAMELIST_ICONREMAP_FIELDS
#-----------------------------------------------------------------------------
date
echo "End of script 04.2!"
#-----------------------------------------------------------------------------
exit
#-----------------------------------------------------------------------------
