import FLOWUnsteady as uns
import FLOWUnsteady: gt, vlm, noise

sims_path = "/home/jaejeong/FLOWUnsteady"

dataset_infos = [ # (label, PWW solution, BPM solution, line style, color)
                    ("FLOWUnsteady",
                        joinpath(sims_path, "examples/vahana/JAY/vahana-example-mid-sim_vcr15_rpm1200-pww00/runcase/"),
                        joinpath(sims_path, "rotorhover-example-midhigh00-bpm-3"),
                        "-", "steelblue"),
                ]

datasets_pww = Dict()     # Stores PWW data in this dictionary
datasets_bpm = Dict()     # Stores BPM data in this dictionary

# Read datasets and stores them in dictionaries
noise.read_data(dataset_infos; datasets_pww=datasets_pww, datasets_bpm=datasets_bpm)

RPM          = 1200                  # RPM of solution
nblades      = 2                     # Number of blades
BPF          = nblades*RPM/60        # Blade passing frequency

# Make sure this grid is the same used as an observer by the aeroacoustic solution
sph_R        = 1.0                 # (m) radial distance from rotor hub
sph_nR       = 0
sph_nphi     = 0
sph_ntht     = 8                    # Number of microphones
sph_thtmin   = 0                     # (deg) first microphone's angle
sph_thtmax   = 360                   # (deg) last microphone's angle
sph_phimax   = 180
sph_rotation = [90, 0, 0]            # Rotation of grid of microphones



# Create observer grid
grid = noise.observer_sphere(sph_R, sph_nR, sph_ntht, sph_nphi;
                                thtmin=sph_thtmin, thtmax=sph_thtmax, phimax=sph_phimax,
                                rotation=sph_rotation);

# This function calculates the angle that corresponds to every microphone
pangle(i) = -180/pi*atan(gt.get_node(grid, i)[1], gt.get_node(grid, i)[2])

#=
### Pressure waveform
Here we plot the pressure waveform at some of the microphones.
*This pressure waveform includes only the tonal component*, as given by
PSU-WOPWOP.
=#


microphones  = [round(pangle(8), digits=1)]            # (deg) microphones to plot
fieldname = "pressure"

hash = Dict((round(pangle(mici), digits=1), mici) for mici in 1:sph_ntht)
# mics         = Int.((-microphones .+ 180) * sph_ntht/360 .+ 1)   # Index of every microphone
micis         = [hash[round(deg)] for deg in microphones]



read_path="/home/jaejeong/FLOWUnsteady/examples/vahana/JAY/vahana-example-mid-sim_vcr15_rpm1200-pww00/runcase/"



data = datasets_pww[read_path][fieldname]
dictionary_data = data["hs"]
time = data["field"][:,:,:,1]
total_pressure_data = data["field"][:,:,:,4]





noise.plot_pressure(dataset_infos, microphones, RPM, sph_ntht, pangle;
                                datasets_pww=datasets_pww, xlims=[0, 5])

test=noise.read_wopwopoutput("pressure",read_path="/home/jaejeong/FLOWUnsteady/rotorhover-example-midhigh00-pww-3/runcase/")
# test1 = noise.read_wopwoploading
