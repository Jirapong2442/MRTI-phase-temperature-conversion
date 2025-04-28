%% load data
clear;
clc; 
A = 30.4; % temperature at the first sensor for file name output
B = 31; % temperature at the second sensor for filename output 

path = "D:\HW\Y4T1\fyp\image data\new_trial\1\FFE\60";
path_hi = "D:\HW\Y4T1\fyp\image data\new_trial\1\FFE\" + B;

[mag_im,phase_im,real_im,img_im,echo] = read_im(path);
[mag_im_hi,phase_im_hi,real_im_hi, img_im_hi,echo_hi] = read_im(path_hi);

%% set condition and scanning parameters
% limit = pi / -0.1364 = 2.0271
algo_unwrap = true; 
drift_corr = true;
manual_unwrap= true;

echo_time = 0.017;
magnetic_field_0 = 3 ;
alpha = -0.01 ;
gyro_mag_ratio = 267.522187 ;

% x,y (left bottom),x increment, y increment
%trial1
rect_pos = [118 76 33 34];
rect_pos_2 = [106 165 32 32];

%trial2
%rect_pos = [122 77 33 34];
%rect_pos_2 = [106 163 32 32];

%% load field drift data
load('./temp_data/drift_correction/FFE/trial2.mat')
mean_drift = cell2mat(mean_drift_pair);
mean_drift = mean(mean_drift);

%% add file type for the first time analysis
% since some of the DICOM file doesnt have .dcm file type after the
% scanning. This will add the file type for further postprocesisng
%test_path2 = "D:\HW\Y4T1\fyp\image data\new_trial\phantom26032025_2\DICOM\00000001\";
%addFileType(test_path2);

%% unwrapping
%unwrap with sunwrap algorithm
if (algo_unwrap == true)
    [phase_unwrap] = unwrap_(mag_im,phase_im);
    [phase_hi_unwrap] = unwrap_(mag_im_hi,phase_im_hi);
      %temp_diff =  unwrap_phase./ (alpha*gyro_mag_ratio*magnetic_field_0*echo_time) ;%comment
end

%% complex subtraction
real_unwrap = cellfun(@(m,p) m.*cos(p),mag_im,phase_unwrap,'UniformOutput', false );
img_unwrap = cellfun(@(m,p) m.*sin(p),mag_im,phase_unwrap,'UniformOutput', false );
real_unwrap_hi = cellfun(@(m,p) m.*cos(p),mag_im_hi,phase_hi_unwrap,'UniformOutput', false );
img_unwrap_hi = cellfun(@(m,p) m.*sin(p),mag_im_hi,phase_hi_unwrap,'UniformOutput', false );

[phase_diff, mag_diff]  = complexSub(real_unwrap,img_unwrap,real_unwrap_hi,img_unwrap_hi);
%% circle mask generation
circle_ = [rect_pos(1)+rect_pos(3)/2 rect_pos(2)+rect_pos(3)/2 rect_pos(3)/2];
circle_2 =[rect_pos_2(1)+rect_pos_2(3)/2 rect_pos_2(2)+rect_pos_2(3)/2 rect_pos_2(3)/2];

mask_oil = generateMask_circle(circle_2, phase_diff{1,1}, "foreground", true );

%% drift correction
phase_corrected = {};

for i= 1:length(phase_diff)
    if (drift_corr == true)
        phase_corrected{1, i} = phase_diff{1, i} -mean_drift;
    else
        phase_corrected{1, i} = phase_diff{1, i};
    end
end

%% temperature mapping
temp_map = {};  
phase_map = {}; 
unwrap_phase = {};
phase_diff_corrected = phase_corrected;

for i= 1:length(phase_im_hi)
    if(manual_unwrap == true)
        submatrix = phase_diff_corrected{1, i}(rect_pos(2):rect_pos(2)+rect_pos(4), rect_pos(1):rect_pos(1)+rect_pos(3)); 
        if (drift_corr)
            mask = (submatrix <= - mean_drift); %change here
        else
            mask = (submatrix <= 0);
        end
        submatrix(mask) = submatrix(mask) + (2*pi) ;
        phase_diff_corrected{1, i}(rect_pos(2):rect_pos(2)+rect_pos(4), rect_pos(1):rect_pos(1)+rect_pos(3)) = submatrix;
    end
    
    temp_diff =  phase_diff_corrected{1,i}./ (alpha*gyro_mag_ratio*magnetic_field_0*echo_time) ;
    %mask = (temp_diff > -40) & (temp_diff < 40);  % to prevent extremities
    temp_diff_masked = temp_diff;
    %temp_diff_masked(~mask) = 0; % to prevent extremities
    temp_map{end+1} = temp_diff_masked;
end


%% Show result.\

%temp_map = cellfun(@(phase_hi, phase_lo) phase_hi-phase_lo, unwrapped_phase_hi, unwrapped_phase, 'UniformOutput', false);
% region of probe = 0 whereas background = 1
%mask_bg = generateMask(rect_pos, temp_map{1,1}, "background", true );
%mask_bg = generateMask(rect_pos_2, mask_bg, "background", false );

image_ = temp_map;
image_phase = phase_diff_corrected;

% circle = 0 bg =1 
mask_bg = generateMask_circle(circle_, image_{1,1}, "background", true );
%mask_bg = generateMask_circle(rect_pos_2, mask_bg, "background", false );

%region of probe = 1, background = Nan
mask_fg = generateMask_circle(circle_, image_{1,1}, "foreground", true );

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
    text(10, 10, ['Mean: ', num2str(mean_val, '%.3f'), '°C'], ...
    'Color', 'black', 'FontSize', 12, 'FontWeight', 'bold');
    title(['Image ', num2str(i)]);

    text(10, 30, ['SNR: ', num2str(snr_db, '%.3f'), ' db'], ...
    'Color', 'black', 'FontSize', 12, 'FontWeight', 'bold');
    title(['Image ', num2str(i)]);
    
    if(drift_corr)
        text(10, 50, ['Drift: ', num2str(mean_drift, '%.3f'), 'rad'], ...
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
%img_name = strcat('D:\HW\Y4T1\fyp\output\New\UW_CS_new\FFE_DC_constant\1/',  num2str(A) , '_',  num2str(B) , '.png') ; 
%saveas(gcf,img_name) ;
%save("./temp_data/new/UW_CS_new/FFE/DC/1/trial1_" + A + "_" + B + ".mat","mean_","std_", "phase_","snr");










