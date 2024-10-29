function Write_PTS_Landmarks2D(fileName, myLmk, visibility)
% Write_PTS_Landmarks2D writes the 2D landmark coordinates with optional visibility status to a .pts file.
%
% INPUT:
%   fileName   - Name of the .pts file to save.
%   myLmk      - A 2 x n matrix of 2D landmark coordinates.
%   visibility (optional) - A 1 x n vector with visibility status for each landmark (1 = visible, 0 = not visible).
%
% This function saves the coordinates of each landmark. If visibility data is provided,
% it includes it as an additional column; otherwise, it saves only the coordinates.

    % Check that myLmk has the correct dimensions
    if size(myLmk, 1) ~= 2
        error('Input landmarks must be a 2 x n matrix');
    end

    % Open the file for writing
    [fid, msg] = fopen(fileName, 'wt');
    if fid == -1
        error(msg);
    end

    % Write header information
    fprintf(fid, 'Version 1.0\n');
    fprintf(fid, '%d\n', size(myLmk, 2));  % Number of landmarks

    % Write each landmark coordinate with optional visibility
    if nargin < 3 || isempty(visibility)
        % Write without visibility if not provided
        for jL = 1:size(myLmk, 2)
            fprintf(fid, 'S%04d  %.6f  %.6f\n', jL-1, myLmk(1, jL), myLmk(2, jL));
        end
    else
        % Check that visibility has the same number of columns as myLmk
        if length(visibility) ~= size(myLmk, 2)
            error('Visibility array must match the number of landmarks');
        end
        
        % Write with visibility
        for jL = 1:size(myLmk, 2)
            fprintf(fid, 'S%04d  %.6f  %.6f  %d\n', jL-1, myLmk(1, jL), myLmk(2, jL), visibility(jL));
        end
    end

    % Close the file
    fclose(fid);
end
