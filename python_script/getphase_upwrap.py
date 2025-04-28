import pydicom as dicom
import numpy as np
import os
pixel_array = 512
def concat(old_data,new_data):
    if type(old_data) == dicom.valuerep.DSfloat:
        old_data = [old_data]
        old_data = np.array(old_data)

    if len(old_data) == 0:
        old_data.append(new_data)
        old_data = np.array(old_data)
    else:
        old_data =np.concatenate((old_data,np.expand_dims(new_data,axis=0)),axis = 0) 
    return old_data

def get_im(ds,Im_type,image,intercept,slope):
    try:
        image_data = ds.pixel_array
        rescale_int = ds.RescaleIntercept
        rescale_slope = ds.RescaleSlope
        type = ds.ImageType

        if type[3] == Im_type and image_data.shape[0] == pixel_array:
            image = concat(image,image_data)
            intercept = concat(intercept,rescale_int)
            slope = concat(slope,rescale_slope)
            return image,intercept, slope
    
    except AttributeError or TypeError: # sometimes it cannot read the image data 
        return None

def check_im (ds):
    try:
        image_data = ds.pixel_array
        if image_data.shape[0] == pixel_array:
            return True
        else:
            return False
    except AttributeError or TypeError: # sometimes it cannot read the image data 
        return False

'''
main function used to extract npy 2d array of phase, real, and imaginary and their rescaling factors from DICOM folder
'''

if __name__ == "__main__":
    # specify your image path
    #ds.dir() to check all the track

    # need to manually input the size of data in checim
    folder_path = 'D:/HW/Y4T1/fyp/image data/DEGRE/2/DICOM/'
    out_path= "./trial2_degre/"

    files = [f for f in os.listdir(folder_path) if os.path.isfile(os.path.join(folder_path, f))]
    imaginary_image_all = []
    real_image_all = []
    phase_image_all = []
    int_img = []
    slope_img = []
    int_real = []
    slope_real = []
    int_phase = []
    slope_phase = []


    for file in files:
        if ".dcm" in file: # when the file havent been assign as a .dcm
            ds = dicom.dcmread(folder_path + "/" + file)

            if check_im(ds):
                print(ds.ImageType)
                if ds.ImageType[3] == 'R':
                    real_image_all,int_real, slope_real = get_im(ds,'R',real_image_all,intercept= int_real,slope= slope_real)
                elif ds.ImageType[3] == 'I':
                    imaginary_image_all,int_img, slope_img = get_im(ds,'I',imaginary_image_all, intercept= int_img, slope=slope_img)     
                elif ds.ImageType[3] == 'P':
                    phase_image_all,int_phase, slope_phase = get_im(ds,'P',phase_image_all, intercept= int_phase, slope= slope_phase ) 
        
        elif "IM" in file:
            os.rename(folder_path +"/" + file, folder_path +"/" + file+".dcm")
    try:
        np.save(out_path + 'all_phase.npy', phase_image_all) 
        np.save(out_path + 'phase_rescale_intercept.npy', int_phase) 
        np.save(out_path + 'phase_rescale_slope.npy', slope_phase) 

        np.save(out_path + 'all_real.npy', real_image_all) 
        np.save(out_path + 'all_img.npy', imaginary_image_all) 
        np.save(out_path + 'real_rescale_intercept.npy', int_real) 
        np.save(out_path + 'real_rescale_slope.npy', slope_real) 
        np.save(out_path + 'img_rescale_intercept.npy', int_img) 
        np.save(out_path + 'img_rescale_slope.npy', slope_img) 
        
    except FileNotFoundError:
        os.mkdir(out_path)
        np.save(out_path + 'all_phase.npy', phase_image_all) 
        np.save(out_path + 'phase_rescale_intercept.npy', int_phase) 
        np.save(out_path + 'phase_rescale_slope.npy', slope_phase) 

        np.save(out_path + 'all_real.npy', real_image_all) 
        np.save(out_path + 'all_img.npy', imaginary_image_all) 
        np.save(out_path + 'real_rescale_intercept.npy', int_real) 
        np.save(out_path + 'real_rescale_slope.npy', slope_real) 
        np.save(out_path + 'img_rescale_intercept.npy', int_img) 
        np.save(out_path + 'img_rescale_slope.npy', slope_img) 
