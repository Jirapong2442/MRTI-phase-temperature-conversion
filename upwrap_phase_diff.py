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

def cal_phase_diff (im_pre_real,im_pre_img,im_post_real,im_post_img):
    phase_diff = np.arctan(((im_post_real*im_pre_img) - (im_pre_real*im_post_img))/
                          ((im_pre_real *im_post_real) - (im_pre_img*im_post_img)))
    phase_diff = np.nan_to_num(phase_diff)/1000
    return phase_diff

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
image_pre_1_img = ds_img_rescale[10:20,:,:]
image_cooldown_1_img = ds_img_rescale[20:30,:,:]

image_pre_2_real = ds_real_rescale[30:40,:,:]
image_cooldown_2_real = ds_real_rescale[40:50,:,:]
image_pre_2_img = ds_img_rescale[30:40,:,:]
image_cooldown_2_img = ds_img_rescale[40:50,:,:]

phase_diff_1 = cal_phase_diff(image_pre_1_real,image_pre_1_img,image_cooldown_1_real,image_cooldown_1_img)
phase_diff_2 = cal_phase_diff(image_pre_2_real,image_pre_2_img,image_cooldown_2_real,image_cooldown_2_img)

temp_diff_1 = phase_diff_1 / (alpha*gyro_mag_ratio*magnetic_field_0*echo_time)
temp_diff_2 = phase_diff_2 / (alpha*gyro_mag_ratio*magnetic_field_0*echo_time)
#with open('MRTI-phase-temperature-conversion/output/temp.diff_1.txt', 'w') as outfile:
#    for slice_2d in temp_diff_1:
#        np.savetxt(outfile, slice_2d)


#np.savetxt('temp_diff.csv', temp_diff_1, delimiter=',') 
fig, ((ax1,ax2,ax3,ax4,ax5),(ax6,ax7,ax8,ax9,ax10)) = plt.subplots(2,5)

im1 = ax1.imshow(temp_diff_1[0])
cbar1 = fig.colorbar(im1, ax=ax1)
im2 = ax2.imshow(temp_diff_1[1])
cbar2 = fig.colorbar(im2, ax=ax2)
im3 = ax3.imshow(temp_diff_1[2])
cbar3 = fig.colorbar(im3, ax=ax3)
im4 = ax4.imshow(temp_diff_1[3])
cbar4 = fig.colorbar(im4, ax=ax4)
im5 = ax5.imshow(temp_diff_1[4])
cbar5 = fig.colorbar(im5, ax=ax5)
im6 = ax6.imshow(temp_diff_1[5])
cbar6 = fig.colorbar(im6, ax=ax6)
im7 = ax7.imshow(temp_diff_1[6])
cbar7 = fig.colorbar(im7, ax=ax7)
im8 = ax8.imshow(temp_diff_1[7])
cbar8 = fig.colorbar(im8, ax=ax8)
im9 = ax9.imshow(temp_diff_1[8])
cbar9 = fig.colorbar(im9, ax=ax9)
im10 = ax10.imshow(temp_diff_1[9])
cbar10 = fig.colorbar(im10, ax=ax10)

#plt.imshow(temp_diff_1[0])
plt.show()

#requrie napari 
#viewer = napari.Viewer()
#viewer.add_image(temp_diff_1, name='temp_diff')
#napari.run()



#ax = plt.figure().add_subplot(projection='3d')
#ax.voxels(temp_diff_1, edgecolor='k')

#plt.show()



       



