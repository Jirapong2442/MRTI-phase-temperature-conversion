function [phase_im_unwrap] = unwrap_(magnitudeImages,phaseImages)
% unwrap the phase image with a selected algorithm
% the fasted algorithm that yield acceptable unwrapped data is unwrap2
% adapted from https://github.com/geggo/phase-unwrap
% 
% input: magnitude and phase image 
%       
% output:phase unwrapped image

    phase_im_unwrap = {};
    addpath('./Unwrap_TIE_DCT_Iter.m/');
    addpath('./@unwrap2/');

    for i= 1:length(phaseImages)
        complex = magnitudeImages{1,i} .* exp(1i * phaseImages{1,i});
        %unwrap_phase = Unwrap_TIE_DCT_Iter(phaseImages{1,i}); 90s (1 TE, 14 slices) 
        %unwrap_phase = sunwrap(complex{1,i}); 30s (1 TE, 14 slices) 
        unwrap_phase = unwrap2(phaseImages{1,i}); %~1s (1 TE, 14 slices) 
        phase_im_unwrap{end+1} = unwrap_phase;
    end

end

