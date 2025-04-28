function [mag_,phase_,real_,img_,echo] =  read_im(folder_path)
% function to output image of different types and echo time from a defined
% path
% input: folder of the image scanned at one temperature. it should include:
%           4 types of image (Magnitude, Real, Imaginary, Phase) 
%           All echotime scanned
%           All slices
% output: Magnitude, Real, Imaginary, Phase image, echo_time
%         each image class compose of: 
%       [slice1 te1 M, slice2 te2 M, ..., sliceN teN M]..,
%       [slice1 te1 R, slice2 te2 R, ..., sliceN teN R]..,
%       [slice1 te1 I, slice2 te2 I, ..., sliceN teN I].., 
%       [slice1 te1 P, slice2 te2 P, ..., sliceN teN P] 

    mag_ = {};
    phase_ = {};
    real_ = {};
    img_ = {};
    echo = {};
    fileList = dir(fullfile(folder_path, '*.dcm'));

    if (isempty(fileList))
        fileList = dir(folder_path);
        for i = 1:length(fileList)
            if (~ fileList(i).isdir)
                [~, f] = fileparts(fileList(i).name);
                %f = fileList(i).name;
                 if (contains(f,"IM"))
                     %new_f = f(1:7);
                     oldfile = convertCharsToStrings(folder_path + f);
                     newfile = oldfile.append(".dcm");
                     %newfile = convertCharsToStrings(folder_path + new_f);
                    movefile( oldfile,newfile );
                 else
                     continue;
                 end
            end

        end
    end
    %%
    for i = 1:length(fileList)
    
        fileName = fileList(i).name;
        filePath = fullfile(folder_path, fileName);
    
        data = dicomread(filePath);
        info = dicominfo(filePath);  % Optional: Read metadata
        
        num_echo = info.EchoTrainLength;
        if i <= num_echo
            echo{end+1} = info.EchoTime /1000;
        end
        imtype = split(info.ImageType, '\');
    
        if  any(strcmp(imtype, 'M'))
            mag = double(data);
            rescaled_mag = mag*info.RescaleSlope + info.RescaleIntercept;
            mag_{end+1} = rescaled_mag ./ 1000;
            disp(['Read file: ', fileName]);
        end
    
        if  any(strcmp(imtype, 'P'))
            phase = double(data);
            rescaled_phase = (phase*info.RescaleSlope + info.RescaleIntercept)./1000;
            phase_{end+1} = rescaled_phase ;
            disp(['Read file: ', fileName]);
        end

        if  any(strcmp(imtype, 'R'))
            real = double(data);
            rescaled_real = real*info.RescaleSlope + info.RescaleIntercept;
            real_{end+1} = rescaled_real./1000;
            disp(['Read file: ', fileName]);
        end
    
        if  any(strcmp(imtype, 'I'))
            img = double(data);
            rescaled_img = (img*info.RescaleSlope + info.RescaleIntercept);
            img_{end+1} = rescaled_img./1000;
            disp(['Read file: ', fileName]);
        end


    end
end
