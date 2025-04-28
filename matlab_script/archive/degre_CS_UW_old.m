%% test
clear
clc
A = 29.95;
B = 30.87;

path = "D:\HW\Y4T1\fyp\image data\new_trial\2\DEGRE\65.6";
path_hi = "D:\HW\Y4T1\fyp\image data\new_trial\2\DEGRE\" + B;
rename = false ;
% limit = pi / -0.1364 = 23.0271
algo_unwrap = false; 
manual_unwrap= ~algo_unwrap;

drift_corr =true;

if (rename == true)
    rewrite_name(24,path_hi);
end

[mag_im,phase_im,real_im,img_im] = read_im(path);
[mag_im_hi,phase_im_hi,real_im_hi,img_im_hi] = read_im(path_hi);

real_map_te1 = real_im(1:2:end);  % Even indices (echo 1)
real_map_te2 = real_im(2:2:end);  % Odd indices (echo 2)
img_map_te1 = img_im(1:2:end);  
img_map_te2 = img_im(2:2:end); 

ref_real_map_te1 = real_im_hi(1:2:end);  
ref_real_map_te2 = real_im_hi(2:2:end);
ref_img_map_te1 = img_im_hi(1:2:end);  
ref_img_map_te2 = img_im_hi(2:2:end);
%% complex subtraction
[phase_diff, mag_diff] = complexSub(real_map_te2,img_map_te2,real_map_te1,img_map_te1);
[ref_phase_diff, ref_mag_diff]= complexSub(ref_real_map_te2,ref_img_map_te2,ref_real_map_te1,ref_img_map_te1);

diff = cellfun(@(p,m) m .* exp(1i * p),phase_diff,mag_diff,'UniformOutput', false );
real_diff = cellfun(@real,diff, 'UniformOutput', false);
img_diff = cellfun(@imag,diff, 'UniformOutput', false);

ref_diff = cellfun(@(p,m) m .* exp(1i * p),ref_phase_diff,ref_mag_diff,'UniformOutput', false );
ref_real_diff = cellfun(@real,ref_diff, 'UniformOutput', false);
ref_img_diff = cellfun(@imag,ref_diff, 'UniformOutput', false);

[delta_phi_diff, delta_mag_diff] = complexSub(ref_real_diff,ref_img_diff,real_diff,img_diff);

%% temp map
echo_time = 0.0191 - 0.00379; %TE2-TE1
magnetic_field_0 = 3 ;
alpha = -0.01 ;
gyro_mag_ratio = 267.522187 ;

rect_pos = [240 156 64 64];
rect_pos_2 = [210 330 60 60];

phase_diff = delta_phi_diff;

circle_2 =[rect_pos_2(1)+rect_pos_2(3)/2 rect_pos_2(2)+rect_pos_2(3)/2 rect_pos_2(3)/2];
mask_fg = generateMask_circle(circle_2, phase_diff{1,1}, "foreground", true );

temp_map = {};  
phase_map = {}; 
unwrap_phase = {};

if (algo_unwrap == true)
[complex, phase_diff] = unwrap(delta_mag_diff,delta_phi_diff);
      %temp_diff =  unwrap_phase./ (alpha*gyro_mag_ratio*magnetic_field_0*echo_time) ;%comment
end


for i= 1:length(phase_diff)
    if(manual_unwrap == true)
        submatrix = phase_diff{1, i}(rect_pos(2):rect_pos(2)+rect_pos(4), rect_pos(1):rect_pos(1)+rect_pos(3));          
        mask = (submatrix < 0);
        submatrix(mask) = submatrix(mask) + 2*pi ;
        phase_diff{1, i}(rect_pos(2):rect_pos(2)+rect_pos(4), rect_pos(1):rect_pos(1)+rect_pos(3)) = submatrix;
    end

    if(drift_corr == true)
        check_corr = phase_diff{1, i};
        check_corr(mask_fg == 0) =NaN;
        mean_drift = mean(check_corr(~(isnan(check_corr))),"all");
        phase_diff{1, i} = phase_diff{1, i} -mean_drift;
    end
    
    
    temp_diff =  phase_diff{1,i}./ (alpha*gyro_mag_ratio*magnetic_field_0*echo_time) ;
    %mask = (temp_diff > -40) & (temp_diff < 40);
    temp_diff_masked = temp_diff;
    %temp_diff_masked(~mask) = 0;
    temp_map{end+1} = temp_diff_masked;
end

%% show results
%rect_pos = [220 140 70 65]; %x,y (left bottom),x increment, y increment
%rect_pos_2 = [235 255 35 25];

% region of probe = 0 whereas background = 1

circle_ = [rect_pos(1)+rect_pos(3)/2 rect_pos(2)+rect_pos(3)/2 rect_pos(3)/2];
[cols, rows] = meshgrid(1:size(phase_diff{1,1}, 2), 1:size(phase_diff{1,1}, 1));
distanceFromCenter = sqrt((rows - circle_(2)).^2 + (cols - circle_(1)).^2);
circleMask = distanceFromCenter <= circle_(3);

mask_bg = generateMask_circle(circle_, temp_map{1,1}, "background", true );
mask_fg = generateMask_circle(circle_, temp_map{1,1}, "foreground", true );

%mask_bg = generateMask(rect_pos, temp_map{1,1}, "background", true );
%mask_bg = generateMask(rect_pos_2, mask_bg, "background", false );
%region of probe = 1, background = 0
%mask_fg = generateMask(rect_pos, temp_map{1,1}, "foreground", true );

mean_ = {}; 
var_ = {};
phase_ = {};

for i = 1:length(temp_map)
    subplot(2, 4, i);  % Create a subplot

    % apply mask to image calculate the    
    bg = temp_map{1,i};
    probe = temp_map{1,i};
    probe_phase = phase_diff{1,i};

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

    %imagesc(phase_diff{1,i});
    imagesc(temp_map{1,i});
    rectangle('Position',rect_pos, Curvature = [1,1])
    rectangle('Position',rect_pos_2  , Curvature = [1,1])    

    text(10, 20, ['Mean: ', num2str(mean_val, '%.3f'), '°C'], ...
    'Color', 'black', 'FontSize', 12, 'FontWeight', 'bold');
    title(['Image ', num2str(i)]);

    %text(10, 60, ['SNR: ', num2str(snr_db, '%.3f'), 'db'], ...
    %'Color', 'black', 'FontSize', 12, 'FontWeight', 'bold');
    %title(['Image ', num2str(i)]);

    h = colorbar;
    mean_{end+1} = mean_val;
    var_{end+1} = std_val;
    phase_{end+1} = phase_val;
end
dcm = datacursormode;
dcm.Enable = 'on';
dcm.DisplayStyle = 'window';

%%
%save("./temp_data/new/DEGRE/algo_unwrap/trial2/trial2_" + A + "_" + B + ".mat" ,"mean_","var_","phase_");








