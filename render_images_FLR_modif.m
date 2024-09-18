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
%     - 'LandmarksQL': Landmark indices for the quarter-left view.
%     - 'LandmarksQR': Landmark indices for the quarter-right view.
%     - 'scale_for_imgSize': Scaling factor for the image size.
%     - 'save_output': Directory and base file name for saving output images.
%     - 'render': String indicating which views to render ('F', 'L', 'R', any combination).
%     - 'verbose': Boolean flag to enable verbose output.
%
% OUTPUT:
% - map_2Dto3D: Structure array containing information about the generated images,
%               including file names, image data, and landmark mappings.

% Check if the mesh and texture should be read from files
if ~read_files
    % If not reading from files, use the provided mesh and texture data directly
    myMesh = x3d_filepath;  % Assign mesh data from input parameter
    myTexture = stereo_img_filepath;  % Assign texture data from input parameter
    clearvars x3d_filepath stereo_img_filepath  % Clear variables to avoid confusion
end

% Default parameters initialization
scale_for_imgSize = 13e-5;  % Default scaling factor for the image size
lmksF = [];  % Initialize landmarks for frontal view
lmksR = [];  % Initialize landmarks for right view
lmksL = [];  % Initialize landmarks for left view
lmksQL = [];  % Initialize landmarks for quarter left view
lmksQR = [];  % Initialize landmarks for quarter right view
outDir = '';  % Initialize output directory string
outFile = '';  % Initialize output file string
verbose = false;  % Default verbosity flag
render = 'FRLQ_RQ_L';  % Default views to render (Frontal, Right, Left)

% Process additional arguments using varargin
while ~isempty(varargin)
    % Check for each additional argument by name and assign values
    if strcmpi(varargin{1}, 'LandmarksF')
        lmksF = varargin{2};  % Assign frontal landmarks
        varargin(1:2) = [];  % Remove processed arguments
        continue;
    end
    if strcmpi(varargin{1}, 'LandmarksR')
        lmksR = varargin{2};  % Assign right landmarks
        varargin(1:2) = [];
        continue;
    end
    if strcmpi(varargin{1}, 'LandmarksL')
        lmksL = varargin{2};  % Assign left landmarks
        varargin(1:2) = [];
        continue;
    end

    if strcmpi(varargin{1}, 'LandmarksQL')
        lmksQL = varargin{2};  % Assign quarter left landmarks
        varargin(1:2) = [];
        continue;
    end

    if strcmpi(varargin{1}, 'LandmarksQR')
        lmksQR = varargin{2};  % Assign quarter right landmarks
        varargin(1:2) = [];
        continue;
    end


    if strcmpi(varargin{1}, 'scale_for_imgSize')
        scale_for_imgSize = varargin{2};  % Assign custom scale for image size
        varargin(1:2) = [];
        continue;
    end
    if strcmp(varargin{1}, 'save_output')
        outDir = varargin{2};  % Assign output directory
        outFile = varargin{3};  % Assign output file name
        varargin(1:3) = [];
        outDir = strcat(outDir, '/');
        outDir = regexprep(outDir, '//$', '/'); % Ensure no double slashes at the end % Ensure directory ends with '/'
        continue;
    end
    if strcmp(varargin{1}, 'render')
        render = varargin{2};  % Assign views to render
        varargin(1:2) = [];
        continue;
    end
    if strcmp(varargin{1}, 'verbose')
        verbose = true;  % Enable verbose output
        varargin(1) = [];
        continue;
    end
    error('Unexpected input argument.')  % Error for unknown arguments
end

% Prepare the base name for the output file
outFile = strsplit(outFile, '.');  % Split file name by dot to remove extension
outFile = outFile{1};  % Take the first part as the base name

% Read and process 3D mesh and texture if necessary
if read_files
    if verbose, fprintf('Reading X3D file\n'), end  % Verbose output
    [coord, faces_coord, faces_tex, tex_coord_img, texture] = read_x3d(x3d_filepath, stereo_img_filepath);
    myMesh.verts = coord;  % Assign vertex coordinates to mesh
    myMesh.faces = faces_coord;  % Assign face data to mesh
end

% Apply rotation to align the mesh to a frontal position
myMesh.verts = eul2rotm(rotAnglesXYZ, 'XYZ') * myMesh.verts;  % Rotate vertices
myMesh.verts = myMesh.verts - mean(myMesh.verts, 2);  % Center the mesh

% Camera setup
cam = eye(3);  % Identity matrix for the camera setup

% Create transformation matrix
tform = eye(4);  % Identity matrix for transformations
dist = [0, 0, 0, 0, 0];  % Distortion parameters

%%%%%%%%% FRONTAL %%%%%%%%%%
% Rotate mesh to frontal view
deg = 180;
rad = deg * pi / 180;  % Convert 180 degrees to radians
Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];  % Rotation matrix around Y-axis
myMesh.verts = Ry * myMesh.verts;  % Apply rotation to vertices

% Upsample the mesh if reading from files
if read_files
    if verbose, fprintf('Upsampling the mesh\n'), end  % Verbose output
    texture_struct.faces_tex = faces_tex;  % Assign face texture data
    texture_struct.RGB = texture;  % Assign RGB texture data
    texture_struct.tex_coord_img = tex_coord_img;  % Assign texture coordinates
    texture_struct.stereo_img = imread(stereo_img_filepath);  % Load stereo image
    [myMesh, myTexture] = mesh_upSample_triEdges(myMesh, 'texture', texture_struct);  % Upsample the mesh
end

% Adjust camera and transformation settings based on the mesh
cam(1, 3) = -min(myMesh.verts(1, :));  % Adjust camera x-position
cam(2, 3) = -min(myMesh.verts(2, :));  % Adjust camera y-position
tform(3, 4) = max(myMesh.verts(3, :)) * 10;  % Adjust camera z-position

% Generate frontal view image
if contains(render, 'F')  % Check if 'F' is in the render options
    map_2Dto3D(1) = generateLandmarksPerView('frontal', myMesh, myTexture, cam, tform, dist, scale_for_imgSize, ...
                                        lmksF, outDir, outFile, 0);
end

% Generate right-side view image
if contains(render, 'R')  % Check if 'R' is in the render options
    map_2Dto3D(2) = generateLandmarksPerView('right', myMesh, myTexture, cam, tform, dist, scale_for_imgSize, ...
                                        lmksR, outDir, outFile, deg);
end

% Generate left-side view image
if contains(render, 'L')  % Check if 'L' is in the render options
    map_2Dto3D(3) = generateLandmarksPerView('left', myMesh, myTexture, cam, tform, dist, scale_for_imgSize, ...
                                        lmksL, outDir, outFile, deg);
end

% Generate quarter left-side view image
if contains(render, 'Q_L')  % Check if 'L' is in the render options
    map_2Dto3D(4) = generateLandmarksPerView('quarter_left', myMesh, myTexture, cam, tform, dist, scale_for_imgSize, ...
                                        lmksQL, outDir, outFile, deg);
end

% Generate quarter right-side view image
if contains(render, 'Q_R')  % Check if 'L' is in the render options
    map_2Dto3D(5) = generateLandmarksPerView('quarter_right', myMesh, myTexture, cam, tform, dist, scale_for_imgSize, ...
                                        lmksQR, outDir, outFile, deg);
end
