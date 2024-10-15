import pydicom as dicom
import numpy as np
import pandas as pd 
import matplotlib.pylab as plt
from pydicom.data import get_testdata_files
import os
#import napari

echo_time = 0.017 #ms
magnetic_field_0 = 3 # T
alpha = -0.01 # ppm/C  tested in rat muscle at 0-40 degree celcius
gyro_mag_ratio = 267.52218708 #10^6 rad/(s*T) 

def rescale (slice,slope,intercept):
    slice = slice*slope + intercept
    return slice

def cal_phase_diff (im_pre_real,im_pre_img,im_post_real,im_post_img):
    phase_diff = np.arctan(((im_post_real*im_pre_img) - (im_pre_real*im_post_img))/
                          ((im_pre_real *im_post_real) - (im_pre_img*im_post_img)))
    phase_diff = np.nan_to_num(phase_diff)/1000
    return phase_diff

ds = np.load('./MRTI-phase-temperature-conversion/output2/all_phase.npy')
rescale_slope = np.unique(np.load('./MRTI-phase-temperature-conversion/output2/phase_rescale_slope.npy'))
rescale_int = np.unique(np.load('./MRTI-phase-temperature-conversion/output2/phase_rescale_intercept.npy'))

ds_rescale = rescale(ds,rescale_slope,rescale_int) # change unit into rad

# 0 -5 interested frame 1-2 and 3-4
image_pre_1 = ds_rescale[15:22,:,:]
image_cooldown_1 = ds_rescale[29:36,:,:]
#image_pre_2 = ds_rescale[30:40,:,:]
#image_cooldown_2 = ds_rescale[40:50,:,:]

phase_diff_1 = image_cooldown_1- image_pre_1 
# mask the outlier
#phase_diff_1[np.abs(phase_diff_1) > 3500] = 0

temp_diff_1 = phase_diff_1 / (alpha*gyro_mag_ratio*magnetic_field_0*echo_time)

fig, (ax1,ax2) = plt.subplots(1,2)

im1 = ax1.imshow(phase_diff_1[0])
cbar1 = fig.colorbar(im1, ax=ax1) 
im2 = ax2.imshow(temp_diff_1[0])
cbar2 = fig.colorbar(im2, ax=ax2)

plt.show()

with open('temp_diff.txt', 'w') as outfile:
    for slice_2d in temp_diff_1:
        np.savetxt(outfile, slice_2d)


#np.savetxt('temp_diff.csv', temp_diff_1, delimiter=',') 
#requrie napari 
#viewer = napari.Viewer()
#viewer.add_image(temp_diff_1, name='temp_diff')
#napari.run()


#ax = plt.figure().add_subplot(projection='3d')
#ax.voxels(temp_diff_1, edgecolor='k')

#plt.show()


#ds = dicom.dcmread(folder_path + "/" + "IM_0001.dcm")

       



