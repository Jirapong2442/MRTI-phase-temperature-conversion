import pydicom as dicom
import numpy as np
import os

# specify your image path
#ds.dir() to check all the track
folder_path = 'D:/HW/Y4T1/fyp/02102024_temperature/02102024_temperature/DICOM'
files = [f for f in os.listdir(folder_path) if os.path.isfile(os.path.join(folder_path, f))]
newfiles = []
count = 0
image = []
intercept_scale = []
slope_scale = []

for file in files:
    if ".dcm" in file:
        ds = dicom.dcmread(folder_path + "/" + file)
        try:
            image_data = ds.pixel_array
            rescale_int = ds.RescaleIntercept
            rescale_slope = ds.RescaleSlope
            type = ds.ImageType
            #window_center = ds. 
            #window_width = 
        except AttributeError:
            continue
        
        if type[3] == 'P':
            count += 1
            if len(image) == 0:
                image.append(image_data)
                intercept_scale.append(rescale_int)
                slope_scale.append(rescale_slope)

                image = np.array(image)
                intercept_scale = np.array(intercept_scale)
                slope_scale = np.array(slope_scale)
            else:
                image = np.concatenate((image,np.expand_dims(image_data,axis=0)),axis = 0)      
                intercept_scale = np.concatenate((intercept_scale,np.expand_dims(rescale_int,axis=0)),axis = 0)    
                slope_scale = np.concatenate((slope_scale,np.expand_dims(rescale_slope,axis=0)),axis = 0)      
        print(type)
    else:
        os.rename(folder_path +"/" + file, folder_path +"/" + file+".dcm")
np.save('D:/HW/Y4T1/fyp/git/MRTI-phase-temperature-conversion/output2/allphase.npy', image) 
np.save('D:/HW/Y4T1/fyp/git/MRTI-phase-temperature-conversion/output2/all_rescale_intercept.npy', intercept_scale) 
np.save('D:/HW/Y4T1/fyp/git/MRTI-phase-temperature-conversion/output2/all_rescale_slope.npy', slope_scale) 
