import pydicom as dicom
import numpy as np
import os

def get_im(ds,Im_type,image):
    try:
        image_data = ds.pixel_array
        rescale_int = ds.RescaleIntercept
        rescale_slope = ds.RescaleSlope
        type = ds.ImageType

        if type[3] == Im_type and image_data.shape[0] == 128:

            if len(image) == 0:
                image.append(image_data)
                image = np.array(image)
 
            else:
                image =np.concatenate((image,np.expand_dims(image_data,axis=0)),axis = 0) 

            return image,rescale_int, rescale_slope
    
    except AttributeError or TypeError: # sometimes it cannot read the image data 
        return None

def check_im (ds):
    try:
        image_data = ds.pixel_array
        if image_data.shape[0] == 128:
            return True
        else:
            return False
    except AttributeError or TypeError: # sometimes it cannot read the image data 
        return False



# specify your image path
#ds.dir() to check all the track
folder_path = 'D:/HW/Y4T1/fyp/For_Ice 3/Temperature_test260824/DICOM'
files = [f for f in os.listdir(folder_path) if os.path.isfile(os.path.join(folder_path, f))]
imaginary_image_all = []
real_image_all = []

for file in files:
    if ".dcm" in file: # when the file havent been assign as a .dcm
        ds = dicom.dcmread(folder_path + "/" + file)

        if check_im(ds):
            print(ds.ImageType)
            if ds.ImageType[3] == 'R':
                real_image_all,int_real, slope_real = get_im(ds,'R',real_image_all)
            elif ds.ImageType[3] == 'I':
                imaginary_image_all,int_img, slope_img = get_im(ds,'I',imaginary_image_all)     
    
    else:
        os.rename(folder_path +"/" + file, folder_path +"/" + file+".dcm")

np.save('D:/HW/Y4T1/fyp/code/output/all_real.npy', real_image_all) 
np.save('D:/HW/Y4T1/fyp/code/outputall_img.npy', imaginary_image_all) 
np.save('D:/HW/Y4T1/fyp/code/output/real_rescale_intercept.npy', int_real) 
np.save('D:/HW/Y4T1/fyp/code/output/real_rescale_slope.npy', slope_real) 
np.save('D:/HW/Y4T1/fyp/code/output/img_rescale_intercept.npy', int_img) 
np.save('D:/HW/Y4T1/fyp/code/output/img_rescale_slope.npy', slope_img) 
