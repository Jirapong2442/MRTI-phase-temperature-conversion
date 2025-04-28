%% load data
clear;
clc; 
addpath('goldstein\');
A = 30.4;
B = 31;

path = "D:\HW\Y4T1\fyp\image data\new_trial\1\FFE\60";
path_hi = "D:\HW\Y4T1\fyp\image data\new_trial\1\FFE\" + B;

[mag_im,phase_im,real_im,img_im] = read_im(path);
[mag_im_hi,phase_im_hi,real_im_hi, img_im_hi] = read_im(path_hi);

%% set condition
% limit = pi / -0.1364 = 2.0271
algo_unwrap = true; 
drift_corr = true;
manual_unwrap= true;

rect_pos = [118 76 33 34];
rect_pos_2 = [106 165 32 32];

%% add file type for the first time analysis
%test_path2 = "D:\HW\Y4T1\fyp\image data\new_trial\phantom26032025_2\DICOM\00000001\";
%addFileType(test_path2);

%% complex subtraction
real_unwrap = cellfun(@(m,p) m.*cos(p),mag_im,phase_im,'UniformOutput', false );
img_unwrap = cellfun(@(m,p) m.*sin(p),mag_im,phase_im,'UniformOutput', false );
real_unwrap_hi = cellfun(@(m,p) m.*cos(p),mag_im_hi,phase_im_hi,'UniformOutput', false );
img_unwrap_hi = cellfun(@(m,p) m.*sin(p),mag_im_hi,phase_im_hi,'UniformOutput', false );

[phase_diff, mag_diff]  = complexSub(real_unwrap,img_unwrap,real_unwrap_hi,img_unwrap_hi);

%% unwrapping
if (algo_unwrap == true)
    [phase_diff_unwrap] = unwrap_(mag_diff,phase_diff);
          %temp_diff =  unwrap_phase./ (alpha*gyro_mag_ratio*magnetic_field_0*echo_time) ;%comment
end

%% show results

for i = 1:7
    subplot(2,4,i);
    imagesc(phase_diff_unwrap{1,i});
end
%% circle mask generation
circle_ = [136 94 16];
circle_2 =[rect_pos_2(1)+rect_pos_2(3)/2 rect_pos_2(2)+rect_pos_2(3)/2 rect_pos_2(3)/2];
[cols, rows] = meshgrid(1:size(phase_diff_unwrap{1,1}, 2), 1:size(phase_diff_unwrap{1,1}, 1));
distanceFromCenter = sqrt((rows - circle_(2)).^2 + (cols - circle_(1)).^2);
circleMask = distanceFromCenter <= circle_(3);

mask_fg = generateMask_circle(circle_2, phase_diff_unwrap{1,1}, "foreground", true );

%% drift correction
mean_drift_all = {};
phase_corrected = {};

for i= 1:length(phase_diff_unwrap)
        check_corr = phase_diff_unwrap{1, i};
        check_corr(mask_fg == 0) =NaN;
        mean_drift = mean(check_corr(~(isnan(check_corr))),"all");
        mean_drift_all{end+1} = mean_drift;

    if (drift_corr == true)
        phase_corrected{1, i} = phase_diff_unwrap{1, i} -mean_drift;
    else
        phase_corrected{1, i} = phase_diff_unwrap{1, i};
    end
end

%% temperature mapping
echo_time = 0.017;
magnetic_field_0 = 3 ;
alpha = -0.01 ;
gyro_mag_ratio = 267.522187 ;
temp_map = {};  
phase_map = {}; 
unwrap_phase = {};
phase_diff_corrected = phase_corrected;

for i= 1:length(phase_im_hi)
    if(manual_unwrap == true)
       
        submatrix = phase_diff_corrected{1, i}(rect_pos(2):rect_pos(2)+rect_pos(4), rect_pos(1):rect_pos(1)+rect_pos(3));  
        mask = (submatrix <= 0);
        submatrix(mask) = submatrix(mask) + (2*pi) ;
        phase_diff_corrected{1, i}(rect_pos(2):rect_pos(2)+rect_pos(4), rect_pos(1):rect_pos(1)+rect_pos(3)) = submatrix;
    end
    
    temp_diff =  phase_diff_corrected{1,i}./ (alpha*gyro_mag_ratio*magnetic_field_0*echo_time) ;
    %mask = (temp_diff > -40) & (temp_diff < 40);
    temp_diff_masked = temp_diff;
    %temp_diff_masked(~mask) = 0;
    temp_map{end+1} = temp_diff_masked;
end


%% Show result.\
 % r = 16 Cx = 136, Cy = 94
%circlePos = [centerX - radius, centerY - radius, 2 * radius, 2 * radius];
%rect_pos = [120 78 32 32]; %x,y (left bottom),x increment, y increment
%rect_pos_2 = [120 132 13 12];

%temp_map = cellfun(@(phase_hi, phase_lo) phase_hi-phase_lo, unwrapped_phase_hi, unwrapped_phase, 'UniformOutput', false);
% region of probe = 0 whereas background = 1
%mask_bg = generateMask(rect_pos, temp_map{1,1}, "background", true );
%mask_bg = generateMask(rect_pos_2, mask_bg, "background", false );

image_ = temp_map;
image_phase = phase_diff_corrected;

mask_bg = generateMask_circle(circle_, image_{1,1}, "background", true );
%mask_bg = generateMask_circle(rect_pos_2, mask_bg, "background", false );

%region of probe = 1, background = 0
mask_fg = generateMask_circle(circle_, image_{1,1}, "foreground", true );

%sqaure coord = (210,135) (

mean_ = {}; 
var_ = {};
phase_ = {};

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
    phase_val = mean(probe_phase(~(isnan(probe_phase))),"all");

    std_bg = std(bg(~(isnan(bg))));
    snr = -mean_val / std_bg;
    
    snr_db = 10*log10(snr);

    imagesc(image_{1,i});
    %imagesc(image_phase{1,i}); % for without unwrap
    rectangle('Position',rect_pos,Curvature=[1,1])
    rectangle('Position',rect_pos_2, Curvature = [1,1])
        
    % Calculate the mean value of the region
    text(10, 20, ['Mean: ', num2str(mean_val, '%.3f'), 'rad'], ...
    'Color', 'black', 'FontSize', 12, 'FontWeight', 'bold');
    title(['Image ', num2str(i)]);

    text(10, 60, ['Drift: ', num2str(mean_drift_all{1,i}, '%.3f'), 'rad'], ...
    'Color', 'black', 'FontSize', 12, 'FontWeight', 'bold');
    title(['Image ', num2str(i)]);
    
    h = colorbar;
    mean_{end+1} = mean_val;
    var_{end+1} = std_val;
    phase_{end+1} = phase_val;
end
dcm = datacursormode;
dcm.Enable = 'on';
dcm.DisplayStyle = 'window';

%%
%save("./temp_data/new/FFE/algo_unwrap/trial1/trial1_" + A + "_" + B + ".mat","mean_","var_", "phase_");










