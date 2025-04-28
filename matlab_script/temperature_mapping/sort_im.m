function [TE_val] = sort_im(im,num_echoes,slices)
% sort image by echotime and slice
% input: 
%   1. image cell data in the format of 
%        ->   [slice1 et1 real, slice1 et2 real,....., sliceN etN phase] 
%   2. num_echoes: to construct the key for struct 
%   3. slice: to allocate cell inside each key of struct 
% output:
%   struct where keys are echo time. In each echo time, the all slices of
%   4 image type of that echo time will be stored

    if num_echoes <= 0 || ~isnumeric(num_echoes) || ~isscalar(num_echoes)
        error('num_echoes must be a positive integer.');
    end
    
    % Initialize empty struct
    TE_val = struct();
    
    % Dynamically create fields te1, te2, ..., teN
    for i = 1:num_echoes
        field_name = ['te' num2str(i)];
        TE_val.(field_name) = [];
    end
    
    name_all = fieldnames(TE_val);
    index = 0;

    for i = 1:num_echoes:num_echoes*slices
        for j = 1:length(name_all) %each echo = 1st slice, 2nd slice
            name = name_all{j};
            if i == 1
                index = j;
            else
                index = index + 1;
            end
            TE_val.(name) = [TE_val.(name),im{1,index}]; 
        end
    end

    rowSizes = size(im{1,1},1); 
    colSizes = repmat(rowSizes, 1, slices);
    field = fieldnames(TE_val);
    
    for i=1:length(field)
        name = field{i};
        TE_val.(name) = mat2cell(TE_val.(name), rowSizes, colSizes);    
    end

end

