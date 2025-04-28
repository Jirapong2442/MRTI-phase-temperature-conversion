function [real,img] = getRealImag(mag,phase)
% input: magnitude and phase image (output type cell)
% output: real and imginary image (output type cell)
real = cellfun(@(m,p) m.*cos(p),mag,phase,'UniformOutput', false );
img = cellfun(@(m,p) m.*sin(p),mag,phase,'UniformOutput', false );
end

