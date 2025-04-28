%% import data and
clear
clc

% this script run the drift correction estimation of adjacent temperature
% pair. 
% input is folder containing all sub folder of different temperature of
% that experiment

main_path =  "D:\HW\Y4T1\fyp\image data\new_trial\1\ME\";
temperature = dir(main_path);
sub_folder = {};
mean_drift_pair = {};
rect_pos = [238 156 66 66];
rect_pos_2 = [206 328 60 60];
number_of_slices = 7;

for i = 1:length(temperature)-1
    current_temp_path =  temperature(i);
    current_temp_2_path =  temperature(i+1);
    mean_drift_ = {};

    if current_temp_path.isdir && ~strcmp(current_temp_path.name, '.') && ~strcmp(current_temp_path.name, '..') &&current_temp_2_path.isdir && ~strcmp(current_temp_2_path.name, '.') && ~strcmp(current_temp_2_path.name, '..')
         current_temp = fullfile(main_path, current_temp_path.name);
         current_temp_2 = fullfile(main_path, current_temp_2_path.name);

         %read im
         [mag_im,phase_im,real_im,img_im,echo] = read_im(current_temp);
         [mag_im_hi,phase_im_hi,real_im_hi, img_im_hi,echo_2] = read_im(current_temp_2);

        %% separate image by its echo time and slice location
        num_echo = length(echo); 
        
        mag_all = sort_im(mag_im,num_echo,number_of_slices);
        phase_all = sort_im(phase_im,num_echo,number_of_slices);
        real_all = sort_im(real_im,num_echo,number_of_slices);
        img_all = sort_im(img_im,num_echo,number_of_slices);
        
        mag_all_hi = sort_im(mag_im_hi,num_echo,number_of_slices);
        phase_all_hi = sort_im(phase_im_hi,num_echo,number_of_slices);
        real_all_hi = sort_im(real_im_hi,num_echo,number_of_slices);
        img_all_hi = sort_im(img_im_hi,num_echo ,number_of_slices);
        
        field = fieldnames(mag_all);
    
               
        %% unwrapping
        phase_unwrap = struct();
        phase_unwrap_hi = struct();
        phase_diff_all = struct();
        mag_diff_all = struct();
        temp_diff_all = struct();
        
        
        for i=1:length(field)
            name = field{i};
            et = echo{i};
        
            %phase unwrap
            phase_unwrap.(name) = unwrap_(mag_all.(name), phase_all.(name));
            phase_unwrap_hi.(name) = unwrap_(mag_all_hi.(name), phase_all_hi.(name));
        
           %complex subtraction
           [real_all.(name), img_all.(name)] = getRealImag(mag_all.(name),phase_unwrap.(name));
           [real_all_hi.(name), img_all_hi.(name)] = getRealImag(mag_all_hi.(name),phase_unwrap_hi.(name));  
           [phase_diff_all.(name), mag_diff_all.(name)] = complexSub(real_all_hi.(name), img_all_hi.(name),real_all.(name), img_all.(name));
    
        end
    
        %% weighted by TE
        % magnitude of the phase diff
        weight_all = struct();
        for i=1:length(field)
            et = echo{i};
            name = field{i};
            test_mag = mag_diff_all.(name);
            weight_all.(name) = cellfun(@(mag) (mag.*(et/1000)).^2,test_mag,'UniformOutput', false );
        end
        
        %% calcualte normalize weight
        nCells = numel(weight_all.(field{1}));
        weighted_phase = cell(1, nCells);
        
        % Preallocate output
        for i = 1:num_echo
            weight_norm.(field{i}) = cell(1,nCells);
        end
        
        % Loop over each map (cell) j
        for j = 1:nCells
            % 1) compute voxel-wise denominator
            sumW = zeros(size(weight_all.(field{1}){j}));
            for i = 1:num_echo
                sumW = sumW + weight_all.(field{i}){j};
            end
        
            %sumW(sumW==0) = 1;  % avoid div-by-zero
            mask = (sumW > 0);
            for i = 1:num_echo
                name = field{i};
                w = weight_all.(name){j};
                w_norm = zeros(size(w));      % default zero
                w_norm(mask) = w(mask) ./ sumW(mask);
                weight_norm.(name){j} = w_norm; % weight of same slices across all TE same slice j
        

                w_phase = phase_diff_all.(name){1, j}.* w_norm;
        
                if i == 1
                    weighted_phase{1,j} = w_phase;
                else
                    weighted_phase{1,j} = weighted_phase{1,j} + w_phase;
                end
            end
        end
        %%
        %generate mask for temperature independent region
        circle_2 =[rect_pos_2(1)+rect_pos_2(3)/2 rect_pos_2(2)+rect_pos_2(3)/2 rect_pos_2(3)/2];
        mask_oil = generateMask_circle(circle_2, weighted_phase{1,1}, "foreground", true );
        %calcualte drift between adjacent frame
        for j= 1:length(weighted_phase)
                check_corr = weighted_phase{1, j};
                check_corr(mask_oil == 0) =NaN;
                mean_drift = mean(check_corr(~(isnan(check_corr))),"all");
                mean_drift_{end+1} = mean_drift;
        end
        mean_drift_ = cell2mat(mean_drift_);
        mean_drift_pair{end+1} = mean(mean_drift_(1:5)); %region that is more clear
    end
end
%% do trial1 again
save("D:\HW\Y4T1\fyp\MRM-2014-PhaseUnwrapping-master\MRM-2014-PhaseUnwrapping-master\temp_data\drift_correction/ME/trial1.mat","mean_drift_pair");

