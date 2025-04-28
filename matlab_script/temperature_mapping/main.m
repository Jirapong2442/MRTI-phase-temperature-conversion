% main script running temperature mapping

B0 = 3;
a = -0.01;
g_ratio = 267.522187 ;
pos = [240 156 64 64];
pos_2 = [210 330 60 60];

% specify the path of image folder 
% image in each folder should be arrange in this format:
%       [slice1 te1 M, slice2 te2 M, ..., sliceN teN M]..,
%       [slice1 te1 R, slice2 te2 R, ..., sliceN teN R]..,
%       [slice1 te1 I, slice2 te2 I, ..., sliceN teN I].., 
%       [slice1 te1 P, slice2 te2 P, ..., sliceN teN P] 

B = 45.2;
path_hi = "D:\HW\Y4T1\fyp\image data\new_trial\1\ME\55.49";
path = "D:\HW\Y4T1\fyp\image data\new_trial\1\ME\" + B;
output_name = 45;

temp_map(pos,pos_2,7,path,path_hi,true,output);
