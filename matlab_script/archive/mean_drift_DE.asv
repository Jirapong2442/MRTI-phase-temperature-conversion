%% import data and
clear
clc

% this script run the drift correction estimation of adjacent temperature
% pair. 
% THIS IS ONLY FOR DOUBLE ECHO DATA
% input is folder containing all sub folder of different temperature of
% that experiment

main_path =  "D:\HW\Y4T1\fyp\image data\new_trial\2\DEGRE\";
temperature = dir(main_path);
sub_folder = {};
mean_drift_pair = {};
rect_pos = [238 156 66 66];
rect_pos_2 = [206 328 60 60];

for i = 1:length(temperature)-1
    current_temp_path =  temperature(i);
    current_temp_2_path =  temperature(i+1);
    mean_drift_ = {};

    if current_temp_path.isdir && ~strcmp(current_temp_path.name, '.') && ~strcmp(current_temp_path.name, '..') &&current_temp_2_path.isdir && ~strcmp(current_temp_2_path.name, '.') && ~strcmp(current_temp_2_path.name, '..')
         current_temp = fullfile(main_path, current_temp_path.name);
         current_temp_2 = fullfile(main_path, current_temp_2_path.name);

         %read im
         [mag_im,phase_im,real_im,img_im] = read_im(current_temp);
         [mag_im_hi,phase_im_hi,real_im_hi, img_im_hi] = read_im(current_temp_2);

        mag_im_te1 = mag_im(1:2:end);  % Even indices (echo 1)
        mag_im_te2 = mag_im(2:2:end);  % Odd indices (echo 2)
        phase_im_te1 = phase_im(1:2:end);  
        phase_im_te2 = phase_im(2:2:end); 
        
        mag_im_hi_te1 = mag_im_hi(1:2:end);  
        mag_im_hi_te2 = mag_im_hi(2:2:end);
        phase_im_hi_te1 = phase_im_hi(1:2:end);  
        phase_im_hi_te2 = phase_im_hi(2:2:end);
               
        % unwrapping
        [phase_unwrap_TE1] = unwrap_(mag_im_te1,phase_im_te1);
        [phase_unwrap_TE2] = unwrap_(mag_im_te2,phase_im_te2);
        [phase_hi_unwrap_TE1] = unwrap_(mag_im_hi_te1,phase_im_hi_te1);
        [phase_hi_unwrap_TE2] = unwrap_(mag_im_hi_te2,phase_im_hi_te2);

        %run complex subtraction
        [real_te1, img_te1] = getRealImag(mag_im_te1,phase_unwrap_TE1);
        [real_te2, img_te2] = getRealImag(mag_im_te2,phase_unwrap_TE2);
        [real_te1_hi, img_te1_hi] = getRealImag(mag_im_hi_te1,phase_hi_unwrap_TE1);
        [real_te2_hi, img_te2_hi] = getRealImag(mag_im_hi_te2,phase_hi_unwrap_TE2);
        
        [phase_ref, mag_ref] = complexSub(real_te2,img_te2,real_te1,img_te1);
        [phase_hi, mag_hi]= complexSub(real_te2_hi,img_te2_hi,real_te1_hi,img_te1_hi);
        
        [real_ref, img_ref] = getRealImag(mag_ref,phase_ref);
        [real_hi, img_hi] = getRealImag(mag_hi,phase_hi);
        [phase_diff, mag_diff]= complexSub(real_hi,img_hi,real_ref,img_ref);

        %generate oil mask
        circle_2 =[rect_pos_2(1)+rect_pos_2(3)/2 rect_pos_2(2)+rect_pos_2(3)/2 rect_pos_2(3)/2];
        mask_oil = generateMask_circle(circle_2, phase_diff{1,1}, "foreground", true );

        %calcualte drift between adjacent frame
        for j= 1:length(phase_diff)
                check_corr = phase_diff{1, j};
                check_corr(mask_oil == 0) =NaN;
                mean_drift = mean(check_corr(~(isnan(check_corr))),"all");
                mean_drift_{end+1} = mean_drift;
        end
        mean_drift_ = cell2mat(mean_drift_);
        mean_drift_pair{end+1} = mean(mean_drift_(1:5)); %region that is more clear
   end
end
%% do trial1 again
mean_drift_pair = cellfun(@(x) x.*-1,mean_drift_pair);
save("./temp_data/drift_correction/DEGRE/trial2.mat","mean_drift_pair");

