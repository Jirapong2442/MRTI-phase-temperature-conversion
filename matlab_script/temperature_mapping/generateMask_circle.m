function [mask_out] = generateMask_circle(boundary_, image_, type_, new_mask_)
% generate circle mask from the input boundary
% input:1. boundary of circle indicating [centerX, centerY, radius]
%       2. image_ to be masked
%       3. type of mask: foreground, image will be zero except mask region
%                      background, image will be one except mask region
%       4. new_mask_: boolean operator
%                   if true, output will output of the new mask
%                   if false, the input image must be a mask and new mask
%                   will be map on the old mask resulting (add another mask to 
%                   the mask image) 
% output: mask of the input image at the region of interest
         %mask of the mask at the region of interest

radius = boundary_(3);
centerX = boundary_(1);
centerY = boundary_(2);
%new_mask_ == true when new mask is generated from rectangle of interest.
[cols, rows] = meshgrid(1:size(image_, 2), 1:size(image_, 1));
distanceFromCenter = sqrt((rows - centerY).^2 + (cols - centerX).^2);
circleMask = distanceFromCenter <= radius;

    if new_mask_
        if type_ == "foreground"
            fore = zeros(size(image_));
            fore(circleMask) = 1;
            mask_out = fore;
            
       end
    
        if type_ == "background"
            bg = ones(size(image_));      
            bg(circleMask) = 0; 
            mask_out = bg;
        end 
    
    else
        if type_ == "foreground"
            %fore = zeros(image_);
            image_( circleMask) = 1;
            mask_out = image_;
    
        end
    
        if type_ == "background"
            %bg = ones(image_);
            image_( circleMask) = 0;
            mask_out = image_;
        end 
        
    end

end

