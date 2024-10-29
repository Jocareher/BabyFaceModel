function [landmarks, visibility] = Read_PTS_Landmarks2D(fileName)
% READ_PTS_Landmarks2D Reads 2D landmarks and optional visibility data from a PTS file.
%
% This function reads 2D landmark coordinates from a PTS file, with an optional visibility column.
% If visibility information is present, it returns a visibility vector; otherwise, it returns only the coordinates.
%
% INPUT:
% - fileName: String, the path and name of the PTS file to be read.
%
% OUTPUT:
% - landmarks: 2xN matrix, where N is the number of landmarks. The first row contains
%              the x coordinates, and the second row contains the y coordinates.
% - visibility (optional): 1xN vector indicating visibility (1 = visible, 0 = not visible).
%              This output is only provided if visibility data is in the file.

    % Open the PTS file for reading
    [fid, msg] = fopen(fileName, 'rt');
    if fid == -1
        error(msg); % If the file cannot be opened, display an error message
    end

    fgetl(fid); % Skip the version identifier line
    nLandmarks = str2double(fgetl(fid)); % Read the number of landmarks
    landmarks = zeros(2, nLandmarks); % Initialize a matrix to store the landmark coordinates
    visibility = []; % Initialize visibility as an empty array by default

    % Read each landmark coordinate from the file
    hasVisibility = false; % Flag to check if visibility is present
    for j = 1:nLandmarks
        newLine = fgetl(fid); % Read the next line
        data = sscanf(newLine, 'S%d %f %f %d'); % Try reading with visibility
        
        % If only three values were read, there's no visibility column
        if length(data) == 3
            landmarks(:, j) = data(2:3);
        elseif length(data) == 4
            landmarks(:, j) = data(2:3);
            visibility(j) = data(4); % Store visibility
            hasVisibility = true;
        end
    end

    % Close the file
    fclose(fid);

    % If no visibility column was found, return only landmarks
    if ~hasVisibility
        visibility = []; % Empty visibility if not detected
    end
end
