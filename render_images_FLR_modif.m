function map_2Dto3D = render_images_FLR_modif(read_files, x3d_filepath, stereo_img_filepath, rotAnglesXYZ, varargin)
% render_images_FLR_modif Generates 2D images from a 3D mesh model with various views.
%
% This function takes a 3D mesh model and its corresponding texture to generate synthetic images
% from different views (frontal, left, right) by applying specified rotations. The function
% supports options to handle landmark coordinates, scaling, and output file saving.
%
% INPUT:
% - read_files: Boolean flag to indicate whether to read the 3D mesh and texture from files.
% - x3d_filepath: Path and file name of the x3D file (ignored if read_files is false).
% - stereo_img_filepath: Path and file name of the stereo image (ignored if read_files is false).
% - rotAnglesXYZ: Angles in x, y, and z that position the scan into a frontal position.
% - varargin: Additional optional arguments as name-value pairs:
%     - 'LandmarksF': Landmark indices for the frontal view.
%     - 'LandmarksR': Landmark indices for the right view.
%     - 'LandmarksL': Landmark indices for the left view.
%     - 'scale_for_imgSize': Scaling factor for the image size.
%     - 'save_output': Directory and base file name for saving output images.
%     - 'render': String indicating which views to render ('F', 'L', 'R', any combination).
%     - 'verbose': Boolean flag to enable verbose output.
%
% OUTPUT:
% - map_2Dto3D: Structure array containing information about the generated images,
%               including file names, image data, and landmark mappings.

if ~read_files
    % If not reading from files, use the provided mesh and texture data directly
    myMesh = x3d_filepath;
    myTexture = stereo_img_filepath;
    clearvars x3d_filepath stereo_img_filepath
end

% Default parameters
scale_for_imgSize = 13e-5;
lmksF = [];
lmksR = [];
lmksL = [];
outDir = '';
outFile = '';
verbose = false;
render = 'FRL';

% Process additional arguments
while ~isempty(varargin)
    if strcmpi(varargin{1},'LandmarksF')
        lmksF = varargin{2};
        varargin(1:2) = [];
        continue;
    end
    if strcmpi(varargin{1},'LandmarksR')
        lmksR = varargin{2};
        varargin(1:2) = [];
        continue;
    end
    if strcmpi(varargin{1},'LandmarksL')
        lmksL = varargin{2};
        varargin(1:2) = [];
        continue;
    end
    if strcmpi(varargin{1},'scale_for_imgSize')
        scale_for_imgSize = varargin{2};
        varargin(1:2) = [];
        continue;
    end
    if strcmp(varargin{1},'save_output')
        outDir = varargin{2};
        outFile = varargin{3};
        varargin(1:3) = [];
        if outDir(end) ~= '/', outDir = [outDir,'/']; end
        continue;
    end
    if strcmp(varargin{1},'render')
        render = varargin{2};
        varargin(1:2) = [];
        continue;
    end
    if strcmp(varargin{1},'verbose')
        verbose = true;
        varargin(1) = [];
        continue;
    end
    error('Unexpected input argument.')
end

% Prepare output file base name
outFile = strsplit(outFile,'.');
outFile = outFile{1};

% Read and process 3D mesh and texture if necessary
if read_files
    if verbose, fprintf('Reading X3D file\n'), end
    [coord, faces_coord, faces_tex, tex_coord_img, texture] = read_x3d(x3d_filepath, stereo_img_filepath);
    myMesh.verts = coord; myMesh.faces = faces_coord;
end

% Apply rotation to align the mesh to a frontal position
myMesh.verts = eul2rotm(rotAnglesXYZ,'XYZ') * myMesh.verts;
myMesh.verts = myMesh.verts - mean(myMesh.verts,2);

% Camera setup
cam = eye(3); % Identity matrix for the camera setup

% Create transformation matrix
tform = eye(4);
dist = [0,0,0,0,0]; % Distortion parameters

% Rotate mesh to frontal view
deg = 180; rad = deg*pi/180;
Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];
myMesh.verts = Ry*myMesh.verts;

% Upsample the mesh if reading from files
if read_files
    if verbose, fprintf('Upsampling the mesh\n'), end
    texture_struct.faces_tex = faces_tex; texture_struct.RGB = texture;
    texture_struct.tex_coord_img = tex_coord_img; texture_struct.stereo_img = imread(stereo_img_filepath);
    [myMesh, myTexture] = mesh_upSample_triEdges(myMesh, 'texture', texture_struct);
end

% Adjust camera and transformation settings based on the mesh
cam(1,3) = -min(myMesh.verts(1,:));
cam(2,3) = -min(myMesh.verts(2,:));
tform(3,4) = max(myMesh.verts(3,:))*10;

% Generate frontal view image
if contains(render,'F')
    if verbose, fprintf('Z-buffering frontal\t'), end
    if ~isempty(lmksF)
        [~, ~, img, map, lmksF_img] = z_buffering_modif(myMesh.verts, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'Landmarks',lmksF,'verbose');
    else
        [~, ~, img, map] = z_buffering_modif(myMesh.verts, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'verbose');
        lmksF_img = [];
    end
    if verbose, fprintf('\n'), end

    % Save or display the frontal image
    if isempty(outFile)
        figure; imshow(uint8(img));
        if ~isempty(lmksF_img), hold on, plot2pts(lmksF_img', '*r'); end
    else
        imwrite(uint8(img),[outDir, outFile,'_frontal.jpg']);
        if ~isempty(lmksF_img)
            figure; imshow(uint8(img)); hold on;
            plot2pts(lmksF_img', '*r');
            saveas(gcf, [outDir, outFile,'_frontal_with_landmarks.jpg']);
            Write_PTS_Landmarks2D([outDir, outFile,'_frontal.pts'],lmksF_img');
        end
    end

    % Store the frontal image data
    map_2Dto3D(1).file = [outDir, outFile,'_frontal.jpg'];
    map_2Dto3D(1).image = img;
    map_2Dto3D(1).map = map;
    map_2Dto3D(1).angle = 0;
    map_2Dto3D(1).landmarks = lmksF_img;
end

% Generate right-side view image
if contains(render,'L')
    deg = -75; rad = deg*pi/180;
    Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];
    coord_right = Ry*myMesh.verts;

    if verbose, fprintf('Z-buffering right\t'), end
    if ~isempty(lmksL)
        [~, ~, img, map, lmksR_img] = z_buffering_modif(coord_right, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'Landmarks',lmksL,'verbose');
    else
        [~, ~, img, map] = z_buffering_modif(coord_right, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'verbose');
        lmksR_img = [];
    end
    if verbose, fprintf('\n'), end

    % Save or display the right-side image
    if isempty(outFile)
        figure; imshow(uint8(img));
        if ~isempty(lmksR_img), hold on, plot2pts(lmksR_img', '*r'); end
    else
        imwrite(uint8(img),[outDir, outFile,'_leftside.jpg']);
        if ~isempty(lmksR_img)
            figure; imshow(uint8(img)); hold on;
            plot2pts(lmksR_img', '*r');
            saveas(gcf, [outDir, outFile,'_leftside_with_landmarks.jpg']);
            Write_PTS_Landmarks2D([outDir, outFile,'_leftside.pts'],lmksR_img');
        end
    end

    % Store the right-side image data
    map_2Dto3D(3).file = [outDir, outFile,'_leftside.jpg'];
    map_2Dto3D(3).image = img;
    map_2Dto3D(3).map = map;
    map_2Dto3D(3).angle = deg;
    map_2Dto3D(3).landmarks = lmksR_img;
end

% Generate left-side view image
if contains(render,'R')
    deg = 75; rad = deg*pi/180;
    Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];
    coord_left = Ry*myMesh.verts;

    if verbose, fprintf('Z-buffering left\t'), end
    if ~isempty(lmksR)
        [~, ~, img, map, lmksL_img] = z_buffering_modif(coord_left, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'Landmarks',lmksR,'verbose');
    else
        [~, ~, img, map] = z_buffering_modif(coord_left, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'verbose');
        lmksL_img = [];
    end
    if verbose, fprintf('\n'), end

    % Save or display the left-side image
    if isempty(outFile)
        figure; imshow(uint8(img));
        if ~isempty(lmksL_img), hold on, plot2pts(lmksL_img', '*r'); end
    else
        imwrite(uint8(img),[outDir, outFile,'_rightside.jpg']);
        if ~isempty(lmksL_img)
            figure; imshow(uint8(img)); hold on;
            plot2pts(lmksL_img', '*r');
            saveas(gcf, [outDir, outFile,'_rightside_with_landmarks.jpg']);
            Write_PTS_Landmarks2D([outDir, outFile,'_rightside.pts'],lmksL_img');
        end
    end

    % Store the left-side image data
    map_2Dto3D(2).file = [outDir, outFile,'_rightside.jpg'];
    map_2Dto3D(2).image = img;
    map_2Dto3D(2).map = map;
    map_2Dto3D(2).angle = deg;
    map_2Dto3D(2).landmarks = lmksL_img;
end
end
