function rewrite_name(max,folder_path)
% image run number until 2048. So if we want to further process the image
% that has a mixture of 2045 and 0001, this script change the filename to
% keep up with the order of image sequence
    fileList = dir(fullfile(folder_path, '*.dcm'));
    for i = 1:length(fileList)
        if (str2num(fileList(i).name(4:7)) <= max)
             oldfile = convertCharsToStrings(folder_path + "\"+ fileList(i).name);
             newfile = folder_path + "\IM_" + num2str(str2num(fileList(i).name(4:7)) + 2048) + ".dcm";
             movefile( oldfile,newfile );
        end
    end
end

