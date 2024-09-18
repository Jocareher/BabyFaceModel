function [visibleF, zbuff, colour, map_2Dto3D, varargout] = z_buffering_modif(coord, faces, RGB, K, T, D, varargin)
% z_buffering_modif Performs z-buffering to project a 3D mesh onto a 2D image plane and computes visibility.
%
% This function performs a z-buffering algorithm to project a 3D mesh onto a 2D image. It also calculates the visibility 
% of landmarks based on their depth compared to the z-buffer. The function supports landmark projection and color 
% rendering.
%
% INPUT:
%   coord           - 3D coordinates of the mesh vertices (N x 3 matrix).
%   faces           - Indices of the triangles (faces) of the mesh (3 x F matrix).
%   RGB             - Texture or color data for the mesh (N x 3 matrix).
%   K               - Camera intrinsic matrix (3 x 3 matrix).
%   T               - Transformation matrix for 3D coordinates (4 x 4 matrix).
%   D               - Distortion coefficients for the camera (1 x 5 vector or empty).
%   varargin        - Optional parameters:
%                       'Landmarks' - Indices of landmarks (for visibility check).
%                       'scale_for_imgSize' - Scaling factor for image size.
%                       'verbose' - Flag for verbosity (boolean).
%
% OUTPUT:
%   visibleF        - List of visible faces.
%   zbuff           - Z-buffer containing the depth values for each pixel.
%   colour          - RGB image with texture data.
%   map_2Dto3D      - Map of 2D pixel coordinates to corresponding 3D coordinates.
%   varargout       - Projected 2D landmark positions and their visibility status (if landmarks are provided).
    
    verbose = 0;  % Initialize verbosity flag
    scale_for_imgSize = 13e-5;  % Default scaling factor for image size
    lmks = [];  % Initialize landmarks

    % Process additional arguments
    while ~isempty(varargin)
        if strcmp(varargin{1}, 'Landmarks')
            lmks = varargin{2};  % Assign landmarks if provided
            varargin(1:2) = [];
        elseif strcmp(varargin{1}, 'verbose')
            verbose = 1;  % Enable verbose output
            varargin(1) = [];
        elseif strcmpi(varargin{1}, 'scale_for_imgSize')
            scale_for_imgSize = varargin{2};  % Assign custom scale for image size
            varargin(1:2) = [];
        else
            error('Unexpected input argument.');
        end
    end

    % Transform all 3D coordinates using the transformation matrix T
    coord_hom = [coord', ones(size(coord, 2), 1)];  % Convert to homogeneous coordinates (N x 4)
    coord_transformed = (T * coord_hom')';  % Apply the transformation matrix (N x 4)
    coord_transformed = coord_transformed(:, 1:3);  % Keep only the first 3 coordinates (N x 3)

    % Project all 3D points to 2D using the camera intrinsic matrix K
    [all_projected, valid] = projectPoints([coord_transformed, RGB], K, [], D, [], false);

    % Determine the bounds of the projected points
    xl = min(all_projected(valid, 1));  % Minimum x-coordinate
    xr = max(all_projected(valid, 1));  % Maximum x-coordinate
    yd = min(all_projected(valid, 2));  % Minimum y-coordinate
    yu = max(all_projected(valid, 2));  % Maximum y-coordinate
    nRows = (yu - yd) / scale_for_imgSize;  % Number of rows in the image
    nCols = (xr - xl) / scale_for_imgSize;  % Number of columns in the image
    imgSize = ceil([nRows, nCols]) + [10, 10];  % Add padding to the image size
    halfCellX = (xr - xl) / (2 * (imgSize(2) - 1));  % Half of the pixel width
    halfCellY = (yu - yd) / (2 * (imgSize(1) - 1));  % Half of the pixel height

    % Initialize output matrices
    zbuff = Inf * ones(imgSize);  % Z-buffer to store depth values (initialized to infinity)
    colour = 255 * ones([imgSize, 3]);  % Image color data (initialized to white)
    map_2Dto3D = Inf * ones([imgSize, 3]);  % Map from 2D pixels to 3D coordinates
    visibleF = zeros(imgSize);  % Initialize visible faces matrix

    % Initialize variables for landmarks
    if ~isempty(lmks)
        lmks_img = zeros(length(lmks), 2);  % Array to store 2D landmark positions
        lmk_visibility = false(length(lmks), 1);  % Boolean array for landmark visibility
        lmks3D = coord(:, lmks)';  % Extract the 3D coordinates of the landmarks (N x 3)

        % Transform the 3D landmarks using the transformation matrix T
        lmks3D_hom = [lmks3D, ones(length(lmks), 1)];  % Convert landmarks to homogeneous coordinates
        lmks3D_transformed = (T * lmks3D_hom')';  % Apply transformation
        lmks3D_transformed = lmks3D_transformed(:, 1:3);  % Extract the transformed 3D coordinates

        % Extract the depth (Z-coordinate) of the transformed landmarks
        z_lmk = lmks3D_transformed(:, 3);

        % Project the transformed 3D landmarks to 2D using the camera intrinsic matrix K
        [lmks_projected, lmks_valid] = projectPoints([lmks3D_transformed, zeros(length(lmks), 0)], K, [], D, [], false);
    end

    % Process each triangle in the mesh (faces)
    if verbose, fprintf('%3i%%', 0); end  % Print progress if verbosity is enabled
    for indF = 1:size(faces, 2)
        if verbose, fprintf('\b\b\b\b%3i%%', round(indF / size(faces, 2) * 100)); end  % Update progress

        % Skip faces with invalid vertices
        if ~all(valid(faces(:, indF)))
            continue;
        end

        % Process the current triangle using transformed coordinates
        points3D = coord_transformed(faces(:, indF), :)';  % Get the 3D coordinates of the face vertices
        if ~isempty(RGB), RGB3D = RGB(faces(:, indF), :); end  % Get the RGB values of the vertices (if provided)

        % Get the 2D projections of the triangle vertices
        points2D = all_projected(faces(:, indF), 1:2);
        if ~isempty(RGB), RGB2D = all_projected(faces(:, indF), 3:5); end  % Get the RGB projections

        % Determine the bounds of the projected triangle in 2D
        P_xmax = max(points2D(:, 1)); P_ymax = max(points2D(:, 2));
        P_xmin = min(points2D(:, 1)); P_ymin = min(points2D(:, 2));

        % Clamp the bounds to the image size
        P_xmax = min(xr + halfCellX, P_xmax + 2 * halfCellX);
        P_ymax = min(yu + halfCellY, P_ymax + 2 * halfCellY);
        P_xmin = max(xl - halfCellX, P_xmin - 2 * halfCellX);
        P_ymin = max(yd - halfCellY, P_ymin - 2 * halfCellY);

        % Convert the 2D bounds to pixel coordinates
        [P_cols, P_rows] = cartesian2pixel([P_xmax, P_ymax; P_xmin, P_ymin], xl, yd, halfCellX, halfCellY, imgSize);
        [C, R] = meshgrid(min(P_cols):max(P_cols), min(P_rows):max(P_rows));  % Generate the pixel grid
        C = C(:); R = R(:);  % Convert to column vectors

        % Process each pixel inside the triangle
        inv_ptmatrix = inv([points2D'; [1, 1, 1]]);  % Inverse of the triangle vertex matrix for barycentric coordinates
        for px = 1:size(C, 1)
            r = R(px); c = C(px);  % Get the row and column of the pixel
            x = xr - halfCellX * 2 * (c - 1);  % Compute the pixel's x-coordinate
            y = yu - halfCellY * 2 * (r - 1);  % Compute the pixel's y-coordinate

            % Compute barycentric coordinates
            bar_coord = inv_ptmatrix * [x; y; 1];

            % Check if the pixel is inside the triangle
            if all(bar_coord >= 0) && all(bar_coord <= 1)
                bar_coord_3D = points3D * bar_coord;  % Interpolate the 3D coordinates
                zdepth = bar_coord_3D(3);  % Get the depth (Z-coordinate)

                % If the current depth is closer than the Z-buffer value, update the buffers
                if zdepth < zbuff(r, c)
                    zbuff(r, c) = zdepth;  % Update the Z-buffer
                    if ~isempty(RGB)
                        colour(r, c, :) = RGB2D' * bar_coord;  % Interpolate and update the color
                    end
                    map_2Dto3D(r, c, :) = bar_coord_3D;  % Update the 2D-to-3D map
                    visibleF(r, c) = indF;  % Mark the face as visible
                end
            end
        end
    end

    % Remove non-visible faces from the list of visible faces
    visibleF = unique(visibleF(:)); visibleF(visibleF == 0) = [];

    % Determine the visibility of landmarks based on the Z-buffer
    if ~isempty(lmks)
        epsilon = 1e-3;  % Epsilon to account for numerical precision
        for idx = 1:length(lmks)
            if ~lmks_valid(idx)
                continue;  % Skip invalid landmarks
            end

            % Convert landmark 2D coordinates to pixel indices
            col = floor(1 + (lmks_projected(idx, 1) - xl + halfCellX) / (2 * halfCellX));
            row = floor(1 + (lmks_projected(idx, 2) - yd + halfCellY) / (2 * halfCellY));
            row = imgSize(1) - row + 1;
            col = imgSize(2) - col + 1;

            % Check if the pixel is within the image bounds
            if row >= 1 && row <= imgSize(1) && col >= 1 && col <= imgSize(2)
                z_buffer_value = zbuff(row, col);  % Get the Z-buffer value at the landmark's pixel
                if isinf(z_buffer_value)
                    lmk_visibility(idx) = false;  % If the Z-buffer value is infinite, the landmark is not visible
                    lmks_img(idx, :) = [NaN, NaN];  % Set the landmark's position to NaN
                    continue;
                end
                % Compare the landmark's depth with the Z-buffer value
                if abs(z_lmk(idx) - z_buffer_value) <= epsilon
                    lmk_visibility(idx) = true;  % The landmark is visible if its depth is close to the Z-buffer value
                else
                    lmk_visibility(idx) = false;  % Otherwise, the landmark is not visible
                end
                lmks_img(idx, :) = [col, row];  % Store the landmark's 2D position
            else
                % If the landmark projects outside the image bounds, mark it as not visible
                lmk_visibility(idx) = false;
                lmks_img(idx, :) = [NaN, NaN];
            end
        end
        % Return the projected landmark positions and visibility if requested
        if nargout > 4
            varargout{1} = lmks_img;
            varargout{2} = lmk_visibility;
        end
    end
end

% Helper function to convert 2D Cartesian coordinates to pixel indices
function [cols, rows] = cartesian2pixel(points2D, xl, yd, halfCellX, halfCellY, imgSize)
    % Convert 2D Cartesian coordinates to pixel indices based on image bounds and scaling
    cols = floor(1 + (points2D(:, 1) - xl + halfCellX) / (2 * halfCellX));
    rows = floor(1 + (points2D(:, 2) - yd + halfCellY) / (2 * halfCellY));
    rows = imgSize(1) - rows + 1;
    cols = imgSize(2) - cols + 1;
end
