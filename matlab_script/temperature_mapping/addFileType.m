function addFileType(dirpath)

fileList = dir(dirpath);
        for i = 1:length(fileList)
            if (~ fileList(i).isdir)
                [~, f] = fileparts(fileList(i).name);
                %f = fileList(i).name;
                 if (contains(f,"IM"))
                     %new_f = f(1:7);
                     oldfile = convertCharsToStrings(dirpath + f);
                     newfile = oldfile.append(".dcm");
                     %newfile = convertCharsToStrings(folder_path + new_f);
                    movefile( oldfile,newfile );
                 else
                     continue;
                 end
            end

        end
end

