clc
clear
temp_path = "./temp_data/new/UW_CS_new/DEGRE/DC/1/";
all_file =  dir(temp_path + '*.mat');
temp_all = {};
std_all = {};
phase_all ={};
mean_drift ={};
snr_all = {};

echo_time = 0.017;
magnetic_field_0 = 3 ;
alpha = -0.01 ;
gyro_mag_ratio = 267.522187 ;

%adjustable
temp_list_FFE = [52 59 59.5 65.99]; %trial1 a b and trial2 a b
temp_list_DE = [49.6 56.74 57.1 64.1]; %trial 1 a b and trial2 a b
getPhase = true;

begin_tmp = temp_list_DE(2);
slice = [1 2]; %a = 34 b = 12
%measured_tmp_lo = [52 46.9 42.6 38 34.6 30.01]; %trial 2 a 
%measured_tmp_lo = [60.2 54.79 49.26 42.99 37.87 31.03]; %FFE trial2 b
%measured_tmp_lo = [52.72 47 41.8 36.28 31]; %FFE trial 1b
%measured_tmp_lo = [45.67 41 37 33.8 30.4]; %FFE trial 1a

%measured_tmp_lo = [44.25 40.25 36.72 33.55 30]; %DE trial 1a
measured_tmp_lo = [51.07 45.9 40.81 35.71 30.67]; %DE trial 1b
%measured_tmp_lo = [50.49 45.72 41.84 37.47 34.26 29.8]; %DE trial 2a
%measured_tmp_lo = [58.05 53.02 48.03 42.04 35.74 30.65]; %DE trial 2b

%% start slicing
for q = 1:length(all_file) 
    load(temp_path + all_file(q).name); 
    d1_sqr = (mean_{slice(1)} - mean_{slice(2)})^2;
    d2_sqr = (mean_{slice(2)} - mean_{slice(1)})^2;

    temp_all{end+1}= (mean_{slice(1)} + mean_{slice(2)})/2 ;%equal data point
    std_all{end +1} = sqrt( (std_{slice(1)}^2 + std_{slice(2)}^2 + d1_sqr + d2_sqr) / 2);
    phase_all{end+1} = (phase_{slice(1)} + phase_{slice(2)})/2;
    mean_drift{end+1} = (mean_drift_all{slice(1)} + mean_drift_all{slice(2)})/2;
    snr1 = snr{slice(1)};
    snr2 = snr{slice(2)};
    lsnr1 = 10^(snr1/10);
    lsnr2 = 10^(snr2/10);
    av_snr = (lsnr2 + lsnr1) / 2;

    snr_all{end+1} = 10*log10(av_snr);

 end
%% plot data
% DEGRE: trial 1, 34.2 37.5 41, trial2 34,40,48

phase_shift_all = cell2mat(phase_all) ./ (gyro_mag_ratio*magnetic_field_0*echo_time) ;
tmp_change = measured_tmp_lo - begin_tmp;
[p,s] = polyfit(tmp_change,sort(phase_shift_all),1);
%tmp = phase / (alpha*gyro_mag_ratio*magnetic_field_0*echo_time)
% alpha = (phase / (gyro_mag_ratio*magnetic_field_0*echo_time)) / tmp
%% show data
curr_tem = measured_tmp_lo;
%estimated_var = [std_all{4} std_all{2} std_all{1} std_all{3}];

%trial2
%estimated_temp = [begin_tmp+temp_all{6} begin_tmp+temp_all{5} begin_tmp+temp_all{4} begin_tmp+temp_all{3} begin_tmp+temp_all{2} begin_tmp+temp_all{1}];
%estimated_var = [std_all{6} std_all{5} std_all{4} std_all{3} std_all{2} std_all{1}];

%for trial 1
estimated_temp = [begin_tmp+temp_all{5} begin_tmp+temp_all{4} begin_tmp+temp_all{3} begin_tmp+temp_all{2} begin_tmp+temp_all{1}];
estimated_var = [std_all{5} std_all{4} std_all{3} std_all{2} std_all{1}];


if (getPhase == true)

    DM = [tmp_change(:), ones(size(tmp_change(:)))];
    y1 = DM * p(:);
    
    figure(1)

    scatter(tmp_change,sort(phase_shift_all)) %make a graph of data point for i=1:n %loop to calculate summition
    hold on
    plot(tmp_change,y1)
    hold off
    dy='phase shift (Φ/γBTE in ppm)';
    ylab = sprintf('%s ',dy);
    ylabel(ylab,'FontSize',12) 
    dx='temperature shift (°C)';
    xlab = sprintf('%s ',dx);
    xlabel(xlab,'FontSize',12) 
    fl='phase temperature relationship';
    tit = sprintf('%s %s  ',fl);
    title(tit,'FontSize',12)
    text(-15, 0.16, sprintf('α = %.5f \\cdot offset = %.5f',p))
    saveas(gcf,'D:/HW/Y4T1/fyp/output/compare_groundtruth/new/alpha_recab/DE_dc/trial1_b.png');


else
    plot(curr_tem, curr_tem, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Ground truth temperature');
    set(gca, 'XDir','reverse')
    hold on;
    
    errorbar(curr_tem,estimated_temp,estimated_var, 'o-b', 'LineWidth', 1.5, 'Color', 'b', 'DisplayName', 'estimated temperature')
    x = curr_tem;
    y1 = estimated_temp;
    err = estimated_var; 
    for i = 1:length(x)
        % Place the text slightly above the error bar
        text(x(i)+0.7, y1(i)+ 1, sprintf('(%.2f, ', x(i)), ...
             'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'r');
        text(x(i)-0.3, y1(i)+ 1, sprintf('%.2f)', y1(i)), ...
             'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'b');
    end
    
    ylim([20 70]);
    legend('show');
    grid on;
    
    xlabel("ground truth temperature");
    ylabel("estimated temperature");
    hold off;
    %saveas(gcf,'D:/HW/Y4T1/fyp/output/compare_groundtruth/new/DE_DC/trial2_b.png');
end


