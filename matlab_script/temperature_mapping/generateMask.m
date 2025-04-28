function [mask_out] = generateMask(boundary_, image_, type_, new_mask_)
% generate square mask from the input boundary
% input:1. boundary of squre indicating [x_left, y_bottom, x_increment,
%                                                       y_increment]
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


    if new_mask_
        if type_ == "foreground"
            fore = zeros(size(image_));
            fore( boundary_(2):boundary_(2)+boundary_(4), boundary_(1):boundary_(1)+boundary_(3)) = 1;
            mask_out = fore;
    
        end
    
        if type_ == "background"
            bg = ones(size(image_));
            bg( boundary_(2):boundary_(2)+boundary_(4), boundary_(1):boundary_(1)+boundary_(3)) = 0;
            mask_out = bg;
        end 
    
    else
        if type_ == "foreground"
            %fore = zeros(image_);
            image_( boundary_(2):boundary_(2)+boundary_(4), boundary_(1):boundary_(1)+boundary_(3)) = 1;
            mask_out = image_;
    
        end
    
        if type_ == "background"
            %bg = ones(image_);
            image_( boundary_(2):boundary_(2)+boundary_(4), boundary_(1):boundary_(1)+boundary_(3)) = 0;
            mask_out = image_;
        end 
        
    end

end

