%% test
clear
clc

%% set hyperparameter
A = 51.68;
B = 59.35;

path = "D:\HW\Y4T1\fyp\image data\new_trial\2\DEGRE\65.6";
path_hi = "D:\HW\Y4T1\fyp\image data\new_trial\2\DEGRE\" + B;

[mag_im,phase_im,real_im,img_im] = read_im(path);
[mag_im_hi,phase_im_hi,real_im_hi,img_im_hi] = read_im(path_hi);

mag_im_te1 = mag_im(1:2:end);  % Even indices (echo 1)
mag_im_te2 = mag_im(2:2:end);  % Odd indices (echo 2)
phase_im_te1 = phase_im(1:2:end);  
phase_im_te2 = phase_im(2:2:end); 

mag_im_hi_te1 = mag_im_hi(1:2:end);  
mag_im_hi_te2 = mag_im_hi(2:2:end);
phase_im_hi_te1 = phase_im_hi(1:2:end);  
phase_im_hi_te2 = phase_im_hi(2:2:end);

%% set condition
rename = false ;
algo_unwrap = true; 
manual_unwrap= algo_unwrap;
drift_corr =true;
%trial1 ROI
%rect_pos = [238 156 66 66];
%rect_pos_2 = [206 328 60 60];

%trial2 ROI
rect_pos = [243 153 66 66];
rect_pos_2 = [208 320 64 66];

if (rename == true)
    rewrite_name(24,path_hi);
end
%% load field drift
load('./temp_data/drift_correction/DEGRE/trial2.mat')
%mean_drift = cell2mat(mean_drift_pair);
mean_drift = mean(mean_drift_pair);

%% unwrapping 
% 1 min per 1 unwrap
if (algo_unwrap == true)
    [phase_unwrap_TE1] = unwrap_(mag_im_te1,phase_im_te1);
    [phase_unwrap_TE2] = unwrap_(mag_im_te2,phase_im_te2);
    [phase_hi_unwrap_TE1] = unwrap_(mag_im_hi_te1,phase_im_hi_te1);
    [phase_hi_unwrap_TE2] = unwrap_(mag_im_hi_te2,phase_im_hi_te2);
end

%% complex subtraction
[real_te1, img_te1] = getRealImag(mag_im_te1,phase_unwrap_TE1);
[real_te2, img_te2] = getRealImag(mag_im_te2,phase_unwrap_TE2);
[real_te1_hi, img_te1_hi] = getRealImag(mag_im_hi_te1,phase_hi_unwrap_TE1);
[real_te2_hi, img_te2_hi] = getRealImag(mag_im_hi_te2,phase_hi_unwrap_TE2);

[phase_ref, mag_ref] = complexSub(real_te2,img_te2,real_te1,img_te1);
[phase_hi, mag_hi]= complexSub(real_te2_hi,img_te2_hi,real_te1_hi,img_te1_hi);

[real_ref, img_ref] = getRealImag(mag_ref,phase_ref);
[real_hi, img_hi] = getRealImag(mag_hi,phase_hi);
[phase_diff, mag_diff]= complexSub(real_hi,img_hi,real_ref,img_ref);


%% circle mask generation
circle_ = [rect_pos(1)+rect_pos(3)/2 rect_pos(2)+rect_pos(3)/2 rect_pos(3)/2];
circle_2 =[rect_pos_2(1)+rect_pos_2(3)/2 rect_pos_2(2)+rect_pos_2(3)/2 rect_pos_2(3)/2];
[cols, rows] = meshgrid(1:size(phase_diff{1,1}, 2), 1:size(phase_diff{1,1}, 1));
distanceFromCenter = sqrt((rows - circle_(2)).^2 + (cols - circle_(1)).^2);
circleMask = distanceFromCenter <= circle_(3);

mask_oil = generateMask_circle(circle_2, phase_diff{1,1}, "foreground", true );

%% show results
%addpath('./Unwrap_TIE_DCT_Iter.m/');
%addpath('./@unwrap2/');
%for i = 1:7
 %   subplot(2,4,i);
  %  imagesc(mag_diff{1,i});
   % rectangle('Position',rect_pos,Curvature=[1,1])
    %rectangle('Position',rect_pos_2, Curvature = [1,1])
%end


%% drift correction
%mean_drift_all = {};
phase_corrected = {};

for i= 1:length(phase_diff)
       % check_corr = phase_diff{1, i};
       % check_corr(mask_oil == 0) =NaN;
       % mean_drift = mean(check_corr(~(isnan(check_corr))),"all");
       % mean_drift_all{end+1} = mean_drift;

    if (drift_corr == true)
        phase_corrected{1, i} = phase_diff{1, i} -mean_drift;
    else
        phase_corrected{1, i} = phase_diff{1, i};
    end
end

%% temp map
echo_time = 0.0191 - 0.00379; %TE2-TE1
magnetic_field_0 = 3 ;
alpha = -0.01 ;
gyro_mag_ratio = 267.522187 ;

temp_map = {};  
phase_map = {}; 
unwrap_phase = {};

phase_diff_corrected = phase_corrected;


for i= 1:length(phase_diff_corrected)
    if(manual_unwrap == true)
        submatrix = phase_diff_corrected{1, i}(rect_pos(2):rect_pos(2)+rect_pos(4), rect_pos(1):rect_pos(1)+rect_pos(3)); 
        if (drift_corr)
            mask = (submatrix < - mean_drift - 0.1); %change here
        else
            mask = (submatrix < -0.1);
        end
        submatrix(mask) = submatrix(mask) + (2*pi) ;
        phase_diff_corrected{1, i}(rect_pos(2):rect_pos(2)+rect_pos(4), rect_pos(1):rect_pos(1)+rect_pos(3)) = submatrix;
    end
    
    temp_diff =  phase_diff_corrected{1,i}./ (alpha*gyro_mag_ratio*magnetic_field_0*echo_time) ;
    %mask = (temp_diff > -40) & (temp_diff < 40);
    temp_diff_masked = temp_diff;
    %temp_diff_masked(~mask) = 0;
    temp_map{end+1} = temp_diff_masked;
end

%% show results
% region of probe = 0 whereas background = 1
image_ = temp_map;
image_phase = phase_diff_corrected;

mask_bg = generateMask_circle(circle_, temp_map{1,1}, "background", true );
mask_fg = generateMask_circle(circle_, temp_map{1,1}, "foreground", true );

%mask_bg = generateMask(rect_pos, temp_map{1,1}, "background", true );
%mask_bg = generateMask(rect_pos_2, mask_bg, "background", false );
%region of probe = 1, background = 0
%mask_fg = generateMask(rect_pos, temp_map{1,1}, "foreground", true );

mean_ = {}; 
std_ = {};
phase_ = {};
snr = {}; 

for i = 1:length(image_)
    subplot(2, 4, i);  % Create a subplot

    % apply mask to image calculate the    
    bg = image_{1,i};
    probe = image_{1,i};
    probe_phase = image_phase{1,i};

    probe_phase(mask_fg == 0) =NaN;
    probe(mask_fg==0) = NaN;
    bg(mask_bg == 0) = NaN;

    % Calculate the mean value of the region
    %mean_val = mean(temp_map{1,i}( 140:140+65, 220:220+70), "all");
    mean_val = mean(probe(~(isnan(probe))),"all");
    std_val = std(probe(~(isnan(probe))));

    %phase value of the probe
    phase_val = mean(probe_phase(~(isnan(probe_phase))),"all");

    std_bg = std(bg(~(isnan(bg))));
    snr_val = -mean_val / std_bg;
    
    snr_db = 10*log10(snr_val);

    imagesc(image_{1,i});
    %imagesc(image_phase{1,i}); % for without unwrap
    rectangle('Position',rect_pos,Curvature=[1,1])
    rectangle('Position',rect_pos_2, Curvature = [1,1])
        
    % Calculate the mean value of the region
    text(10, 20, ['Mean: ', num2str(mean_val, '%.3f'), '°C'], ...
    'Color', 'black', 'FontSize', 12, 'FontWeight', 'bold');
    title(['Image ', num2str(i)]);

    text(10, 50, ['SNR: ', num2str(snr_db, '%.3f'), ' db'], ...
    'Color', 'black', 'FontSize', 12, 'FontWeight', 'bold');
    title(['Image ', num2str(i)]);
    
    if(drift_corr)
        text(10, 80, ['Drift: ', num2str(mean_drift, '%.3f'), 'rad'], ...
        'Color', 'black', 'FontSize', 12, 'FontWeight', 'bold');
        title(['Image ', num2str(i)]);
    end
    
    h = colorbar;
    mean_{end+1} = mean_val;
    std_{end+1} = std_val;
    phase_{end+1} = phase_val;
    snr{end+1} = snr_db;
end
dcm = datacursormode;
dcm.Enable = 'on';
dcm.DisplayStyle = 'window';

%% save data
img_name = strcat('D:\HW\Y4T1\fyp\output\New\UW_CS_new\DE_DC_constant\2\',  num2str(A) , '_',  num2str(B) , '.png') ; 

saveas(gcf,img_name) ;
save("./temp_data/new/UW_CS_new/DEGRE/DC/2/trial2_" + A + "_" + B + ".mat" ,"mean_","std_", "phase_","snr");








