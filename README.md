# PRFS-based Magnetic Resonance Temperature Imaging
This is a simple script for the MRT algorithm that incorporates single/dual/multi-echo imaging with field drift correction. The MATLAB version of MRT is complete. 

The algorithm includes an unwrapping process with an unwrapping algorithm by Herráez [1]. The temperature difference of the Unwrapped Images at different temperatures would be calculated through complex subtraction and the PRFS equation.
Subsequently, the temperature difference of each TE would be weighted by TE and its magnitude as suggested by Odéen and Parker [2]. 

If the main magnetic field drift correction is required, the *average field drift* from all temperature pairs would be subtracted from phase change in the script. Average phase drift is derived from _mean_drift_all.m_ output. 

Two outputs, including the temperature map image, and an array of [mean temp, std temp, phase, snr] of temperature could be stored in the desired directory. 

[1] M. A. Herráez, D. R. Burton, M. J. Lalor, and M. A. Gdeisat, "Fast two-dimensional phase-unwrapping algorithm based on sorting by reliability following a noncontinuous path", Applied Optics, Vol. 41, Issue 35, pp. 7437-7444 (2002),
[2] H. Odéen and D. L. Parker, "Improved MR thermometry for laser interstitial thermotherapy," Lasers in Surgery and Medicine, vol. 51, no. 3, pp. 286–300, Jan. 2019. doi:10.1002/lsm.23049  

# Example
## Run temperature mapping
The temperature mapping function is _temp_map.m_ and the illustration of how to use is in _main.m_ 

## run visualization
The graph comparison between estimated temperature and ground truth temperature could be plotted in the _plot_line.m_ in _result_visualization_. 
