function [phase_diff, mag_diff] = complexSub(real_pre,img_pre,real_post,img_post)
% perform a complex subtraction (find phase difference) on two complex image
% input: real and imaginary image of two complex image we would love to
%        find a phase difference
% output: phase and magnitude difference of two image

    phase_diff = cellfun(@(r_pre,i_pre,r_post,i_post) atan2( ((r_pre.*i_post) - (r_post.*i_pre)), ((r_pre .*r_post) + (i_post.*i_pre)) ), real_pre,img_pre,real_post,img_post, 'UniformOutput', false);
    mag_diff = cellfun(@(r_pre,i_pre,r_post,i_post) sqrt(((r_pre.*i_post) - (r_post.*i_pre)).^2 + ((r_pre .*r_post) + (i_post.*i_pre)).^2 ), real_pre,img_pre,real_post,img_post, 'UniformOutput', false);
    
end

