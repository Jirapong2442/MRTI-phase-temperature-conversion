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

ds_real = np.load('D:/HW/Y4T1/fyp/code/output/all_real.npy')
ds_img = np.load('D:/HW/Y4T1/fyp/code/outputall_img.npy')
slope_real = np.unique(np.load('D:/HW/Y4T1/fyp/code/output/real_rescale_slope.npy'))
int_real = np.unique(np.load('D:/HW/Y4T1/fyp/code/output/real_rescale_intercept.npy'))
slope_img = np.unique(np.load('D:/HW/Y4T1/fyp/code/output/img_rescale_slope.npy'))
int_img = np.unique(np.load('D:/HW/Y4T1/fyp/code/output/img_rescale_intercept.npy'))


ds_real_rescale = rescale(ds_real,slope_real,int_real) # change unit into rad
ds_img_rescale = rescale(ds_img,slope_img,int_img) # change unit into rad

# 0 -5 interested frame 1-2 and 3-4
image_pre_1_real = ds_real_rescale[10:20,:,:]
image_cooldown_1_real = ds_real_rescale[20:30,:,:]
image_pre_2_real = ds_real_rescale[30:40,:,:]
image_cooldown_2_real = ds_real_rescale[40:50,:,:]

image_pre_1_img = ds_img_rescale[10:20,:,:]
image_cooldown_1_img = ds_img_rescale[20:30,:,:]
image_pre_2_img = ds_img_rescale[30:40,:,:]
image_cooldown_2_img = ds_img_rescale[40:50,:,:]

phase_diff_1 = np.arctan(((image_cooldown_1_real*image_pre_1_img) - (image_pre_1_real*image_cooldown_1_img))/
                          ((image_pre_1_real *image_cooldown_1_real) - (image_pre_1_img*image_cooldown_1_img)))

phase_diff_1 = np.nan_to_num(phase_diff_1)/1000

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

       



