function [visibleF, zbuff, colour, map_2Dto3D, varargout] = z_buffering_modif(coord, faces, RGB, K, T, D, varargin)
% z_buffering_modif Performs z-buffering to project a 3D mesh onto a 2D image plane.
%
% This function projects a 3D mesh onto a 2D image plane using z-buffering. It supports
% camera and transformation matrices, distortion correction, and optional landmark
% projections. The function returns the visible faces, z-buffer, projected image, and
% a 2D-to-3D mapping.
%
% INPUTS:
% - coord: 3xN matrix, coordinates of the N vertices of the mesh.
% - faces: 3xM matrix, triangulation of the mesh (M = number of triangles).
% - RGB: Nx3 matrix, colors in RGB form of the N vertices.
% - K: 3x3 or 3x4 camera matrix.
% - T: 4x4 transformation matrix to apply to points before projecting them (default identity matrix).
% - D: 1xq distortion vector matching OpenCV's implementation [k1, k2, p1, p2, k3], q can be from 1 to 5.
% - varargin: Additional optional arguments as name-value pairs:
%     - 'Landmarks': Indices of landmarks to be projected.
%     - 'verbose': Boolean flag to enable verbose output.
%     - 'scale_for_imgSize': Scaling factor for the image size.
%
% OUTPUTS:
% - visibleF: Indices of the visible faces in the "faces" input.
% - zbuff: Z-buffer matrix of depths.
% - colour: Projected image matrix of projected colors.
% - map_2Dto3D: Matrix of size imgSize, mapping 2D points to 3D points.
% - varargout: Optionally returns the 2D coordinates of the landmarks.

verbose = 0; % Initialize verbosity flag
scale_for_imgSize = 13e-5; % Default scaling factor for image size
lmks = []; % Initialize landmarks

% Process additional arguments
while ~isempty(varargin)
    if strcmp(varargin{1},'Landmarks')
        lmks = varargin{2};
        lmks_img = zeros(length(lmks),2);
        varargin(1:2) = [];
    elseif strcmp(varargin{1},'verbose')
        verbose = 1;
        varargin(1) = [];
    elseif strcmpi(varargin{1},'scale_for_imgSize')
        scale_for_imgSize = varargin{2};
        varargin(1:2) = [];
    else
        error('Unexpected input argument.')
    end
end

% Project all 3D points to 2D using the provided camera and transformation matrices
[all_projected, valid] = projectPoints([coord', RGB], K, T, D, [], false);

% Determine the bounds of the projected points
xl = min(all_projected(valid,1)); xr = max(all_projected(valid,1));
yd = min(all_projected(valid,2)); yu = max(all_projected(valid,2));
nRows = (yu - yd) / scale_for_imgSize;
nCols = (xr - xl) / scale_for_imgSize;
imgSize = ceil([nRows, nCols]) + [10, 10]; % Add padding to image size
halfCellX = (xr - xl) / (2 * (imgSize(2) - 1));
halfCellY = (yu - yd) / (2 * (imgSize(1) - 1));

% Initialize output matrices
zbuff = Inf * ones(imgSize);
colour = 255 * ones([imgSize, 3]);
map_2Dto3D = Inf * ones([imgSize, 3]);
visibleF = zeros(imgSize);

% Check if any faces contain landmarks
lmk_faces = ismember(faces, lmks);

% Process each triangle in the faces
if verbose, fprintf('%3i%%', 0), end
for indF = 1:size(faces, 2)
    if verbose, fprintf('\b\b\b\b%3i%%', round(indF / size(faces, 2) * 100)), end
    
    % Skip faces with invalid vertices
    if ~all(valid(faces(:, indF)))
        continue;
    end
    
    % Handle landmarks within the current triangle
    currLmkIdx = faces(lmk_faces(:, indF), indF);
    for indL = 1:length(currLmkIdx)
        currLmk = all_projected(currLmkIdx(indL), 1:2);
        L_xmax = min(xr + halfCellX, currLmk(1, 1));
        L_ymax = min(yu + halfCellY, currLmk(1, 2));
        L_xmin = max(xl - halfCellX, currLmk(1, 1));
        L_ymin = max(yd - halfCellY, currLmk(1, 2));
        [L_cols, L_rows] = cartesian2pixel([L_xmax, L_ymax; L_xmin, L_ymin], xl, yd, halfCellX, halfCellY, imgSize);
        [C_L, R_L] = meshgrid(min(L_cols):max(L_cols), min(L_rows):max(L_rows));

        currIndL = find(lmks == currLmkIdx(indL)); % OJO con esta sección
        for indL2 = 1:length(currIndL)
            if all(lmks_img(currIndL(indL2), :) == [0, 0])
                lmks_img(currIndL(indL2), :) = [C_L, R_L];
            else
                if any(lmks_img(currIndL(indL2), :) ~= [C_L, R_L]), error(''), end
            end
        end
    end
    
    % Process the current triangle
    points3D = coord(:, faces(:, indF));
    if ~isempty(RGB), RGB3D = RGB(faces(:, indF), :); end
    
    % Project the 3 vertices of the triangle
    points2D = all_projected(faces(:, indF), 1:2);
    if ~isempty(RGB), RGB2D = all_projected(faces(:, indF), 3:5); end
    
    % Determine the bounds of the projected triangle
    P_xmax = max(points2D(:, 1)); P_ymax = max(points2D(:, 2));
    P_xmin = min(points2D(:, 1)); P_ymin = min(points2D(:, 2));
    
    P_xmax = min(xr + halfCellX, P_xmax + 2 * halfCellX);
    P_ymax = min(yu + halfCellY, P_ymax + 2 * halfCellY);
    P_xmin = max(xl - halfCellX, P_xmin - 2 * halfCellX);
    P_ymin = max(yd - halfCellY, P_ymin - 2 * halfCellY);
    
    [P_cols, P_rows] = cartesian2pixel([P_xmax, P_ymax; P_xmin, P_ymin], xl, yd, halfCellX, halfCellY, imgSize);
    [C, R] = meshgrid(min(P_cols):max(P_cols), min(P_rows):max(P_rows));
    C = C(:); R = R(:);
    
    % Process each cell that intersects with the triangle
    inv_ptmatrix = inv([points2D'; [1, 1, 1]]);
    for px = 1:size(C, 1)
        r = R(px); c = C(px);
        x = xr - halfCellX * 2 * (c - 1);
        y = yu - halfCellY * 2 * (r - 1);

        % Compute barycentric coordinates
        bar_coord = inv_ptmatrix * [x; y; 1];
        %bar_coord = inv_ptmatrix \ [x; y; 1];

        if all(bar_coord >= 0) && all(bar_coord <= 1)
            bar_coord_3D = points3D * bar_coord;
            zdepth = bar_coord_3D(3);

            if zdepth < zbuff(r, c) % Revisar esta sección
                zbuff(r, c) = zdepth;
                if ~isempty(RGB)
                    colour(r, c, :) = RGB2D' * bar_coord;
                end
                map_2Dto3D(r, c, :) = bar_coord_3D;
                visibleF(r, c) = indF;
            end
        end
    end
end

visibleF = unique(visibleF(:)); visibleF(visibleF == 0) = [];

if exist('lmks', 'var') && nargout > 4
    varargout{1} = lmks_img;
    [lmk_faces,~] = ismember(faces, lmks); % Con el lc mirar en cuales filas se repite en landmarks, y guardar
    varargout{2}= ismember(lmk_faces',visibleF); % Recorrer con un for para ver en que vertices se repiten los landmarks, y en donde la suma de 
    % landmarks es >0, entonce sno es visible.
    
end

end

% Convert 2D Cartesian coordinates to pixel indices
function [cols, rows] = cartesian2pixel(points2D, xl, yd, halfCellX, halfCellY, imgSize)
    cols = floor(1 + (points2D(:, 1) - xl + halfCellX) / (2 * halfCellX));
    rows = floor(1 + (points2D(:, 2) - yd + halfCellY) / (2 * halfCellY));
    rows = imgSize(1) - rows + 1;
    cols = imgSize(2) - cols + 1;
end

% Convert pixel indices to 2D Cartesian coordinates
% function [x, y] = pixel2cartesian(rows, cols, xr, yu, halfCellX, halfCellY)
%     x = xr - halfCellX * 2 * (cols - 1);
%     y = yu - halfCellY * 2 * (rows - 1);
% end
