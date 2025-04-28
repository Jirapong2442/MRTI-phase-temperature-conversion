%% import data and
clear
clc

% this script run the drift correction estimation of adjacent temperature
% pair. 
% THIS IS ONLY FOR SINGLE ECHO DATA
% input is folder containing all sub folder of different temperature of
% that experiment

main_path =  "D:\HW\Y4T1\fyp\image data\new_trial\1\FFE\";
temperature = dir(main_path);
sub_folder = {};
mean_drift_pair = {};

for i = 1:length(temperature)-1
    current_temp_path =  temperature(i);
    current_temp_2_path =  temperature(i+1);
    mean_drift_ = {};

    if current_temp_path.isdir && ~strcmp(current_temp_path.name, '.') && ~strcmp(current_temp_path.name, '..') &&current_temp_2_path.isdir && ~strcmp(current_temp_2_path.name, '.') && ~strcmp(current_temp_2_path.name, '..')
         current_temp = fullfile(main_path, current_temp_path.name);
         current_temp_2 = fullfile(main_path, current_temp_2_path.name);

         %read im
         [mag_im,phase_im,real_im,img_im,echo] = read_im(current_temp);
         [mag_im_hi,phase_im_hi,real_im_hi, img_im_hi,echo_hi] = read_im(current_temp_2);
         %trial2
        rect_pos = [122 77 33 34];
        rect_pos_2 = [106 163 32 32];
               
        % unwrapping
        [phase_unwrap] = unwrap_(mag_im,phase_im);
        [phase_hi_unwrap] = unwrap_(mag_im_hi,phase_im_hi);

        %run complex subtraction
        real_unwrap = cellfun(@(m,p) m.*cos(p),mag_im,phase_unwrap,'UniformOutput', false );
        img_unwrap = cellfun(@(m,p) m.*sin(p),mag_im,phase_unwrap,'UniformOutput', false );
        real_unwrap_hi = cellfun(@(m,p) m.*cos(p),mag_im_hi,phase_hi_unwrap,'UniformOutput', false );
        img_unwrap_hi = cellfun(@(m,p) m.*sin(p),mag_im_hi,phase_hi_unwrap,'UniformOutput', false );
        [phase_diff, mag_diff]  = complexSub(real_unwrap_hi,img_unwrap_hi, real_unwrap,img_unwrap);

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

save("./temp_data/drift_correction/FFE/trial1.mat","mean_drift_pair");

