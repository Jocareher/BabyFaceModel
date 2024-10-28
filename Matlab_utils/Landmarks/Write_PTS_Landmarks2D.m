function Write_PTS_Landmarks2D(fileName, myLmk, visibility)
% Write_PTS_Landmarks2D writes the 2D landmark coordinates and visibility status to a .pts file.
%
% INPUT:
%   fileName   - Name of the .pts file to save.
%   myLmk      - A 2 x n matrix of 2D landmark coordinates.
%   visibility - A 1 x n vector with visibility status for each landmark (1 = visible, 0 = not visible).
%
% This function saves the coordinates of each landmark along with its visibility as an additional column.

    % Check that myLmk has the correct dimensions
    if size(myLmk, 1) ~= 2
        error('Input landmarks must be a 2 x n matrix');
    end

    % Check that visibility has the same number of columns as myLmk
    if length(visibility) ~= size(myLmk, 2)
        error('Visibility array must match the number of landmarks');
    end

    % Open the file for writing
    [fid, msg] = fopen(fileName, 'wt');
    if fid == -1
        error(msg);
    end

    % Write header information
    fprintf(fid, 'Version 1.0\n');
    fprintf(fid, '%d\n', size(myLmk, 2));  % Number of landmarks

    % Write each landmark coordinate with its visibility status
    for jL = 1:size(myLmk, 2)
        x = myLmk(1, jL);
        y = myLmk(2, jL);
        vis = visibility(jL);  % Extract visibility for this landmark
        
        fprintf(fid, 'S%04d  %.6f  %.6f  %d\n', jL-1, x, y, vis);  % Include visibility in the output
    end

    % Close the file
    fclose(fid);
end
