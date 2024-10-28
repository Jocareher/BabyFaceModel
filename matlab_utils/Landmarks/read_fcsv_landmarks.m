function lmks = read_fcsv_landmarks(fcsv_file, varargin)

    lmkNames = {};
    if nargin > 0
        fileID = fopen(varargin{1},'r');
        lmkNames = textscan(fileID,'%s');
        lmkNames = lmkNames{1};
        fclose(fileID);
    end
    
    
    [lmksFile_dir, lmksFile_name] = fileparts( fcsv_file ); 
    copyfile(fcsv_file, fullfile(lmksFile_dir, [lmksFile_name, '.csv']));
    
    warning('off')
    T = readtable(fullfile(lmksFile_dir, [lmksFile_name, '.csv']));
    warning('on')
    delete( fullfile(lmksFile_dir, [lmksFile_name, '.csv']) );   
    
    if ~isempty( lmkNames ) && length( lmkNames ) ~= size(T,1)
        warning('Mismatch in number of provided landmark names and landmarks. Ignoring landmark names.')
    end
    
    lmks = NaN(3,size(T,1));
    repeat = false;
    for k = 1:size(T,1)
        if isempty(lmkNames), idx = k;
        else
            idx = strcmp(lmkNames, T.label(k));
            if isempty(idx) || sum(idx) < 1
                warning('Name of landmark in FCSV file not found in provided list of landmark names. Ignoring landmark names.')
                repeat = true;
                break;
            elseif sum(idx) > 1
                warning('Name of landmark in FCSV file found more than once in provided list of landmark names. Ignoring landmark names.')
                repeat = true;
                break;
            end
        end
        
        lmks(1,idx)= T.x(k);
        lmks(2,idx)= T.y(k);
        lmks(3,idx)= T.z(k);
    end
    
    if repeat
        lmks = NaN(3,size(T,2));
        for k = 1:size(T,2)
            lmks(1,idx)= T.x(k);
            lmks(2,idx)= T.y(k);
            lmks(3,idx)= T.z(k);
        end
    end



end

