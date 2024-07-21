import FLOWUnsteady as uns
import FLOWUnsteady: vlm, vpm, gt, Im

include(joinpath(uns.examples_path, "vahana", "vahana_vehicle.jl"))
include(joinpath(uns.examples_path, "vahana", "vahana_maneuver.jl"))
include(joinpath(uns.examples_path, "vahana", "vahana_monitor.jl"))

run_name        = "vahana"                  # Name of this simulation
save_path       = "vahana-example-mid-sim_vcr30_rpm900_test"# Where to save this simulation
paraview        = true                      # Whether to visualize with Paraview

# ----------------- GEOMETRY PARAMETERS ----------------------------------------
n_factor        = 1                         # Discretization factor
add_wings       = true                      # Whether to include wings
add_rotors      = true                      # Whether to include rotors

# Reference lengths
R               = 0.75                      # (m) reference blade radius
b               = 5.86                      # (m) reference wing span
chord           = b/7.4                     # (m) reference wing chord
thickness       = 0.04*chord                # (m) reference wing thickness

# ----------------- SIMULATION PARAMETERS --------------------------------------
# Maneuver settings
Vcruise         = 30.0                      # (m/s) cruise speed (reference) 15
RPMh_w          = 900.0                     # RPM of main-wing rotors in hover (reference) 600
ttot            = 30.0                      # (s) total time to perform maneuver

use_variable_pitch = true                   # Whether to use variable pitch in cruise

# Freestream
Vinf(X,t)       = 1e-5*[1, 0, -1]           # (m/s) freestream velocity (if 0 the solvers can become unstable)
rho             = 1.225                     # (kg/m^3) air density
mu              = 1.81e-5                   # (kg/ms) air dynamic viscosity

# NOTE: Use these parameters to start and end the simulation at any arbitrary
#       point along the eVTOL maneuver (tstart=0 and tquit=ttot will simulate
#       the entire maneuver, tstart=0.20*ttot will start it at the beginning of
#       the hover->cruise transition)
tstart          = 0.00*ttot                 # (s) start simulation at this point in time
tquit           = 1.00*ttot                 # (s) end simulation at this point in time

start_kinmaneuver = true                    # If true, it starts the maneuver with the
                                            # velocity and angles of tstart.
                                            # If false, starts with velocity=0
                                            # and angles as initiated by the geometry
# ----------------- SOLVER PARAMETERS ------------------------------------------

# Aerodynamic solver
VehicleType     = uns.UVLMVehicle           # Unsteady solver
# VehicleType     = uns.QVLMVehicle         # Quasi-steady solver

# Time parameters
nsteps          = 4*540                    # Time steps for entire maneuver 4*5400
dt              = ttot/nsteps               # (s) time step

# VPM particle shedding
p_per_step      = 5                         # Sheds per time step
shed_starting   = false                     # Whether to shed starting vortex
shed_unsteady   = true                      # Whether to shed vorticity from unsteady loading
unsteady_shedcrit = 0.001                   # Shed unsteady loading whenever circulation
                                            #  fluctuates by more than this ratio

# Regularization of embedded vorticity
sigma_vlm_surf  = b/400                     # VLM-on-VPM smoothing radius
sigma_rotor_surf= R/20                      # Rotor-on-VPM smoothing radius
lambda_vpm      = 2.125                     # VPM core overlap
                                            # VPM smoothing radius
sigma_vpm_overwrite         = lambda_vpm * (2*pi*RPMh_w/60*R + Vcruise)*dt / p_per_step
sigmafactor_vpmonvlm        = 1             # Shrink particles by this factor when
                                            #  calculating VPM-on-VLM/Rotor induced velocities

# Rotor solver
vlm_rlx                     = 0.2           # VLM relaxation <-- this also applied to rotors
hubtiploss_correction       = vlm.hubtiploss_correction_prandtl # Hub and tip correction

# Wing solver: actuator surface model (ASM)
vlm_vortexsheet             = false         # Whether to spread the wing surface vorticity as a vortex sheet (activates ASM)
vlm_vortexsheet_overlap     = 2.125         # Overlap of the particles that make the vortex sheet
vlm_vortexsheet_distribution= uns.g_pressure# Distribution of the vortex sheet
# vlm_vortexsheet_sigma_tbv = thickness*chord / 100  # Size of particles in trailing bound vortices
vlm_vortexsheet_sigma_tbv   = sigma_vpm_overwrite
                                            # How many particles to preallocate for the vortex sheet
vlm_vortexsheet_maxstaticparticle = vlm_vortexsheet==false ? nothing : 6000000

# Wing solver: force calculation
KJforce_type                = "regular"     # KJ force evaluated at middle of bound vortices_vortexsheet also true)
include_trailingboundvortex = false         # Include trailing bound vortices in force calculations

include_unsteadyforce       = true          # Include unsteady force
add_unsteadyforce           = false         # Whether to add the unsteady force to Ftot or to simply output it

include_parasiticdrag       = true          # Include parasitic-drag force
add_skinfriction            = true          # If false, the parasitic drag is purely parasitic, meaning no skin friction
calc_cd_from_cl             = false         # Whether to calculate cd from cl or effective AOA
wing_polar_file             = "xf-n0012-il-500000-n5.csv"    # Airfoil polar for parasitic drag


# VPM solver
# vpm_integration = vpm.rungekutta3         # VPM temporal integration scheme
vpm_integration = vpm.euler

vpm_viscous     = vpm.Inviscid()            # VPM viscous diffusion scheme
# vpm_viscous   = vpm.CoreSpreading(-1, -1, vpm.zeta_fmm; beta=100.0, itmax=20, tol=1e-1)

# vpm_SFS       = vpm.SFS_none              # VPM LES subfilter-scale model
vpm_SFS         = vpm.DynamicSFS(vpm.Estr_fmm, vpm.pseudo3level_positive;
                                  alpha=0.999, maxC=1.0,
                                  clippings=[vpm.clipping_backscatter],
                                  controls=[vpm.control_directional, vpm.control_magnitude])

if VehicleType == uns.QVLMVehicle
    # Mute warnings regarding potential colinear vortex filaments. This is
    # needed since the quasi-steady solver will probe induced velocities at the
    # lifting line of the blade
    uns.vlm.VLMSolver._mute_warning(true)
end




# ----------------- 1) VEHICLE DEFINITION --------------------------------------
vehicle = generate_vahana_vehicle(; xfoil       = false,
                                    n_factor    = n_factor,
                                    add_wings   = add_wings,
                                    add_rotors  = add_rotors,
                                    VehicleType = VehicleType,
                                    run_name    = "vahana"
                                    )



# ------------- 2) MANEUVER DEFINITION -----------------------------------------
maneuver = generate_maneuver_vahana(; disp_plot=true, add_rotors=add_rotors)

# Plot maneuver before running the simulation
uns.plot_maneuver(maneuver)