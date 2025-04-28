import pydicom as dicom
import numpy as np
import pandas as pd 
import matplotlib.pylab as plt
from pydicom.data import get_testdata_files
import cv2
from rembg import remove #doesnt work with input image = removed the whole image, output image = unit is not uint16
from scipy.stats import norm
from scipy import stats
import os
from skimage.restoration import unwrap_phase
from scipy.ndimage import gaussian_filter

echo_time = 0.017 #xs
magnetic_field_0 = 3 # T
alpha = -0.01 # ppm/C  tested in rat muscle at 0-40 degree celcius
gyro_mag_ratio = 267.5105 #10^6 rad/(s*T)

# how to broadcast into the whole image
def rescale (slice,all_slope,all_intercept):
    out_slice = slice.astype(np.float64)
    for index in range(all_slope.shape[0]):
        out_slice[index] = slice[index]*all_slope[index] + all_intercept[index]
    return out_slice/1000

def cal_phase_diff (im_pre_real,im_pre_img,im_post_real,im_post_img):
    phase_diff = np.arctan(((im_pre_real*im_post_img) - (im_post_real*im_pre_img))/
                          ((im_pre_real *im_post_real) + (im_pre_img*im_post_img)))
    phase_diff = np.nan_to_num(phase_diff)
    return phase_diff

def normalize(phase_image,sigma):
    adjusted_phase = np.zeros(phase_image.shape)

    for index in range(phase_image.shape[0]):
        mu, std = norm.fit(phase_image[index])
        adjusted_phase[index] = np.where( np.abs((phase_image[index]-mu)/std) <= sigma, phase_image[index] , 0)

    return adjusted_phase

def compute_phase_difference(phase_map, ref_map, slice_):
    """
    Compute the temperature difference using phase maps.

    Parameters:
    - phase_map_te1: 2D numpy array of phase values at TE1 (current state).
    - phase_map_te2: 2D numpy array of phase values at TE2 (current state).
    - ref_phase_map_te1: 2D numpy array of phase values at TE1 (reference state).
    - ref_phase_map_te2: 2D numpy array of phase values at TE2 (reference state).
    - alpha: Proton resonance frequency temperature coefficient (default -0.01 ppm/°C).
    - gamma: Gyromagnetic ratio in Hz/T (default 42.58 MHz/T for hydrogen).
    - B0: Magnetic field strength in Tesla (default 3.0 T).
    - delta_TE: Difference in echo times in seconds (default 0.01 s = 10 ms).

    Returns:
    - temperature_difference: 2D numpy array of temperature differences.
    phasemap - refmap
    
    """
    slice_ = int(slice_/2)
    #even = echo 1; odd = echo2
    phase_map_te1 = phase_map[::2]
    phase_map_te2 = phase_map[1::2]

    ref_phase_map_te1 = ref_map[::2]
    ref_phase_map_te2 =ref_map[1::2]

    # Compute the complex exponentials of the phase maps
    exp_phase_te1 = np.exp(1j * phase_map_te1)
    exp_phase_te2 = np.exp(1j * phase_map_te2)
    exp_ref_phase_te1 = np.exp(1j * ref_phase_map_te1)
    exp_ref_phase_te2 = np.exp(1j * ref_phase_map_te2)

    # Compute the phase differences using the complex conjugates
    delta_phi_current = np.angle(exp_phase_te2 * np.conj(exp_phase_te1))
    delta_phi_ref = np.angle(exp_ref_phase_te2 * np.conj(exp_ref_phase_te1))

    # Compute the corrected phase difference between the current and reference states
    delta_phi_diff = np.angle(np.exp(1j * delta_phi_current) * np.conj(np.exp(1j * delta_phi_ref)))

    return delta_phi_diff

if __name__ == "__main__":

    df = {
    "all_img": [],
    "all_phase": [],
    "all_real": [],
    "img_rescale_intercept": [],
    "img_rescale_slope":[],
    "phase_rescale_intercept": [],
    "phase_rescale_slope":[],
    "real_rescale_intercept": [],
    "real_rescale_slope":[],
    }

    '''
    1st trial : 
        Large 
            1.1 ffe 44 degre 43
            1.2 ffe 37.5 degre 37.5 
            1.3 ffe 34.21 degre
        Small
            1.1 ffe 30 degre 29.5
            1.2 ffe 30 degre
            1.3 ffe 28.85 degre

    2nd trial :
        Large 
            2.1 ffe 49 degre 48
            2.2 ffe 40 degre 40
            2.3 ffe 34 degre
        Small
            2.1 ffe 38 degre 37
            2.2 ffe 30 degre 30
            2.3 ffe 28.6 degre 

    '''

    path = "./trial1_degre/"
    files = os.listdir(path)
    for file in files:
        file_name = file.split('.')[0]
        df[file_name] = np.load(path + file)

    ds_real_rescale = rescale(df['all_real'],df['real_rescale_slope'],df['real_rescale_intercept']) # change unit into rad
    ds_img_rescale = rescale(df['all_img'],df['img_rescale_slope'],df['img_rescale_intercept']) # change unit into rad
    ds_phase_rescale = rescale(df['all_phase'],df['phase_rescale_slope'],df['phase_rescale_intercept'])
    
    x = [54.0,48.0,42.0,39.0]
    x = np.array(x)

    im_slice = int(ds_real_rescale.shape[0] / 3)

    # 44 to 37.5 degree (-6.5 diff)
    image_pre_1_real = ds_real_rescale[0:im_slice,:,:]
    image_cooldown_1_real = ds_real_rescale[im_slice:im_slice*2,:,:]
    image_pre_1_img = ds_img_rescale[0:im_slice,:,:]
    image_cooldown_1_img = ds_img_rescale[im_slice:im_slice*2,:,:]
    image_pre_phase = ds_phase_rescale[0:im_slice,:,:]
    image_cooldown_phase = ds_phase_rescale[im_slice:im_slice*2,:,:]

    #37.5 to 34.2  -3.3 degree
    image_cooldown_2_real = ds_real_rescale[2*im_slice:im_slice*3,:,:]
    image_cooldown_2_img = ds_img_rescale[2*im_slice:im_slice*3,:,:]
    image_cooldown_2_phase = ds_phase_rescale[2*im_slice:im_slice*3,:,:]

    #phase image
    image_phase_1 = ds_phase_rescale[0:im_slice,:,:]
    image_phase_2 = ds_phase_rescale[im_slice:im_slice*2,:,:]
    image_phase_3 = ds_phase_rescale[2*im_slice:im_slice*3,:,:]

    #phase_diff_1 = cal_phase_diff(image_pre_1_real,image_pre_1_img,image_cooldown_1_real,image_cooldown_1_img)
    #phase_diff_2 = cal_phase_diff(image_cooldown_1_real,image_cooldown_1_img,image_cooldown_2_real,image_cooldown_2_img)
    #phase_diff_3 = cal_phase_diff(image_pre_1_real,image_pre_1_img,image_cooldown_2_real,image_cooldown_2_img)

    #DEGRE
    echo_time = (19.1-3.79)/1000
    phase_diff_1 = compute_phase_difference(image_phase_1,image_phase_2,im_slice) #1 - 2 ref = +6.5
    phase_diff_2 = compute_phase_difference(image_phase_2,image_phase_3,im_slice) # 2 - 3 ref = 3.3
    phase_diff_3 = compute_phase_difference(image_phase_1,image_phase_3,im_slice) # 1 - 3 ref = 9.8
    rect = 70*2
    extension = 30*2
    pad = 45*2

    # 44 to 34.2 = -10 degree

    temp_diff_1 = phase_diff_1 / (alpha*gyro_mag_ratio*magnetic_field_0*echo_time) 
    temp_diff_2 = phase_diff_2 / (alpha*gyro_mag_ratio*magnetic_field_0*echo_time) 
    temp_diff_3 = phase_diff_3 / (alpha*gyro_mag_ratio*magnetic_field_0*echo_time) 

    # plot the image
    # 128 = 75,30,35


    #rect = 70
    #extension = 30
    #pad = 45

    image_to_plot = temp_diff_3
    
    fig, ((ax1,ax2,ax3,ax4),(ax5,ax6,ax7,ax8)) = plt.subplots(2,4)
   

    im1 = ax1.imshow(image_to_plot[0])
    cbar1 = fig.colorbar(im1, ax=ax1)
    rect1 = plt.Rectangle((rect+pad, rect), extension, extension, fill=False, color='red', linewidth=2)
    ax1.add_patch(rect1)
    #additional
    rect1_small = plt.Rectangle((rect+pad+5, rect+ 2*extension), extension/2, extension/2, fill=False, color='blue', linewidth=1)
    ax1.add_patch(rect1_small)
    avg1_small = np.mean(image_to_plot[0][rect+ 2*extension:int(rect+ 2*extension+extension/2), rect+pad+5:int(rect+pad+5+extension/2)])
    ax1.text(20, 80, f'Avg: {avg1_small:.2f}', color='blue', bbox=dict(facecolor='white', alpha=0.7))

    avg1 = np.mean(image_to_plot[0][rect:rect+extension, rect+pad:rect+pad+extension])
    ax1.text(20, 20, f'Avg: {avg1:.2f}', color='red', bbox=dict(facecolor='white', alpha=0.7))

    im2 = ax2.imshow(image_to_plot[1])
    cbar2 = fig.colorbar(im2, ax=ax2)
    rect1 = plt.Rectangle((rect+pad, rect), extension, extension, fill=False, color='red', linewidth=2)
    ax2.add_patch(rect1)
    #additional
    rect1_small = plt.Rectangle((rect+pad+5, rect+ 2*extension), extension/2, extension/2, fill=False, color='blue', linewidth=1)
    ax2.add_patch(rect1_small)
    avg1_small = np.mean(image_to_plot[1][rect+ 2*extension:int(rect+ 2*extension+extension/2), rect+pad+5:int(rect+pad+5+extension/2)])
    ax2.text(20, 80, f'Avg: {avg1_small:.2f}', color='blue', bbox=dict(facecolor='white', alpha=0.7))

    avg2 = np.mean(image_to_plot[1][rect:rect+extension, rect+pad:rect+pad+extension])
    ax2.text(20, 20, f'Avg: {avg2:.2f}', color='red', bbox=dict(facecolor='white', alpha=0.7))


    im3 = ax3.imshow(image_to_plot[2])
    cbar3 = fig.colorbar(im3, ax=ax3)
    rect3 = plt.Rectangle((rect+pad, rect), extension, extension, fill=False, color='red', linewidth=2)
    ax3.add_patch(rect3)
    #additional
    rect1_small = plt.Rectangle((rect+pad+5, rect+ 2*extension), extension/2, extension/2, fill=False, color='blue', linewidth=1)
    ax3.add_patch(rect1_small)
    avg1_small = np.mean(image_to_plot[2][rect+ 2*extension:int(rect+ 2*extension+extension/2), rect+pad+5:int(rect+pad+5+extension/2)])
    ax3.text(20, 80, f'Avg: {avg1_small:.2f}', color='blue', bbox=dict(facecolor='white', alpha=0.7))

    avg3 = np.mean(image_to_plot[2][rect:rect+extension, rect+pad:rect+pad+extension])
    ax3.text(20, 20, f'Avg: {avg3:.2f}', color='red', bbox=dict(facecolor='white', alpha=0.7))

    im4 = ax4.imshow(image_to_plot[3])
    cbar4 = fig.colorbar(im4, ax=ax4)
    rect4 = plt.Rectangle((rect+pad, rect), extension, extension, fill=False, color='red', linewidth=2)
    ax4.add_patch(rect4)
    #additional
    rect1_small = plt.Rectangle((rect+pad+5, rect+ 2*extension), extension/2, extension/2, fill=False, color='blue', linewidth=1)
    ax4.add_patch(rect1_small)
    avg1_small = np.mean(image_to_plot[3][rect+ 2*extension:int(rect+ 2*extension+extension/2), rect+pad+5:int(rect+pad+5+extension/2)])
    ax4.text(20, 80, f'Avg: {avg1_small:.2f}', color='blue', bbox=dict(facecolor='white', alpha=0.7))

    avg4 = np.mean(image_to_plot[3][rect:rect+extension, rect+pad:rect+pad+extension])
    ax4.text(20, 20, f'Avg: {avg4:.2f}', color='red', bbox=dict(facecolor='white', alpha=0.7))

    im5 = ax5.imshow(image_to_plot[4])
    cbar5 = fig.colorbar(im5, ax=ax5)
    rect5 = plt.Rectangle((rect+pad, rect), extension, extension, fill=False, color='red', linewidth=2)
    ax5.add_patch(rect5)
    #additional
    rect1_small = plt.Rectangle((rect+pad+5, rect+ 2*extension), extension/2, extension/2, fill=False, color='blue', linewidth=1)
    ax5.add_patch(rect1_small)
    avg1_small = np.mean(image_to_plot[4][rect+ 2*extension:int(rect+ 2*extension+extension/2), rect+pad+5:int(rect+pad+5+extension/2)])
    ax5.text(20, 80, f'Avg: {avg1_small:.2f}', color='blue', bbox=dict(facecolor='white', alpha=0.7))

    avg5 = np.mean(image_to_plot[4][rect:rect+extension, rect+pad:rect+pad+extension])
    ax5.text(20, 20, f'Avg: {avg5:.2f}', color='red', bbox=dict(facecolor='white', alpha=0.7))

    im6 = ax6.imshow(image_to_plot[5])
    cbar6 = fig.colorbar(im6, ax=ax6)
    rect6 = plt.Rectangle((rect+pad, rect), extension, extension, fill=False, color='red', linewidth=2)
    ax6.add_patch(rect6)
    #additional
    rect1_small = plt.Rectangle((rect+pad+5, rect+ 2*extension), extension/2, extension/2, fill=False, color='blue', linewidth=1)
    ax6.add_patch(rect1_small)
    avg1_small = np.mean(image_to_plot[5][rect+ 2*extension:int(rect+ 2*extension+extension/2), rect+pad+5:int(rect+pad+5+extension/2)])
    ax6.text(20, 80, f'Avg: {avg1_small:.2f}', color='blue', bbox=dict(facecolor='white', alpha=0.7))

    avg6 = np.mean(image_to_plot[5][rect:rect+extension, rect+pad:rect+pad+extension])
    ax6.text(20, 20, f'Avg: {avg6:.2f}', color='red', bbox=dict(facecolor='white', alpha=0.7))

    im7 = ax7.imshow(image_to_plot[6])
    cbar7 = fig.colorbar(im7, ax=ax7)
    rect7 = plt.Rectangle((rect+pad, rect), extension, extension, fill=False, color='red', linewidth=2)
    ax7.add_patch(rect7)
    #additional
    rect1_small = plt.Rectangle((rect+pad+5, rect+ 2*extension), extension/2, extension/2, fill=False, color='blue', linewidth=1)
    ax7.add_patch(rect1_small)
    avg1_small = np.mean(image_to_plot[6][rect+ 2*extension:int(rect+ 2*extension+extension/2), rect+pad+5:int(rect+pad+5+extension/2)])
    ax7.text(20, 80, f'Avg: {avg1_small:.2f}', color='blue', bbox=dict(facecolor='white', alpha=0.7))

    avg7 = np.mean(image_to_plot[6][rect:rect+extension, rect+pad:rect+pad+extension])
    ax7.text(20, 20, f'Avg: {avg7:.2f}', color='red', bbox=dict(facecolor='white', alpha=0.7))
    
    ax8.axis('off')
    plt.show()

    '''
    im8 = ax8.imshow(image_to_plot[7])
    cbar8 = fig.colorbar(im8, ax=ax8)
    rect8 = plt.Rectangle((rect, rect), extension, extension, fill=False, color='red', linewidth=2)
    ax8.add_patch(rect8)
    avg8 = np.mean(image_to_plot[7][rect:rect+extension, rect+pad:rect+pad+extension])
    ax8.text(20, 20, f'Avg: {avg8:.2f}', color='red', bbox=dict(facecolor='white', alpha=0.7))

    im9 = ax9.imshow(image_to_plot[8])
    cbar9 = fig.colorbar(im9, ax=ax9)
    rect9 = plt.Rectangle((rect, rect), extension, extension, fill=False, color='red', linewidth=2)
    ax9.add_patch(rect9)
    avg9 = np.mean(image_to_plot[8][rect:rect+extension, rect+pad:rect+pad+extension])
    ax9.text(20, 20, f'Avg: {avg9:.2f}', color='red', bbox=dict(facecolor='white', alpha=0.7))

    im10 = ax10.imshow(image_to_plot[9])
    cbar10 = fig.colorbar(im10, ax=ax10)
    rect10 = plt.Rectangle((rect, rect), extension, extension, fill=False, color='red', linewidth=2)
    ax10.add_patch(rect10)
    avg10 = np.mean(image_to_plot[9][rect:rect+extension, rect+pad:rect+pad+extension])
    ax10.text(20, 20, f'Avg: {avg10:.2f}', color='red', bbox=dict(facecolor='white', alpha=0.7))
    '''
    #fig.savefig('temp_diff_2.png')
    



    #plt.imshow(temp_diff_1[0])

    #requrie napari 
    #viewer = napari.Viewer()
    #viewer.add_image(temp_diff_1, name='temp_diff')
    #napari.run()



    #ax = plt.figure().add_subplot(projection='3d')
    #ax.voxels(temp_diff_1, edgecolor='k')

    #plt.show()

'''
#plot reg line
    rect = 68
    extension = 120
    y2 = [np.average(temp_diff_1[:,rect:rect+extension,rect:rect+extension]),np.average(temp_diff_2[:,rect:rect+extension,rect:rect+extension]),
            np.average(temp_diff_3[:,rect:rect+extension,rect:rect+extension]),np.average(temp_diff_4[:,rect:rect+extension,rect:rect+extension])]

    y1 = [np.average(temp_diff_1[:,rect:rect+extension,rect:rect+extension]),np.average(temp_diff_2[:,rect:rect+extension,rect:rect+extension]),
            np.average(temp_diff_3[:,rect:rect+extension,rect:rect+extension]),np.average(temp_diff_4[:,rect:rect+extension,rect:rect+extension])]

    y = y2
    slope, intercept, r_value, p_value, std_err = stats.linregress(x, y)
    
    # Create the plot
    plt.figure(figsize=(10, 6))
    
    # Scatter plot of original points
    plt.scatter(x, y, color='blue', label='Data Points')
        # Add full coordinate labels to each point
    for xi, yi in zip(x, y):
        plt.annotate(f'({xi:.2f}, {yi:.2f})', 
                     (xi, yi), 
                     xytext=(5, 5),  # 5 points offset
                     textcoords='offset points',
                     fontsize=9,
                     color='blue')
    
    # Regression line
    line = slope * x + intercept
    plt.plot(x, line, color='red', label=f'Regression Line: y = {slope:.2f}x + {intercept:.2f}')
    
    # Customize the plot
    plt.title('temperature estimated from phase shift in each temperature interval', fontsize=15)
    plt.xlabel('measured temperature', fontsize=12)
    plt.ylabel('estimated temperature difference', fontsize=12)
    plt.legend()
    plt.grid(True, linestyle='--', alpha=0.7)
    
    # Add regression statistics as text
    stats_text = (
        f'Slope: {slope:.4f}\n'
        f'Intercept: {intercept:.4f}\n'
        f'R-squared: {r_value**2:.4f}\n'
        f'P-value: {p_value:.4f}'
    )
    plt.annotate(stats_text, xy=(0.05, 0.95), xycoords='axes fraction', 
                 verticalalignment='top', 
                 bbox=dict(boxstyle='round', facecolor='white', alpha=0.7))

    # Show the plot
    plt.tight_layout()
    plt.show()
'''


       



'''
    #38 to 34
    image_pre_1_real = ds_real_rescale[10:20,:,:]
    image_cooldown_1_real = ds_real_rescale[20:30,:,:]
    image_pre_1_img = ds_img_rescale[10:20,:,:]
    image_cooldown_1_img = ds_img_rescale[20:30,:,:]
    image_pre_phase = ds_phase_rescale[10:20,:,:]
    image_cooldown_phase = ds_phase_rescale[20:30,:,:]

    #32 to 28
    image_pre_2_real = ds_real_rescale[30:40,:,:]
    image_cooldown_2_real = ds_real_rescale[40:50,:,:]
    image_pre_2_img = ds_img_rescale[30:40,:,:]
    image_cooldown_2_img = ds_img_rescale[40:50,:,:]
    image_pre_phase_2 = ds_phase_rescale[30:40,:,:]
    image_cooldown_phase_2 = ds_phase_rescale[40:50,:,:]

    
    # temp 58-54
    image_pre_1_real = ds_real_rescale[0:7,:,:]
    image_cooldown_1_real = ds_real_rescale[7:14,:,:]
    image_pre_1_img = ds_img_rescale[0:7,:,:]
    image_cooldown_1_img = ds_img_rescale[7:14,:,:]
    image_pre_phase = ds_phase_rescale[0:7,:,:]
    image_cooldown_phase = ds_phase_rescale[7:14,:,:]

    # temp 58-48
    image_pre_2_real = ds_real_rescale[0:7,:,:]
    image_cooldown_2_real = ds_real_rescale[21:28,:,:]
    image_pre_2_img = ds_img_rescale[0:7,:,:]
    image_cooldown_2_img = ds_img_rescale[21:28,:,:]
    image_pre_phase_2 = ds_phase_rescale[0:7,:,:]
    image_cooldown_phase_2 = ds_phase_rescale[21:28,:,:]

    # temp 58-42
    image_pre_3_real = ds_real_rescale[0:7,:,:]
    image_cooldown_3_real = ds_real_rescale[56:63,:,:]
    image_pre_3_img = ds_img_rescale[0:7,:,:]
    image_cooldown_3_img = ds_img_rescale[56:63,:,:]
    image_pre_phase_3 = ds_phase_rescale[0:7,:,:]
    image_cooldown_phase_3 = ds_phase_rescale[56:63,:,:]

    
    # temp 58-39
    image_pre_4_real = ds_real_rescale[0:7,:,:]
    image_cooldown_4_real = ds_real_rescale[63:70,:,:]
    image_pre_4_img = ds_img_rescale[0:7,:,:]
    image_cooldown_4_img = ds_img_rescale[63:70,:,:]
    image_pre_phase_4 = ds_phase_rescale[0:7,:,:]
    image_cooldown_phase_4 = ds_phase_rescale[63:70,:,:]

    
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


    #temp 58 - 48
    image_pre_5_real = ds_real_rescale[0:7,:,:]
    image_cooldown_5_real = ds_real_rescale[21:28,:,:]
    image_pre_5_img = ds_img_rescale[0:7,:,:]
    image_cooldown_5_img = ds_img_rescale[21:28,:,:]
    image_pre_phase_5 = ds_phase_rescale[0:7,:,:]
    image_cooldown_phase_5 = ds_phase_rescale[21:28,:,:]
    '''