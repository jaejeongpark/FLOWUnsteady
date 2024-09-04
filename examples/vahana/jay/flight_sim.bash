#!/bin/bash

# Parameters range (you can modify these ranges according to your requirements)
rpm_values=({400..600..50})    # Example RPM values
vcr_values=({5..60..5})        # Example cruise velocities (in m/s)
ttot_values=(30)       # Example total time (in seconds)

# Loop through all combinations of RPM, Vcr, and Ttot
for vcr in "${vcr_values[@]}"; do
  for rpm in "${rpm_values[@]}"; do
    for ttot in "${ttot_values[@]}"; do
      # Calculate nstep based on Nyquist rate and Bode plot
      nstep=$((10 * vcr * ttot))
      
      echo "Running simulation with Vcr=$vcr, RPM=$rpm Ttot=$ttot, Nstep=$nstep"
      # Run Julia script and wait for completion before continuing to the next simulation
      julia vahana_run.jl $vcr $rpm $ttot $nstep
    done
  done
done

echo "All simulations complete."
