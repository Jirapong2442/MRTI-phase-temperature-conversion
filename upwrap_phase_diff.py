import pydicom as dicom
import numpy as np
import pandas as pd 
import matplotlib.pylab as plt
from pydicom.data import get_testdata_files
import cv2
from rembg import remove #doesnt work with input image = removed the whole image, output image = unit is not uint16
from scipy.stats import norm

echo_time = 0.017 #ms
magnetic_field_0 = 3 # T
alpha = -0.009 # ppm/C  tested in rat muscle at 0-40 degree celcius
gyro_mag_ratio = 267.52218708 #10^8 rad/(s*T)

# how to broadcast into the whole image
def rescale (slice,all_slope,all_intercept):
    out_slice = slice.astype(np.float64)
    for index in range(all_slope.shape[0]):
        out_slice[index] = slice[index]*all_slope[index] + all_intercept[index]
    return out_slice/1000

def cal_phase_diff (im_pre_real,im_pre_img,im_post_real,im_post_img):
    phase_diff = np.arctan(((im_post_real*im_pre_img) - (im_pre_real*im_post_img))/
                          ((im_pre_real *im_post_real) + (im_pre_img*im_post_img)))
    phase_diff = np.nan_to_num(phase_diff)
    return phase_diff

def normalize(phase_image,sigma):
    adjusted_phase = np.zeros(phase_image.shape)

    for index in range(phase_image.shape[0]):
        mu, std = norm.fit(phase_image[index])
        adjusted_phase[index] = np.where( np.abs((phase_image[index]-mu)/std) <= sigma, phase_image[index] , 0)

    return adjusted_phase

ds_real = np.load('D:/HW/Y4T1/fyp/git/MRTI-phase-temperature-conversion/output2/all_real.npy')
ds_img = np.load('D:/HW/Y4T1/fyp/git/MRTI-phase-temperature-conversion/output2/all_img.npy')
slope_real = np.load('D:/HW/Y4T1/fyp/git/MRTI-phase-temperature-conversion/output2/real_rescale_slope.npy')
int_real = np.load('D:/HW/Y4T1/fyp/git/MRTI-phase-temperature-conversion/output2/real_rescale_intercept.npy')
slope_img = np.load('D:/HW/Y4T1/fyp/git/MRTI-phase-temperature-conversion/output2/img_rescale_slope.npy')
int_img = np.load('D:/HW/Y4T1/fyp/git/MRTI-phase-temperature-conversion/output2/img_rescale_intercept.npy')

ds_phase = np.load('D:/HW/Y4T1/fyp/git/MRTI-phase-temperature-conversion/output2/all_phase.npy')
slope_phase = np.load('D:/HW/Y4T1/fyp/git/MRTI-phase-temperature-conversion/output2/phase_rescale_slope.npy')
int_phase = np.load('D:/HW/Y4T1/fyp/git/MRTI-phase-temperature-conversion/output2/phase_rescale_intercept.npy')

ds_real_rescale = rescale(ds_real,slope_real,int_real) # change unit into rad
ds_img_rescale = rescale(ds_img,slope_img,int_img) # change unit into rad
ds_phase_rescale = rescale(ds_phase,slope_phase,int_phase)

# temp 58-54
image_pre_1_real = ds_real_rescale[0:7,:,:]
image_cooldown_1_real = ds_real_rescale[7:14,:,:]
image_pre_1_img = ds_img_rescale[0:7,:,:]
image_cooldown_1_img = ds_img_rescale[7:14,:,:]
image_pre_phase = ds_phase_rescale[0:7,:,:]
image_cooldown_phase = ds_phase_rescale[7:14,:,:]

# temp 54-48
image_pre_2_real = ds_real_rescale[7:14,:,:]
image_cooldown_2_real = ds_real_rescale[21:28,:,:]
image_pre_2_img = ds_img_rescale[7:14,:,:]
image_cooldown_2_img = ds_img_rescale[21:28,:,:]
image_pre_phase_2 = ds_phase_rescale[7:14,:,:]
image_cooldown_phase_2 = ds_phase_rescale[21:28,:,:]

# temp 48-39
image_pre_3_real = ds_real_rescale[21:28,:,:]
image_cooldown_3_real = ds_real_rescale[63:70,:,:]
image_pre_3_img = ds_img_rescale[21:28,:,:]
image_cooldown_3_img = ds_img_rescale[63:70,:,:]
image_pre_phase_3 = ds_phase_rescale[21:28,:,:]
image_cooldown_phase_3 = ds_phase_rescale[63:70,:,:]



phase_diff_1 = cal_phase_diff(image_pre_1_real,image_pre_1_img,image_cooldown_1_real,image_cooldown_1_img)
phase_diff_2 = cal_phase_diff(image_pre_2_real,image_pre_2_img,image_cooldown_2_real,image_cooldown_2_img)
phase_diff_3 = cal_phase_diff(image_pre_3_real,image_pre_3_img,image_cooldown_3_real,image_cooldown_3_img)

phase_diff_adjusted_1 = normalize(phase_diff_1,2)
phase_diff_adjusted_2 = normalize(phase_diff_2,2)
phase_diff_adjusted_3 = normalize(phase_diff_3,2)

temp_diff_1 = phase_diff_adjusted_1 / (alpha*gyro_mag_ratio*magnetic_field_0*echo_time)
temp_diff_2 = phase_diff_adjusted_2 / (alpha*gyro_mag_ratio*magnetic_field_0*echo_time)
temp_diff_3 = phase_diff_adjusted_3 / (alpha*gyro_mag_ratio*magnetic_field_0*echo_time)

fig, ((ax1,ax2,ax3,ax4),(ax5,ax6,ax7,ax8)) = plt.subplots(2,4)

im1 = ax1.imshow(temp_diff_3[0])
cbar1 = fig.colorbar(im1, ax=ax1)
im2 = ax2.imshow(temp_diff_3[1])
cbar2 = fig.colorbar(im2, ax=ax2)
im3 = ax3.imshow(temp_diff_3[2])
cbar3 = fig.colorbar(im3, ax=ax3)
im4 = ax4.imshow(temp_diff_3[3])
cbar4 = fig.colorbar(im4, ax=ax4)
im5 = ax5.imshow(temp_diff_3[4])
cbar5 = fig.colorbar(im5, ax=ax5)
im6 = ax6.imshow(temp_diff_3[5])
cbar6 = fig.colorbar(im6, ax=ax6)
im7 = ax7.imshow(temp_diff_3[6])
#cbar7 = fig.colorbar(im7, ax=ax7)
#im8 = ax8.imshow(temp_diff_1[7])
#cbar8 = fig.colorbar(im8, ax=ax8)
#im9 = ax9.imshow(temp_diff_1[8])
#cbar9 = fig.colorbar(im9, ax=ax9)
#im10 = ax10.imshow(temp_diff_1[9])
#cbar10 = fig.colorbar(im10, ax=ax10)

#plt.imshow(temp_diff_1[0])

#requrie napari 
#viewer = napari.Viewer()
#viewer.add_image(temp_diff_1, name='temp_diff')
#napari.run()



#ax = plt.figure().add_subplot(projection='3d')
#ax.voxels(temp_diff_1, edgecolor='k')

#plt.show()



       



