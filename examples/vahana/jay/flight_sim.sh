#!/bin/bash

# Parameters range (you can modify these ranges according to your requirements)
# rpm_values=({400..1200..100})    # Example RPM values (Range) RPM_hw
rpm_values=(800) # RPM (Single)
# vcr_values=({20..40..5})        # Example cruise velocities (in m/s)
vcr_values=(10) # Vcr (Single)

ttot_values=(60)       # Example total time (in seconds)

# Loop through all combinations of RPM, Vcr, and Ttot
for vcr in "${vcr_values[@]}"; do
  for rpm in "${rpm_values[@]}"; do
    for ttot in "${ttot_values[@]}"; do
      # Calculate nstep based on the formula: nstep = rpm/60*72*ttot
      nstep=$((rpm / 60 * 72 * ttot)) # 5 deg blade rotation on each step
      
      echo "Running simulation with Vcr=$vcr, RPM=$rpm, Ttot=$ttot, Nstep=$nstep"
      # Run Julia script and wait for completion before continuing to the next simulation
      tmux new -s "Flight_Sim_${vcr}_${rpm}_${ttot}_${nstep}" -d "julia vahana_run.jl $vcr $rpm $ttot $nstep"
    done
  done
done

echo "All simulations complete."