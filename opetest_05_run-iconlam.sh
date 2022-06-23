#! /bin/bash -xl
# ============================================================================
# Basic script for the ICON model
#
# Limited-area run initialized from and forced by ICON forecasts
#
# Region: South America
# Resolution: 6.5 km
#
# ----------------------------------------------------------------------
#
# ALT:
# 21jan22 (CT Neris) - Output 'topography_c' inserted in the main ml_varlist for comparison purposes with z_mc.
set -ex

if [ $# -ne 1 ]; then

	echo "Entre com o horario da rodada (00/12):"
	echo "Ex.: 05_run-iconlam.sh 00"
	exit 1

fi

echo "Initiating script 05..."
date


#ulimit -s unlimited
export MPI_GROUP_MAX=1024
export MPI_IB_RECV_MSGS=2048
export LIBDWD_BITMAP_TYPE=ASCII
export MPI_BUFS_PER_PROC=1024
export MPI_BUFS_PER_HOST=1024
export LIBDWD_FORCE_CONTROLWORDS=1
ulimit -s unlimited
ulimit -l unlimited
ulimit -v unlimited


HH=$1
HSTART=`cat /home/opicon/operacional/data/currentdates/icon_start_time${HH}`
HSTOP=`cat /home/opicon/operacional/data/currentdates/icon_stop_time${HH}`

# ----------------------------------------------------------------------
# SETTINGS: Input/output directories
# ----------------------------------------------------------------------

# directory where the tutorial exercise (and the input data) is located
workdir=/home/opicon/operacional/data

# base directory for ICON sources and binary:
ICONDIR=/home/opicon/operacional/binaries/iconmodel

# directory with input grids:
GRIDDIR=${workdir}/const

# directory with initial conditions
INIDIR=${workdir}/initialcond$HH

# directory with lateral boundary forcing data
LBCDIR=${workdir}/initialcond$HH

# directory with external parameter data:
EXTPARDIR=${workdir}/const

# absolute path to directory with plenty of space:
EXPDIR=${workdir}/outputdata$HH

# path to model binary, including the executable:
MODEL=${ICONDIR}/icon

# ----------------------------------------------------------------------
# copy input data: grids, external parameters
# ----------------------------------------------------------------------

# the experiment directory will be created, if not already there
if [ ! -d $EXPDIR ]; then
    mkdir -p $EXPDIR
fi
cd ${EXPDIR}


# grid files
#
# reduced radiation grid file
ln -sf ${GRIDDIR}/ICON-AS_DOM01.parent.nc lam_test_DOM01.parent.nc
#
# limited area grid
ln -sf ${GRIDDIR}/ICON-AS_DOM01.nc lam_test_DOM01.nc
#
# lateral boundary grid
ln -sf ${LBCDIR}/lateral_boundary.grid.nc .

# external parameter
#
ln -sf ${EXTPARDIR}/external_parameter_icon_ICON-AS_DOM01_tiles.nc lam_test_DOM01.extpar.nc

# initial data
#
ln -sf $INIDIR/igfff00000000.grb2 .

# files needed for radiation
#ln -sf ${ICONDIR}/data/ECHAM6_CldOptProps.nc rrtm_cldopt.nc
ln -sf ${EXTPARDIR}/ECHAM6_CldOptProps.nc rrtm_cldopt.nc
#ln -sf ${ICONDIR}/data/rrtmg_lw.nc .
ln -sf ${EXTPARDIR}/rrtmg_lw.nc .

# Dictionary for the mapping: DWD GRIB2 names <-> ICON internal names
#ln -sf ${ICONDIR}/run/ana_varnames_map_file.txt map_file.ana
ln -sf ${EXTPARDIR}/ana_varnames_map_file.txt map_file.ana

# Dictionary for the mapping: GRIB2/Netcdf input names <-> ICON internal names
ln -sf ${GRIDDIR}/map_file.latbc .

# ----------------------------------------------------------------------------
# grid namelist settings
# ----------------------------------------------------------------------------

# the grid parameters
dynamics_grid_filename="'lam_test_DOM01.nc'"
radiation_grid_filename="'lam_test_DOM01.parent.nc'"

# ----------------------------------------------------------------------------
# create ICON master namelist
# ----------------------------------------------------------------------------

cat > icon_master.namelist << EOF

! master_nml: ----------------------------------------------------------------
&master_nml
 lrestart                   =                      .FALSE.        ! .TRUE.=current experiment is resumed
/

! master_model_nml: repeated for each model ----------------------------------
&master_model_nml
 model_type                  =                          1         ! identifies which component to run (atmosphere,ocean,...)
 model_name                  =                      "ATMO"        ! character string for naming this component.
 model_namelist_filename     =              "NAMELIST_NWP"        ! file name containing the model namelists
 model_min_rank              =                          1         ! start MPI rank for this model
 model_max_rank              =                      65536         ! end MPI rank for this model
 model_inc_rank              =                          1         ! stride of MPI ranks
/

! time_nml: specification of date and time------------------------------------
&time_nml
!ini_datetime_string         =      "2021-10-25T00:00:00Z"        ! initial date and time of the simulation
 ini_datetime_string         =      "$HSTART"        ! initial date and time of the simulation
!end_datetime_string         =      "2021-10-29T00:00:00Z"        ! end date and time of the simulation
 end_datetime_string         =      "$HSTOP"        ! end date and time of the simulation
                                                                  ! example date: 2001-01-01T01:00:00Z
/
EOF

# ----------------------------------------------------------------------
# model namelists
# ----------------------------------------------------------------------


cat > NAMELIST_NWP << EOF
! parallel_nml: MPI parallelization -------------------------------------------
&parallel_nml
 nproma                      =                         10         ! loop chunk length
 p_test_run                  =                     .FALSE.        ! .TRUE. means verification run for MPI parallelization
 num_io_procs                =                          1         ! number of I/O processors
 num_restart_procs           =                          0         ! number of restart processors
 num_prefetch_proc           =                          1         ! number of processors for LBC prefetching
 iorder_sendrecv             =                          1         ! sequence of MPI send/receive calls
 proc0_shift                 =                          0         ! serves for offloading I/O to the vector hosts of the NEC Aurora
 use_omp_input               =                      .TRUE.        ! allows task parallelism for reading atmospheric input data
/

! run_nml: general switches ---------------------------------------------------
&run_nml
 ltestcase                   =                     .FALSE.        ! real case run
 num_lev                     =                         50         ! number of full levels (atm.) for each domain
 lvert_nest                  =                     .FALSE.        ! no vertical nesting
 dtime                       =                         60.        ! timestep in seconds
 ldynamics                   =                      .TRUE.        ! compute adiabatic dynamic tendencies
 ltransport                  =                      .TRUE.        ! compute large-scale tracer transport
 ntracer                     =                          5         ! number of advected tracers
 iforcing                    =                          3         ! forcing of dynamics and transport by parameterized processes
 ldass_lhn                   =                      .FALSE.       ! TRUE: latent heat nudging
 msg_level                   =                          1         ! detailed report during integration
 ltimer                      =                      .TRUE.        ! timer for monitoring the runtime of specific routines
 timers_level                =                         10         ! performance timer granularity
 check_uuid_gracefully       =                      .FALSE.       ! TRUE: give only warnings for non-matching uuids
 output                      =                        "nml"       ! main switch for enabling/disabling components of the model output
/

! diffusion_nml: horizontal (numerical) diffusion ----------------------------
&diffusion_nml
 lhdiff_vn                   =                      .TRUE.        ! diffusion on the horizontal wind field
 lhdiff_temp                 =                      .TRUE.        ! diffusion on the temperature field
 lhdiff_w                    =                      .TRUE.        ! diffusion on the vertical wind field
 hdiff_order                 =                          5         ! order of nabla operator for diffusion
 itype_vn_diffu              =                          1         ! reconstruction method used for Smagorinsky diffusion
 itype_t_diffu               =                          2         ! discretization of temperature diffusion
 hdiff_efdt_ratio            =                         24.0       ! ratio of e-folding time to time step 
 hdiff_smag_fac              =                          0.025     ! scaling factor for Smagorinsky diffusion
/

! dynamics_nml: dynamical core -----------------------------------------------
&dynamics_nml
 iequations                  =                          3         ! type of equations and prognostic variables
 idiv_method                 =                          1         ! method for divergence computation
 divavg_cntrwgt              =                          0.50      ! weight of central cell for divergence averaging
 lcoriolis                   =                      .TRUE.        ! Coriolis force
/

! extpar_nml: external data --------------------------------------------------
&extpar_nml
 itopo                       =                          1         ! topography (0:analytical)
 itype_vegetation_cycle      =                          1         ! tweaks the annual cycle of LAI
 extpar_filename             =  'lam_test_DOM01.extpar.nc'    ! filename of external parameter input file
 n_iter_smooth_topo          =                          1         ! iterations of topography smoother
 heightdiff_threshold        =                       2250.        ! height difference between neighb. grid points
 hgtdiff_max_smooth_topo     =                        750.        ! see Namelist doc
 heightdiff_threshold        =                       2250.
 read_nc_via_cdi             =                      .TRUE.
/

! initicon_nml: specify read-in of initial state ------------------------------
&initicon_nml
 init_mode                   =                          7         ! start from DWD fg with subsequent vertical remapping 
 lread_ana                   =                     .false.        ! no analysis data will be read
 ana_varnames_map_file       =              "map_file.ana"        ! Dictionary for initial data file
 dwdfg_filename              = "${INIDIR}/igfff00000000.grb2"     ! initial data filename
 ltile_coldstart             =                      .TRUE.        ! coldstart for surface tiles
 ltile_init                  =                     .FALSE.        ! set it to .TRUE. if FG data originate from run without tiles
/

! grid_nml: horizontal grid --------------------------------------------------
&grid_nml
 dynamics_grid_filename      =  ${dynamics_grid_filename}         ! array of the grid filenames for the dycore
 radiation_grid_filename     = ${radiation_grid_filename}         ! array of the grid filenames for the radiation model
 lredgrid_phys               =                      .TRUE.        ! .true.=radiation is calculated on a reduced grid
 lfeedback                   =                      .TRUE.        ! specifies if feedback to parent grid is performed
 l_limited_area              =                      .TRUE.        ! .TRUE. performs limited area run
 ifeedback_type              =                          2         ! feedback type (incremental/relaxation-based)
 start_time                  =                          0.        ! Time when a nested domain starts to be active [s]
/

! gridref_nml: grid refinement settings --------------------------------------
&gridref_nml
 denom_diffu_v               =                        150.        ! denominator for lateral boundary diffusion of velocity
/

! interpol_nml: settings for internal interpolation methods ------------------
&interpol_nml
 nudge_zone_width            =                         10         ! width of lateral boundary nudging zone
 nudge_max_coeff             =                          0.075     ! maximum relaxation coefficient for lateral boundary nudging
 support_baryctr_intp        =                     .FALSE.        ! barycentric interpolation support for output
/

! io_nml: general switches for model I/O -------------------------------------
&io_nml
 itype_pres_msl              =                          5         ! method for computation of mean sea level pressure
 itype_rh                    =                          1         ! method for computation of relative humidity
 lmask_boundary              =                      .TRUE.        ! mask out interpolation zone in output
/

! limarea_nml: settings for limited area mode ---------------------------------
&limarea_nml
 itype_latbc                 =                          1         ! 1: time-dependent lateral boundary conditions
 dtime_latbc                 =                      10800         ! time difference between 2 consecutive boundary data
 latbc_boundary_grid         =  "lateral_boundary.grid.nc"        ! Grid file defining the lateral boundary
 latbc_path                  =                 "${LBCDIR}"        ! Absolute path to boundary data
 latbc_varnames_map_file     =            "map_file.latbc"
 latbc_filename              =  "igfff<ddhhmmss>_lbc.grb2"        ! boundary data input filename
 init_latbc_from_fg          =                     .FALSE.        ! .TRUE.: take lbc for initial time from first guess
/

! lnd_nml: land scheme switches -----------------------------------------------
&lnd_nml
 ntiles                      =                          3         ! number of tiles
 nlev_snow                   =                          3         ! number of snow layers
 lmulti_snow                 =                      .FALSE.       ! .TRUE. for use of multi-layer snow model
 idiag_snowfrac              =                         20         ! type of snow-fraction diagnosis
 lsnowtile                   =                       .TRUE.       ! .TRUE.=consider snow-covered and snow-free separately
 itype_root                  =                          2         ! root density distribution
 itype_heatcond              =                          3         ! type of soil heat conductivity
 itype_lndtbl                =                          4         ! table for associating surface parameters
 itype_evsl                  =                          4         ! type of bare soil evaporation
 itype_canopy                =                          2         ! Type of canopy parameterization
 itype_snowevap              =                          3         ! Snow evap. in vegetated areas with add. variables for snow age and max. snow height
 itype_trvg                  =                          3         ! BATS scheme with add. prog. var. for integrated plant transpiration since sunrise
 cwimax_ml                   =                      5.e-4         ! scaling parameter for max. interception storage
 c_soil                      =                       1.25         ! surface area density of the evaporative soil surface
 c_soil_urb                  =                        0.5         ! same for urban areas
 lseaice                     =                      .TRUE.        ! .TRUE. for use of sea-ice model
 lprog_albsi                 =                      .TRUE.        ! prognostic seaice albedo
 llake                       =                      .TRUE.        ! .TRUE. for use of lake model
 sstice_mode                 =                          2         ! 2: SST is updated on a daily basis by climatological increments
/

! nonhydrostatic_nml: nonhydrostatic model -----------------------------------
&nonhydrostatic_nml
 iadv_rhotheta               =                          2         ! advection method for rho and rhotheta
 ivctype                     =                          2         ! type of vertical coordinate
 itime_scheme                =                          4         ! time integration scheme
 ndyn_substeps               =                          5         ! number of dynamics steps per fast-physics step
 exner_expol                 =                          0.333     ! temporal extrapolation of Exner function
 vwind_offctr                =                          0.2       ! off-centering in vertical wind solver
 damp_height                 =                      18000.0       ! height at which Rayleigh damping of vertical wind starts
 rayleigh_coeff              =                          5.0       ! Rayleigh damping coefficient
 divdamp_order               =                         24         ! order of divergence damping 
 divdamp_type                =                         32         ! type of divergence damping
 divdamp_fac                 =                          0.004     ! scaling factor for divergence damping
 l_open_ubc                  =                     .FALSE.        ! .TRUE.=use open upper boundary condition
 igradp_method               =                          3         ! discretization of horizontal pressure gradient
 l_zdiffu_t                  =                      .TRUE.        ! specifies computation of Smagorinsky temperature diffusion
 thslp_zdiffu                =                          0.02      ! slope threshold (temperature diffusion)
 thhgtd_zdiffu               =                        125.0       ! threshold of height difference (temperature diffusion)
 htop_moist_proc             =                      22500.0       ! max. height for moist physics
 hbot_qvsubstep              =                      16000.0       ! height above which QV is advected with substepping scheme
/

! nudging_nml: Parameters for the upper boundary nudging in the LAM ---------
&nudging_nml
 nudge_type                  =                          0         ! upper boundary nudging switched off
/

! nwp_phy_nml: switches for the physics schemes ------------------------------
&nwp_phy_nml
 inwp_gscp                   =                          2         ! cloud microphysics and precipitation
 inwp_convection             =                          1         ! convection
 lshallowconv_only           =                      .TRUE.        ! only shallow convection
 inwp_radiation              =                          1         ! radiation
 inwp_cldcover               =                          1         ! cloud cover scheme for radiation
 inwp_turb                   =                          1         ! vertical diffusion and transfer
 inwp_satad                  =                          1         ! saturation adjustment
 inwp_sso                    =                          1         ! subgrid scale orographic drag
 inwp_gwd                    =                          0         ! non-orographic gravity wave drag
 inwp_surface                =                          1         ! surface scheme
 latm_above_top              =                      .TRUE.        ! take into account atmosphere above model top for radiation computation
 ldetrain_conv_prec          =                      .TRUE.
 efdt_min_raylfric           =                       7200.        ! minimum e-folding time of Rayleigh friction
 itype_z0                    =                          2         ! type of roughness length data
 icapdcycl                   =                          3         ! apply CAPE modification to improve diurnalcycle over tropical land
 icpl_aero_conv              =                          1         ! coupling between autoconversion and Tegen aerosol climatology
 icpl_aero_gscp              =                          1         ! coupling between autoconversion and Tegen aerosol climatology
 icpl_o3_tp                  =                          1
 lrtm_filename               =                'rrtmg_lw.nc'       ! longwave absorption coefficients for RRTM_LW
 cldopt_filename             =             'rrtm_cldopt.nc'       ! RRTM cloud optical properties
 mu_rain                     =                         0.5        ! shap parameter in gamma distribution for rain
 rain_n0_factor              =                         0.1        ! tuning factor for intercept parameter of raindrop size distr.
 dt_rad                      =                         720.       ! time step for radiation in s
 dt_conv                     =                         120.       ! time step for convection in s (domain specific)
 dt_sso                      =                         120.       ! time step for SSO parameterization
 dt_gwd                      =                         120.       ! time step for gravity wave drag parameterization
/

! nwp_tuning_nml: additional tuning parameters ----------------------------------
&nwp_tuning_nml
 itune_albedo                =                          1         ! reduced albedo (w.r.t. MODIS data) over Sahara
 tune_gkwake                 =                        0.25
 tune_gfrcrit                =                        0.333
 tune_gkdrag                 =                        0.0
 tune_minsnowfrac            =                        0.3
 tune_box_liq_asy            =                        3.5
 tune_gust_factor            =                        7.25
 tune_sgsclifac              =                        1.0
/

! output_nml: specifies an output stream | MAIN --------------------------------------
&output_nml
 filetype                    =                          2         ! output format: 2=GRIB2, 4=NETCDFv2
 dom                         =                          1         ! write domain 1 only
 output_bounds               =          0., 432000., 10800.       ! start, end, increment
! output_bounds               =          0., 432000., 3600.       ! start, end, increment
 steps_per_file              =                          1         ! number of steps per file
 mode                        =                          1         ! 1: forecast mode (relative t-axis), 2: climate mode (absolute t-axis)
 include_last                =                     .FALSE.
 output_filename             =                    'iconlam_metarea5'
 filename_format             = '<output_filename>_${HH}_<datetime2>_<levtype_l>' ! file name base
 output_grid                =                      .TRUE.
 remap                       =                          1         ! 1: remap to REGULAR lat-lon grid
 north_pole                  =                     0,90.         ! definition of north_pole for regular (NON rotated) lat-lon grid (lon,lat)
 reg_lon_def                 =              -72.1,0.0625,-17.9
 reg_lat_def                 =              -50.0,0.0625,15.0
 !p_levels			=	20000,25000,30000,40000,50000,60000,70000,85000,90000,95000,100000 
 p_levels			=	20000.0,25000.0,30000.0,40000.0,50000.0,60000.0,70000.0,85000.0,90000.0,95000.0,100000.0 
 !p_levels			=	2000.0,2500.0,3000.0,4000.0,5000.0,6000.0,7000.0,8500.0,9000.0,9500.0,10000.0,20000.0
 pl_varlist='u', 'v', 'w', 'temp', 'rh', 'omega', 'geopot'
 ml_varlist='u', 'v', 'w', 'temp','clcl','clcm','clch','clct','ceiling','cape','fr_land',
'group:precip_vars','albdif','rh_2m','u_10m','v_10m','sp_10m','gust10','pres_sfc','pres_msl','z_mc','topography_c',
'THB_T','tmax_2m','tmin_2m','td_2m','t_2m','geopot'
/

! output_nml: specifies an output stream | VRF --------------------------------------
&output_nml
 filetype                    =                          2         ! output format: 2=GRIB2, 4=NETCDFv2
 dom                         =                          1         ! write domain 1 only
 output_bounds               =          0., 432000., 10800.       ! start, end, increment
 steps_per_file              =                          1         ! number of steps per file
 mode                        =                          1         ! 1: forecast mode (relative t-axis), 2: climate mode (absolute t-axis)
 include_last                =                     .FALSE.
 output_filename             =                    'iconlam_metarea5'
 filename_format             = '<output_filename>_${HH}_<datetime2>_<levtype_l>_vrf' ! file name base
 output_grid                =                      .TRUE.
 remap                       =                          1         ! 1: remap to REGULAR lat-lon grid
 north_pole                  =                     0,90.         ! definition of north_pole for regular (NON rotated) lat-lon grid (lon,lat)
 reg_lon_def                 =              -72.1,0.0625,-17.9
 reg_lat_def                 =              -50.0,0.0625,15.0
 ml_varlist='fr_land','group:precip_vars','u_10m','v_10m','gust10','pres_sfc','pres_msl','tmax_2m','tmin_2m','td_2m','t_2m','topography_c'
/


! meteogram_output_nml: meteogram output file ---------------------------------------------
!&meteogram_output_nml
! lmeteogram_enabled		=	.TRUE.
! n0_mtgrm			= 	0		! initial time step for meteogram output
! ninc_mtgrm			=	30		! output interval (in time steps, 30*120s = 1 hour)
! stationlist_tot		= 50.050(lat), 8.600(lon), ’Frankfurt-Flughafen’,
! stationlist_tot		=	-22.84,-43.16,'BaiaGuanabara_RJ',
!					-22.90,-43.17,'RiodeJaneiro_RJ',
!					-23.95,-46.33,'Santos_SP',
!					-32.04,-52.10,'RioGrande_RS',
!					-12.97,-38.51,'Salvador_BA',
!					-17.95,-38.70,'Abrolhos_BA',
!					-20.32,-40.34,'Vitoria_ES',
!					-05.80,-35.21,'Natal_RN',
!					-01.46,-48.50,'Belem_PA',
!					-20.50,-29.32,'IlhaTrindade'
! zprefix			=	'meteograms_metarea5'
! var_list			=	'clcl','clcm','clch','clct','ceiling','group:precip_vars',
!					'pres_msl','td_2m','t_2m','tmax_2m','tmin_2m','fr_land',
!					'rh_2m','u_10m','v_10m','gust10'
!/

! radiation_nml: radiation scheme ---------------------------------------------
&radiation_nml
 irad_o3                     =                         79         ! ozone climatology
 irad_aero                   =                          6         ! aerosols
 islope_rad                  =                          0         ! Slope correction for surface radiation
 albedo_type                 =                          2         ! type of surface albedo
 vmr_co2                     =                    390.e-06
 vmr_ch4                     =                   1800.e-09
 vmr_n2o                     =                   322.0e-09
 vmr_o2                      =                     0.20946
 vmr_cfc11                   =                    240.e-12
 vmr_cfc12                   =                    532.e-12
/

! sleve_nml: vertical level specification -------------------------------------
&sleve_nml
 min_lay_thckn               =                         20.0       ! layer thickness of lowermost layer
 top_height                  =                      30000.0       ! height of model top
 stretch_fac                 =                          0.65      ! stretching factor to vary distribution of model levels
 decay_scale_1               =                       4000.0       ! decay scale of large-scale topography component
 decay_scale_2               =                       2500.0       ! decay scale of small-scale topography component
 decay_exp                   =                          1.2       ! exponent of decay function
 flat_height                 =                      16000.0       ! height above which the coordinate surfaces are flat
/

! transport_nml: tracer transport ---------------------------------------------
&transport_nml
 ivadv_tracer                =           3, 3, 3, 3, 3, 3         ! tracer specific method to compute vertical advection
 itype_hlimit                =           3, 4, 4, 4, 4, 4         ! type of limiter for horizontal transport
 ihadv_tracer                =          52, 2, 2, 2, 2, 2         ! tracer specific method to compute horizontal advection
 llsq_svd                    =                      .TRUE.        ! use SV decomposition for least squares design matrix
/

! turbdiff_nml: turbulent diffusion -------------------------------------------
&turbdiff_nml
 tkhmin                      =                          0.5       ! scaling factor for minimum vertical diffusion coefficient
 tkmmin                      =                          0.75      ! scaling factor for minimum vertical diffusion coefficient
 pat_len                     =                        750.0       ! effective length scale of thermal surface patterns
 tur_len                     =                        300.0       ! asymptotic maximal turbulent distance
 rat_sea                     =                          7.0       ! controls laminar resistance for sea surface
 frcsmot                     =                          0.2       ! these 2 switches together apply vertical smoothing of the TKE source terms
 imode_frcsmot               =                            2       ! in the tropics (only), which reduces the moist bias in the tropical lower troposphere
 imode_tkesso                =                            2       ! mode of calculating th SSO source term for TKE production
 itype_sher                  =                            2       ! type of shear forcing used in turbulence
 ltkeshs                     =                        .TRUE.      ! include correction term for coarse grids in hor. shear production term
 ltkesso                     =                        .TRUE.      ! consider TKE-production by sub-grid SSO wakes
 a_hshr                      =                          2.0       ! length scale factor for separated horizontal shear mode
 icldm_turb                  =                            2       ! mode of cloud water representation in turbulence
 q_crit                      =                          2.0       ! critical value for normalized supersaturation
/

EOF



# ----------------------------------------------------------------------
# run the model!
# ----------------------------------------------------------------------
source /home/opicon/.bashrc

#export -f module
#export use /usr/share/modules/modulefiles/intel
#module load intel/intel_2019.5-compilers

#export LD_LIBRARY_PATH=/home/devicon/instalacao-intel2019.5/libraries/lib:/opt/intel/intel_2019.5/compilers_and_libraries_2019.5.281/linux/compiler/lib/intel64_lin:$LD_LIBRARY_PATH
#export PATH=/home/devicon/instalacao-intel2019.5/libraries/bin:$PATH
#export ECCODES_DEFINITION_PATH=$HOME/software/definitions.edzw-2.12.5-2:$HOME/software/share/eccodes/definitions
#export OMPI_MCA_btl=tcp,self,vader
#export OMP_NUM_THREADS=1



# create rank file, placing MPI ranks on PEs
#cat << EOF > /tmp/myrankfile
#rank 0=localhost slot=0
#rank 1=localhost slot=1
#rank 2=localhost slot=2
#rank 3=localhost slot=3
#rank 4=localhost slot=4
#EOF

# path to model binary, including the executable:
#/opt/intel/compilers_and_libraries_2020.4.304/linux/mpi/intel64/bin/mpirun -v `cat /home/devicon/run/hostfile.txt` np 4 $MODEL
#/home/devicon/instalacao-intel2019.5/libraries/bin/mpiexec -f /home/devicon/run/hostfile.txt -np 1152 -ppn 96 $MODEL
#/home/devicon/instalacao-intel2019.5/libraries/bin/mpiexec -np 96 $MODEL
#/home/devicon/instalacao-intel2019.5/libraries/bin/mpiexec -f /home/opicon/operacional/data/const/icon_model_nodes_tests.txt -n 1536 $MODEL
#/home/devicon/instalacao-intel2019.5/libraries/bin/mpiexec -f /home/opicon/operacional/data/const/icon_model_nodes_tests.txt -n 1440 $MODEL
#/home/devicon/instalacao-intel2019.5/libraries/bin/mpiexec -f /home/opicon/operacional/data/const/icon_model_nodes_tests.txt -n 1344 $MODEL
#/home/devicon/instalacao-intel2019.5/libraries/bin/mpiexec -f /home/opicon/operacional/data/const/icon_model_nodes_tests.txt -n 1248 $MODEL
#/home/devicon/instalacao-intel2019.5/libraries/bin/mpiexec -f /home/opicon/operacional/data/const/icon_model_nodes_tests.txt -n 1152 $MODEL
#/home/devicon/instalacao-intel2019.5/libraries/bin/mpiexec -f /home/opicon/operacional/data/const/icon_model_nodes_tests.txt -n 1056 $MODEL
#/home/devicon/instalacao-intel2019.5/libraries/bin/mpiexec -f /home/opicon/operacional/data/const/icon_model_nodes_tests.txt -n 960 $MODEL
#/home/devicon/instalacao-intel2019.5/libraries/bin/mpiexec -f /home/opicon/operacional/data/const/icon_model_nodes_tests.txt -n 864 $MODEL
#/home/devicon/instalacao-intel2019.5/libraries/bin/mpiexec -f /home/opicon/operacional/data/const/icon_model_nodes_tests.txt -n 768 $MODEL
#/home/devicon/instalacao-intel2019.5/libraries/bin/mpiexec -f /home/opicon/operacional/data/const/icon_model_nodes_tests.txt -n 672 $MODEL
#/home/devicon/instalacao-intel2019.5/libraries/bin/mpiexec -f /home/opicon/operacional/data/const/icon_model_nodes_tests.txt -n 576 $MODEL
#/home/devicon/instalacao-intel2019.5/libraries/bin/mpiexec -f /home/opicon/operacional/data/const/icon_model_nodes_tests.txt -n 480 $MODEL
/home/devicon/instalacao-intel2019.5/libraries/bin/mpiexec -f /home/opicon/operacional/data/const/icon_model_nodes_tests.txt -n 384 $MODEL

# ----------------------------------------------------------------------
date
echo "End of script 05!"
# ----------------------------------------------------------------------
