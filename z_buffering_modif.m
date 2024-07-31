function [visibleF, zbuff, colour, map_2Dto3D,varargout] = z_buffering_modif(coord, faces, RGB, K, T, D, varargin )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%% INPUTS %%%%%%%%
% coord: 3xN, coordinates of the N vertices of the mesh
% faces: 3xM, triangulation of the mesh (M = #triangles)
% RGB: Nx3, colours in RGB form of the N vertices
% K: either a 3x3 or 3x4 camera matrix
% T: 4x4 transformation matrix to apply to points before projecting them
%       (default identity matrix)
% D: 1xq distortion vector that matches opencv's implementation [k1,k2,p1,p2,k3], 
%       q can be from 1 to 5 and any values not given are
%       set to 0 (default [0,0,0,0,0])
% imgSize: 1x2 vector that gives the size of image (y,x) the points
%       will be projected onto, if it is given points that are outside this
%       size or negitive will be treated as invalid (default [])
% sortPoints: 1x1 binary value, if true points are sorted by their
%       distance (furthest away first) from the camera (useful for 
%       rendering points), (default false)
%
% %%%%%%%% OUTPUTS %%%%%%%%
% visible: the indices of the visible faces in the "faces" input
% zbuff: z-buffering matrix of depths
% colour: projected image matrix of projected colours
% map_2Dto3D: matrix of size imgSize, an element in position (r,c)
%             is the 3D point that, once projected, lays in the pixel (r,c)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
verbose = 0;
scale_for_imgSize = 13e-5;
lmks = [];
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


% Create image grid: project all the 3D points and create a grid that
% contains these 2D points, size(grid) = imgSize
% [ all_projected, valid ] = projectPoints( [coord',RGB], K, T, D, imgSize, false );
[ all_projected, valid ] = projectPoints( [coord',RGB], K, T, D, [], false );
% all_projected = all_projected(valid,:);

% xl = min(all_projected(:,1)); xr = max(all_projected(:,1));
% yd = min(all_projected(:,2)); yu = max(all_projected(:,2));
% halfCellX = (xr - xl)/(2*(imgSize(2) - 1));
% halfCellY = (yu - yd)/(2*(imgSize(1) - 1));

xl = min(all_projected(valid,1)); xr = max(all_projected(valid,1));
yd = min(all_projected(valid,2)); yu = max(all_projected(valid,2));
nRows = (yu - yd)/scale_for_imgSize;
nCols = (xr - xl)/scale_for_imgSize;
imgSize = ceil([nRows, nCols])+[10,10];
halfCellX = (xr - xl)/(2*(imgSize(2) - 1));
halfCellY = (yu - yd)/(2*(imgSize(1) - 1));


% Initialisation
zbuff = Inf*ones(imgSize);
colour = 255*ones([imgSize,3]);
map_2Dto3D = Inf*ones([imgSize,3]);
visibleF = zeros(imgSize);


% For each triangle in faces
lmk_faces = ismember(faces,lmks);
if verbose, fprintf('%3i%%',0), end
for indF = 1:size(faces,2)
    if verbose, fprintf('\b\b\b\b%3i%%',round(indF/size(faces,2)*100)), end
    
    if ~all(valid(faces(:,indF)))
        continue;
    end
    
    % If the current triangle has a vertex that is a landmark
    currLmkIdx = faces(lmk_faces(:,indF),indF);
    for indL = 1:length(currLmkIdx)

        currLmk = all_projected(currLmkIdx(indL),1:2);
        L_xmax = min(xr+halfCellX,currLmk(1,1));
        L_ymax = min(yu+halfCellY,currLmk(1,2));
        L_xmin = max(xl-halfCellX,currLmk(1,1));
        L_ymin = max(yd-halfCellY,currLmk(1,2));
        [L_cols, L_rows] = cartesian2pixel([L_xmax, L_ymax; L_xmin, L_ymin],xl,yd,halfCellX,halfCellY,imgSize);
        [C_L,R_L] = meshgrid(min(L_cols):max(L_cols), min(L_rows):max(L_rows));

        currIndL = find(lmks == currLmkIdx(indL));
        for indL2 = 1:length(currIndL)
            if all(lmks_img(currIndL(indL2),:) == [0,0])
                lmks_img(currIndL(indL2),:) = [C_L,R_L];
            else
                if any(lmks_img(currIndL(indL2),:) ~= [C_L,R_L]), error(''), end
            end
        end
    end
    
    
    
    points3D = coord(:,faces(:,indF));
    if ~isempty(RGB), RGB3D = RGB(faces(:,indF),:); end
    
    if any(faces(:,indF) == 4595)
        disp('')
    end
    
    
    % Project the 3 vertices of the triangle
    points2D = all_projected(faces(:,indF),1:2);
    if ~isempty(RGB), RGB2D = all_projected(faces(:,indF),3:5); end
    
    
    % Extract which cells of the grid intersecting with or containing 
    % (part of) the projected triangle
    P_xmax = max(points2D(:,1)); P_ymax = max(points2D(:,2));
    P_xmin = min(points2D(:,1)); P_ymin = min(points2D(:,2));
    
    P_xmax = min(xr+halfCellX,P_xmax+2*halfCellX);
    P_ymax = min(yu+halfCellY,P_ymax+2*halfCellY);
    P_xmin = max(xl-halfCellX,P_xmin-2*halfCellX);
    P_ymin = max(yd-halfCellY,P_ymin-2*halfCellY);
    
    [P_cols, P_rows] = cartesian2pixel([P_xmax, P_ymax; P_xmin, P_ymin],xl,yd,halfCellX,halfCellY,imgSize);
    [C,R] = meshgrid(min(P_cols):max(P_cols), min(P_rows):max(P_rows));
    C = C(:); R = R(:);
    
    
    % For each of these cells (that intersect with the triangle)
    inv_ptmatrix = inv([points2D';[1,1,1]]);
    for px = 1:size(C,1)
        r = R(px); c = C(px);
%         [x,y] = pixel2cartesian(r,c,xr,yu,halfCellX,halfCellY);
        x = xr - halfCellX*2*(c-1);
        y = yu - halfCellY*2*(r-1);

        % bar_coord = [points2D';[1,1,1]]\[x;y;1];
        bar_coord = inv_ptmatrix * [x;y;1];
%         v = [points2D(2:3,:);[x,y]] - points2D(1,:);
%         lambda2_num = (v(2,:)*v(2,:)' * v(1,:)*v(3,:)') - (v(1,:)*v(2,:)' * v(2,:)*v(3,:)');
%         lambda3_num = (v(1,:)*v(1,:)' * v(2,:)*v(3,:)') - (v(1,:)*v(2,:)' * v(1,:)*v(3,:)');
%         denominator =  (v(1,:)*v(1,:)' * v(2,:)*v(2,:)') - (v(1,:)*v(2,:)')^2;
%         bar_coord = [ 0; lambda2_num/denominator; lambda3_num/denominator ];
%         bar_coord(1) = 1 - sum(bar_coord);
        

        if all(bar_coord >= 0) && all(bar_coord <= 1)
            %bar_coord=bar_coord.*1.6;
            bar_coord_3D = points3D*bar_coord;
            % Compute the z-depth of the grid_centers of these cells
            % How? the z-depth is the z coordinate
            zdepth = bar_coord_3D(3);

            if zdepth < zbuff(r,c)
                zbuff(r,c) = zdepth;
                if ~isempty(RGB)
                    colour(r,c,:) = RGB2D'*bar_coord;
                end
                map_2Dto3D(r,c,:) = bar_coord_3D;
                visibleF(r,c) = indF;
            end
        end
    end
end

visibleF = unique(visibleF(:)); visibleF(visibleF == 0) = [];

if exist('lmks','var') && nargout > 4
    varargout{1} = lmks_img;
end


end


function [cols, rows] = cartesian2pixel(points2D,xl,yd,halfCellX,halfCellY,imgSize)
% points2D:  Nx2
cols = floor(1 + (points2D(:,1)-xl+halfCellX)/(2*halfCellX)); %(points2D(:,1) - xl + halfCellX)/(xr - xl + 2*halfCellX)*imgSize(2) ); 
rows = floor(1 + (points2D(:,2)-yd+halfCellY)/(2*halfCellY)); %(points2D(:,2) - yd + halfCellY)/(yu - yd + 2*halfCellY)*imgSize(1) ); 
rows = imgSize(1) - rows + 1;
cols = imgSize(2) - cols + 1;
end

function [x,y] = pixel2cartesian(rows,cols,xr,yu,halfCellX,halfCellY)
% pixels:  Nx2 rows, columns
    x = xr - halfCellX*2*(cols-1);
    y = yu - halfCellY*2*(rows-1);
end