import pydicom as dicom
import numpy as np
import pandas as pd 
import matplotlib.pylab as plt
from pydicom.data import get_testdata_files
import os
import napari

echo_time = 0.017 #ms
magnetic_field_0 = 3 # T
alpha = -0.009 # ppm/C  tested in rat muscle at 0-40 degree celcius
gyro_mag_ratio = 2.6752218708 #10^8 rad/(s*T)

def rescale (slice,slope,intercept):
    slice = slice*slope + intercept
    return slice

ds = np.load('allphase.npy')
rescale_slope = np.unique(np.load('all_rescale_slope.npy'))
rescale_int = np.unique(np.load('all_rescale_intercept.npy'))

ds_rescale = rescale(ds,rescale_slope,rescale_int)/1000 # change unit into rad

# 0 -5 interested frame 1-2 and 3-4
image_pre_1 = ds_rescale[10:20,:,:]
image_cooldown_1 = ds_rescale[20:30,:,:]
image_pre_2 = ds_rescale[30:40,:,:]
image_cooldown_2 = ds_rescale[40:50,:,:]

phase_diff_1 = image_cooldown_1- image_pre_1 
phase_diff_2 = image_cooldown_2 - image_pre_2

temp_diff_1 = phase_diff_1 / (alpha*gyro_mag_ratio*magnetic_field_0*echo_time)
with open('temp_diff.txt', 'w') as outfile:
    for slice_2d in temp_diff_1:
        np.savetxt(outfile, slice_2d)


#np.savetxt('temp_diff.csv', temp_diff_1, delimiter=',') 
#requrie napari 
viewer = napari.Viewer()
viewer.add_image(temp_diff_1, name='temp_diff')
napari.run()


#ax = plt.figure().add_subplot(projection='3d')
#ax.voxels(temp_diff_1, edgecolor='k')

#plt.show()


#ds = dicom.dcmread(folder_path + "/" + "IM_0001.dcm")

       



