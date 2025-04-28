function [TE_val] = sort_im(im)
% now it is used for 11 TE
% assume has 7 slices per TE
    TE_val = struct();
    TE_val.te1 = [];
    TE_val.te2= [];
    TE_val.te3 = [];
    TE_val.te4 = [];
    TE_val.te5 = [];
    TE_val.te6 = [];
    TE_val.te7 = [];
    TE_val.te8 = [];
    TE_val.te9 = [];
    TE_val.te10 = [];
    TE_val.te11 = [];
    
    for i = 1:11:77
        TE_val.te1 = [TE_val.te1 ,im{1,i}];
        TE_val.te2 = [TE_val.te2 ,im{1,i+1}];
        TE_val.te3 = [TE_val.te3 ,im{1,i+2}];
        TE_val.te4 = [TE_val.te4 ,im{1,i+3}];
        TE_val.te5 = [TE_val.te5 ,im{1,i+4}];
        TE_val.te6 = [TE_val.te6 ,im{1,i+5}];
        TE_val.te7 = [TE_val.te7 ,im{1,i+6}];
        TE_val.te8 = [TE_val.te8 ,im{1,i+7}];
        TE_val.te9 = [TE_val.te9 ,im{1,i+8}];
        TE_val.te10 = [TE_val.te10 ,im{1,i+9}];
        TE_val.te11 = [TE_val.te11 ,im{1,i+10}];
    end

    rowSizes = size(im{1,1},1); 
    colSizes = repmat(rowSizes, 1, 7);
    field = fieldnames(TE_val);
    
    for i=1:length(field)
        name = field{i};
        TE_val.(name) = mat2cell(TE_val.(name), rowSizes, colSizes);    
    end

end

