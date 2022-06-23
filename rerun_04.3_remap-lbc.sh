#! /bin/bash -xl
#-----------------------------------------------------------------------------
#PBS -q xc_norm_h
#PBS -l select=4:ompthreads=4
#PBS -j oe
#PBS -l place=scatter
#PBS -l walltime=00:45:00
#-----------------------------------------------------------------------------


#-----------------------------------------------------------------------------
# Run script template for creation of lateral boundary data
# 01/2017 : F. Prill, DWD
#
# Usage: Submit this PBS runs script with "qsub"
#        Do not forget to fill in the file name settings below!
#-----------------------------------------------------------------------------

if [ $# -ne 1 ]; then

        echo "Entre com o horario da rodada (00/12):"
        echo "Ex.: [script] 00"
        exit 1

fi

echo "Initiating script 04.3..."
date

export MPI_GROUP_MAX=1024
export MPI_IB_RECV_MSGS=2048
export LIBDWD_BITMAP_TYPE=ASCII
export MPI_BUFS_PER_PROC=1024
export MPI_BUFS_PER_HOST=1024
export LIBDWD_FORCE_CONTROLWORDS=1

HH=$1

# SETTINGS: DIRECTORIES AND INPUT/OUTPUT FILE NAMES --------------------------
DATABASE_DIR=/home/opicon/operacional

# directory containing DWD icon tools binaries
ICONTOOLS_DIR=/home/opicon/operacional/binaries/icontools

# file name of input grid
INGRID=/home/opicon/operacional/data/const/icon_grid_bras_n2_R03B07_20180625_tiles.nc

# file name of limited-area (output) grid
LOCALGRID=/home/opicon/operacional/data/const/ICON-AS_DOM01.nc

# directory containing data files which shall be mapped to nudging zone
DATADIR=/home/opicon/operacional/data/rerun_inputdataready$HH
DATAFILELIST=$(find ${DATADIR}/igff*0)

# output directory for extracted boundary data
OUTDIR=/home/opicon/operacional/data/rerun_initialcond$HH


#-----------------------------------------------------------------------------

BINARY_ICONSUB=iconsub
BINARY_REMAP=iconremap

# grid file defining the lateral boundary
AUXGRID="lateral_boundary"


#-----------------------------------------------------------------------------
# PART I: Create auxiliary grid file which contains only the cells of the 
#         boundary zone.
#-----------------------------------------------------------------------------


mkdir -p ${OUTDIR}
cd ${PBS_O_WORKDIR}

cat > NAMELIST_ICONSUB << EOF_1
&iconsub_nml
  grid_filename    = '${LOCALGRID}',
  output_type      = 4,
  lwrite_grid      = .TRUE.,
/
&subarea_nml
  ORDER            = "${OUTDIR}/${AUXGRID}",
  grf_info_file    = '${LOCALGRID}',
  min_refin_c_ctrl = 1
  max_refin_c_ctrl = 14
/
EOF_1

/opt/intel/intel_2019.5/compilers_and_libraries_2019.5.281/linux/mpi/intel64/bin/mpirun -np 1 ${ICONTOOLS_DIR}/${BINARY_ICONSUB}  --nml NAMELIST_ICONSUB 2>&1
#/opt/intel/intel_2019.5/compilers_and_libraries_2019.5.281/linux/mpi/intel64/bin/mpirun -n 2 -ppn 1 -f /home/opicon/operacional/data/const/icon_preproc_nodes.txt ${ICONTOOLS_DIR}/${BINARY_ICONSUB}  --nml NAMELIST_ICONSUB 2>&1



#-----------------------------------------------------------------------------
# PART II: Extract boundary data
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
# preparations:

rm -f ncstorage.tmp*
set +x
cat > NAMELIST_ICONREMAP_FIELDS << EOF_2A
&input_field_nml
 inputname      = "HHL"         
 outputname     = "z_ifc"          
 intp_method    = 3
 loptional      = .TRUE.
/
EOF_2A

# Alternative forcing dataset:
# U V W T P QV QC QI QR QS

for field in U V W T P QV QC QI QR QS ; do
cat >> NAMELIST_ICONREMAP_FIELDS << EOF_2B
!
&input_field_nml
 inputname      = "${field}"         
 outputname     = "${field}"          
 intp_method    = 3
/
EOF_2B
done
set -x


#-----------------------------------------------------------------------------
# loop over file list:

echo ${DATAFILELIST}
for datafilename in ${DATAFILELIST} ; do

datafile="${datafilename##*/}"  # get filename without path
echo datafile = $datafile
outdatafile=${datafile%.*}      # get filename without suffix
echo outdatafile = $outdatafile

cat > NAMELIST_ICONREMAP << EOF_2C
&remap_nml
 in_grid_filename  = '${INGRID}'
 in_filename       = '${DATADIR}/${datafile}'
 in_type           = 2
 out_grid_filename = '${OUTDIR}/${AUXGRID}.grid.nc'
 out_filename      = '${OUTDIR}/${outdatafile}_lbc.grb2'
 out_type          = 2
 out_filetype      = 2
 l_have3dbuffer    = .false.
 ncstorage_file    = "ncstorage.tmp"
/
EOF_2C

/opt/intel/intel_2019.5/compilers_and_libraries_2019.5.281/linux/mpi/intel64/bin/mpirun -np 1 ${ICONTOOLS_DIR}/${BINARY_REMAP} -q \
            --remap_nml NAMELIST_ICONREMAP                                  \
            --input_field_nml NAMELIST_ICONREMAP_FIELDS 2>&1

done

#-----------------------------------------------------------------------------
# clean-up

rm -f ncstorage.tmp*
rm -f nml.log  NAMELIST_ICONSUB NAMELIST_ICONREMAP NAMELIST_ICONREMAP_FIELDS

#-----------------------------------------------------------------------------

date
echo "End of script 04.3!"

#-----------------------------------------------------------------------------
exit
#-----------------------------------------------------------------------------

