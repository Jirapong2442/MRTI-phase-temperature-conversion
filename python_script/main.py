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

class tempmap:
    def __init__(self,extracted_folder):
        self.ds_real = []
        self.ds_img = []
        self.slope_real = []
        self.slope_img = []
        self.int_real = []
        self.int_img = []
        self.echo_time = 0.017 #ms
        self.magnetic_field_0 = 3 # T
        self.alpha = -0.009 # ppm/C  tested in rat muscle at 0-40 degree celcius
        self.gyro_mag_ratio = 267.52218708 #10^8 rad/(s*T)


    def load_folder (path):
        files = os.listdir(path)
        for file in files:
             

