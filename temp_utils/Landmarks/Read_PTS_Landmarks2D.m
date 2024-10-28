function landmarks = Read_PTS_Landmarks2D(fileName)
% READ_PTS_Landmarks2D Reads 2D landmarks from a PTS file.
%
% This function reads 2D landmark coordinates from a PTS file, which is a common
% format for storing annotated landmark points. The function parses the file and
% extracts the x and y coordinates of the landmarks.
%
% INPUT:
% - fileName: String, the path and name of the PTS file to be read.
%
% OUTPUT:
% - landmarks: 2xN matrix, where N is the number of landmarks. The first row contains
%              the x coordinates, and the second row contains the y coordinates.
%
% The PTS file is expected to have the following structure:
% - The first line is a version identifier (ignored by this function).
% - The second line contains the number of landmarks.
% - The subsequent lines contain the x and y coordinates of each landmark.

    
% Open the PTS file for reading
[fid, msg] = fopen(fileName, 'rt');
if fid == -1
    error(msg); % If the file cannot be opened, display an error message
end

fgetl(fid); % Skip the version identifier line
nLandmarks = str2num(fgetl(fid)); % Read the number of landmarks
landmarks = zeros(2, nLandmarks); % Initialize a matrix to store the landmark coordinates

% Read each landmark coordinate from the file
for j = 1:nLandmarks
    newLine = fgetl(fid); % Read the next line
    [token, remain] = strtok(newLine); % Tokenize the line to extract the x coordinate
    [token, remain] = strtok(remain); % Move to the y coordinate
    landmarks(1, j) = str2num(token); % Store the x coordinate
    [token, remain] = strtok(remain); % Move to the remaining part of the line
    landmarks(2, j) = str2num(token); % Store the y coordinate
    % landmarks(3, j) = str2num(remain); % This line is commented out, presumably for 3D coordinates
end

fclose(fid); % Close the file
