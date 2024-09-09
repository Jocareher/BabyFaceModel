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
render = 'FRLID';  % Default views to render (Frontal, Right, Left)

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
    % deg = 75;  % Set rotation angle for right view
    % Ry = [cos(deg*pi/180), 0, sin(deg*pi/180); 0, 1, 0; -sin(deg*pi/180), 0, cos(deg*pi/180)];
    % myMesh.verts = Ry * myMesh.verts;  % Rotate mesh for right view
    map_2Dto3D(2) = generateLandmarksPerView('right', myMesh, myTexture, cam, tform, dist, scale_for_imgSize, ...
                                        lmksR, outDir, outFile, deg);
end

% Generate left-side view image
if contains(render, 'L')  % Check if 'L' is in the render options
    % deg = -75;  % Set rotation angle for left view
    % Ry = [cos(deg*pi/180), 0, sin(deg*pi/180); 0, 1, 0; -sin(deg*pi/180), 0, cos(deg*pi/180)];
    % myMesh.verts = Ry * myMesh.verts;  % Rotate mesh for left view
    map_2Dto3D(3) = generateLandmarksPerView('left', myMesh, myTexture, cam, tform, dist, scale_for_imgSize, ...
                                        lmksL, outDir, outFile, deg);
end


% % Generate frontal view image
% if contains(render, 'F')  % Check if 'F' is in the render options
%     if verbose, fprintf('Z-buffering frontal\t'), end  % Verbose output
%     if ~isempty(lmksF)  % Check if frontal landmarks are specified
%         % Perform z-buffering with landmarks
%         [~, ~, imgF, mapF, lmksF_img] = z_buffering_modif(myMesh.verts, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'Landmarks', lmksF, 'verbose');
%     else
%         % Perform z-buffering without landmarks
%         [~, ~, imgF, mapF] = z_buffering_modif(myMesh.verts, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'verbose');
%         lmksF_img = [];  % No landmark images
%     end
%     if verbose, fprintf('\n'), end  % New line for verbose output
% 
%     % Save or display the frontal image
%     if isempty(outFile)  % Check if no output file is specified
%         figure; imshow(uint8(imgF));  % Display image
%         if ~isempty(lmksF_img)  % Check if landmark images exist
%             hold on;
%             % Plot original landmarks in red
%             numOriginalLandmarks = 23;  % Number of original landmarks
%             if size(lmksF_img, 1) >= numOriginalLandmarks
%                 plot2pts(lmksF_img(1:numOriginalLandmarks, :)', '*r');  % Plot in red
%             end
%             % Plot additional landmarks in blue
%             if size(lmksF_img, 1) > numOriginalLandmarks
%                 plot2pts(lmksF_img(numOriginalLandmarks+1:end, :)', '*b');  % Plot in blue
%             end
%         end
%     else
%         % Save image to specified file
%         imwrite(uint8(imgF), [outDir, outFile, '_frontal.jpg']);
%         if ~isempty(lmksF_img)
%             figure; imshow(uint8(imgF)); hold on;
%             % Plot original landmarks in red
%             numOriginalLandmarks = 23;  % Number of original landmarks
%             if size(lmksF_img, 1) >= numOriginalLandmarks
%                 plot2pts(lmksF_img(1:numOriginalLandmarks, :)', '*r');  % Plot original landmarks in red
%             end
%             % Plot additional landmarks in blue
%             if size(lmksF_img, 1) > numOriginalLandmarks
%                 plot2pts(lmksF_img(numOriginalLandmarks+1:end, :)', '*b');  % Plot additional landmarks in blue
%             end
%             % Save the figure with landmarks as a new image
%             saveas(gcf, [outDir, outFile, '_frontal_with_landmarks.jpg']);
%             % Save landmarks to a .pts file
%             Write_PTS_Landmarks2D([outDir, outFile, '_frontal.pts'], lmksF_img');
%         end
%     end
% 
%     % Store the frontal image data in the output structure
%     map_2Dto3D(1).file = [outDir, outFile, '_frontal.jpg'];  % File path
%     map_2Dto3D(1).image = imgF;  % Image data
%     map_2Dto3D(1).map = mapF;  % 2D-to-3D map
%     map_2Dto3D(1).angle = 0;  % Viewing angle
%     map_2Dto3D(1).landmarks = lmksF_img;  % Landmarks
% end
% 
% % Generate right-side view image
% if contains(render, 'R')  % Check if 'R' is in the render options
%     deg = 75;  % Set rotation angle for right view
%     rad = deg * pi / 180;  % Convert angle to radians
%     Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];  % Rotation matrix for right view
%     coord_right = Ry * myMesh.verts;  % Rotate mesh for right view
% 
%     if verbose, fprintf('Z-buffering right\t'), end  % Verbose output
%     if ~isempty(lmksR)  % Check if right landmarks are specified
%         % Perform z-buffering with landmarks for right view
%         [~, ~, imgR, mapR, lmksR_img] = z_buffering_modif(coord_right, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'Landmarks', lmksR, 'verbose');
%     else
%         % Perform z-buffering without landmarks for right view
%         [~, ~, imgR, mapR] = z_buffering_modif(coord_right, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'verbose');
%         lmksR_img = [];  % No landmark images for right view
%     end
%     if verbose, fprintf('\n'), end  % New line for verbose output
% 
%     % Save or display the right-side image
%     if isempty(outFile)  % Check if no output file is specified
%         figure; imshow(uint8(imgR));  % Display image
%         if ~isempty(lmksR_img)  % Check if landmark images exist
%             hold on;
%             % Plot original landmarks in red
%             numOriginalLandmarks = 23;  % Number of original landmarks
%             if size(lmksR_img, 1) >= numOriginalLandmarks
%                 plot2pts(lmksR_img(1:numOriginalLandmarks, :)', '*r');  % Plot in red
%             end
%             % Plot additional landmarks in blue
%             if size(lmksR_img, 1) > numOriginalLandmarks
%                 plot2pts(lmksR_img(numOriginalLandmarks+1:end, :)', '*b');  % Plot in blue
%             end
%         end
%     else
%         % Save image to specified file
%         imwrite(uint8(imgR), [outDir, outFile, '_rightside.jpg']);
%         if ~isempty(lmksR_img)
%             figure; imshow(uint8(imgR)); hold on;
%             % Plot original landmarks in red
%             numOriginalLandmarks = 23;  % Number of original landmarks
%             if size(lmksR_img, 1) >= numOriginalLandmarks
%                 plot2pts(lmksR_img(1:numOriginalLandmarks, :)', '*r');  % Plot in red
%             end
%             % Plot additional landmarks in blue
%             if size(lmksR_img, 1) > numOriginalLandmarks
%                 plot2pts(lmksR_img(numOriginalLandmarks+1:end, :)', '*b');  % Plot in blue
%             end
%             saveas(gcf, [outDir, outFile, '_rightside_with_landmarks.jpg']);
%             % Save landmarks to a .pts file
%             Write_PTS_Landmarks2D([outDir, outFile, '_rightside.pts'], lmksR_img'); % Change lmks_R -> Change lmks_L
%         end
%     end
% 
%     % Store the right-side image data in the output structure
%     map_2Dto3D(2).file = [outDir, outFile, '_rightside.jpg'];  % File path
%     map_2Dto3D(2).image = imgR;  % Image data
%     map_2Dto3D(2).map = mapR;  % 2D-to-3D map
%     map_2Dto3D(2).angle = deg;  % Viewing angle
%     map_2Dto3D(2).landmarks = lmksR_img;  % Landmarks
% end
% 
% % Generate left-side view image
% if contains(render, 'L')  % Check if 'L' is in the render options
%     deg = -75;  % Set rotation angle for left view
%     rad = deg * pi / 180;  % Convert angle to radians
%     Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];  % Rotation matrix for left view
%     coord_left = Ry * myMesh.verts;  % Rotate mesh for left view
% 
%     if verbose, fprintf('Z-buffering left\t'), end  % Verbose output
%     if ~isempty(lmksL)  % Check if left landmarks are specified
%         % Perform z-buffering with landmarks for left view
%         [~, ~, imgL, mapL, lmksL_img] = z_buffering_modif(coord_left, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'Landmarks', lmksL, 'verbose');
%     else
%         % Perform z-buffering without landmarks for left view
%         [~, ~, imgL, mapL] = z_buffering_modif(coord_left, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'verbose');
%         lmksL_img = [];  % No landmark images for left view
%     end
%     if verbose, fprintf('\n'), end  % New line for verbose output
% 
%     % Save or display the left-side image
%     if isempty(outFile)  % Check if no output file is specified
%         figure; imshow(uint8(imgL));  % Display image
%         if ~isempty(lmksL_img)  % Check if landmark images exist
%             hold on;
%             % Plot original landmarks in red
%             numOriginalLandmarks = 23;  % Number of original landmarks
%             if size(lmksL_img, 1) >= numOriginalLandmarks
%                 plot2pts(lmksL_img(1:numOriginalLandmarks, :)', '*r');  % Plot in red
%             end
%             % Plot additional landmarks in blue
%             if size(lmksL_img, 1) > numOriginalLandmarks
%                 plot2pts(lmksL_img(numOriginalLandmarks+1:end, :)', '*b');  % Plot in blue
%             end
%         end
%     else
%         % Save image to specified file
%         imwrite(uint8(imgL), [outDir, outFile, '_leftside.jpg']);
%         if ~isempty(lmksL_img)
%             figure; imshow(uint8(imgL)); hold on;
%             % Plot original landmarks in red
%             numOriginalLandmarks = 23;  % Number of original landmarks
%             if size(lmksL_img, 1) >= numOriginalLandmarks
%                 plot2pts(lmksL_img(1:numOriginalLandmarks, :)', '*r');  % Plot in red
%             end
%             % Plot additional landmarks in blue
%             if size(lmksL_img, 1) > numOriginalLandmarks
%                 plot2pts(lmksL_img(numOriginalLandmarks+1:end, :)', '*b');  % Plot in blue
%             end
%             saveas(gcf, [outDir, outFile, '_leftside_with_landmarks.jpg']);
%             % Save landmarks to a .pts file
%             Write_PTS_Landmarks2D([outDir, outFile, '_leftside.pts'], lmksL_img'); % Change lmks_L -> Change lmks_R
%         end
%     end
% 
%     % Store the left-side image data in the output structure
%     map_2Dto3D(3).file = [outDir, outFile, '_leftside.jpg'];  % Set the file path for the left-side image
%     map_2Dto3D(3).image = imgL;  % Store the image data
%     map_2Dto3D(3).map = mapL;  % Store the 2D-to-3D mapping
%     map_2Dto3D(3).angle = deg;  % Store the viewing angle used for this image
%     map_2Dto3D(3).landmarks = lmksL_img;  % Store the landmarks for the left-side image
% end
% 
% % Generate quarter left-side view image
% if contains(render, 'I')  % Check if 'I' is in the render options
%     deg = -45;  % Set rotation angle for quarter left view
%     rad = deg * pi / 180;  % Convert angle to radians
%     Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];  % Rotation matrix for quarter left view
%     coord_qright = Ry * myMesh.verts;  % Rotate mesh for quarter left view
% 
%     if verbose, fprintf('Z-buffering left\t'),
%     end  % Verbose output
%     if ~isempty(lmksQL)  % Check if quarter left landmarks are specified
%         % Perform z-buffering with landmarks for quarter left view
%         [~, ~, imgQR, mapQR, lmksQR_img] = z_buffering_modif(coord_qright, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'Landmarks', lmksQL, 'verbose');
%     else
%         % Perform z-buffering without landmarks for quarter left view
%         [~, ~, imgQR, mapQR] = z_buffering_modif(coord_qright, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'verbose');
%         lmksQR_img = [];  % No landmark images for quarter left view
%     end
%     if verbose, fprintf('\n'),
%     end  % New line for verbose output
% 
%     % Save or display the quarter left-side image
%     if isempty(outFile)  % Check if no output file is specified
%         figure; imshow(uint8(imgQR));  % Display image
%         if ~isempty(lmksQR_img)  % Check if landmark images exist
%             hold on;
%             % Plot original landmarks in red
%             numOriginalLandmarks = 23;  % Number of original landmarks
%             if size(lmksQR_img, 1) >= numOriginalLandmarks
%                 plot2pts(lmksQR_img(1:numOriginalLandmarks, :)', '*r');  % Plot in red
%             end
%             % Plot additional landmarks in blue
%             if size(lmksQR_img, 1) > numOriginalLandmarks
%                 plot2pts(lmksQR_img(numOriginalLandmarks+1:end, :)', '*b');  % Plot in blue
%             end
%         end
%     else
%         % Save image to specified file
%         imwrite(uint8(imgQR), [outDir, outFile, '_qleftside.jpg']);
%         if ~isempty(lmksQR_img)
%             figure; imshow(uint8(imgQR)); hold on;
%             % Plot original landmarks in red
%             numOriginalLandmarks = 23;  % Number of original landmarks
%             if size(lmksQR_img, 1) >= numOriginalLandmarks
%                 plot2pts(lmksQR_img(1:numOriginalLandmarks, :)', '*r');  % Plot in red
%             end
%             % Plot additional landmarks in blue
%             if size(lmksQR_img, 1) > numOriginalLandmarks
%                 plot2pts(lmksQR_img(numOriginalLandmarks+1:end, :)', '*b');  % Plot in blue
%             end
%             saveas(gcf, [outDir, outFile, '_qleftside_with_landmarks.jpg']);
%             % Save landmarks to a .pts file
%             Write_PTS_Landmarks2D([outDir, outFile, '_qleftside.pts'], lmksQR_img');
%         end
%     end
% 
%     % Store the quarter left-side image data in the output structure
%     map_2Dto3D(4).file = [outDir, outFile, '_qleftside.jpg'];  % Set the file path for the left-side image
%     map_2Dto3D(4).image = imgQR;  % Store the image data
%     map_2Dto3D(4).map = mapQR;  % Store the 2D-to-3D mapping
%     map_2Dto3D(4).angle = deg;  % Store the viewing angle used for this image
%     map_2Dto3D(4).landmarks = lmksQR_img;  % Store the landmarks for the quarter left-side image
% end
% 
% 
% % Generate quarter right-side view image
% if contains(render, 'D')  % Check if 'I' is in the render options
%     deg = 45;  % Set rotation angle for quarter left view
%     rad = deg * pi / 180;  % Convert angle to radians
%     Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];  % Rotation matrix for quarter left view
%     coord_qright = Ry * myMesh.verts;  % Rotate mesh for quarter left view
% 
%     if verbose, fprintf('Z-buffering left\t'),
%     end  % Verbose output
%     if ~isempty(lmksQR)  % Check if quarter left landmarks are specified
%         % Perform z-buffering with landmarks for quarter left view
%         [~, ~, imgQR, mapQR, lmksQR_img] = z_buffering_modif(coord_qright, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'Landmarks', lmksQR, 'verbose');
%     else
%         % Perform z-buffering without landmarks for quarter left view
%         [~, ~, imgQR, mapQR] = z_buffering_modif(coord_qright, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'verbose');
%         lmksQR_img = [];  % No landmark images for quarter left view
%     end
%     if verbose, fprintf('\n'),
%     end  % New line for verbose output
% 
%     % Save or display the quarter left-side image
%     if isempty(outFile)  % Check if no output file is specified
%         figure; imshow(uint8(imgQR));  % Display image
%         if ~isempty(lmksQR_img)  % Check if landmark images exist
%             hold on;
%             % Plot original landmarks in red
%             numOriginalLandmarks = 23;  % Number of original landmarks
%             if size(lmksQR_img, 1) >= numOriginalLandmarks
%                 plot2pts(lmksQR_img(1:numOriginalLandmarks, :)', '*r');  % Plot in red
%             end
%             % Plot additional landmarks in blue
%             if size(lmksQR_img, 1) > numOriginalLandmarks
%                 plot2pts(lmksQR_img(numOriginalLandmarks+1:end, :)', '*b');  % Plot in blue
%             end
%         end
%     else
%         % Save image to specified file
%         imwrite(uint8(imgQR), [outDir, outFile, '_qrightside.jpg']);
%         if ~isempty(lmksQR_img)
%             figure; imshow(uint8(imgQR)); hold on;
%             % Plot original landmarks in red
%             numOriginalLandmarks = 23;  % Number of original landmarks
%             if size(lmksQR_img, 1) >= numOriginalLandmarks
%                 plot2pts(lmksQR_img(1:numOriginalLandmarks, :)', '*r');  % Plot in red
%             end
%             % Plot additional landmarks in blue
%             if size(lmksQR_img, 1) > numOriginalLandmarks
%                 plot2pts(lmksQR_img(numOriginalLandmarks+1:end, :)', '*b');  % Plot in blue
%             end
%             saveas(gcf, [outDir, outFile, '_qrightside_with_landmarks.jpg']);
%             % Save landmarks to a .pts file
%             Write_PTS_Landmarks2D([outDir, outFile, '_qrightside.pts'], lmksQR_img');
%         end
%     end
% 
%     % Store the quarter left-side image data in the output structure
%     map_2Dto3D(5).file = [outDir, outFile, '_qrightside.jpg'];  % Set the file path for the left-side image
%     map_2Dto3D(5).image = imgQR;  % Store the image data
%     map_2Dto3D(5).map = mapQR;  % Store the 2D-to-3D mapping
%     map_2Dto3D(5).angle = deg;  % Store the viewing angle used for this image
%     map_2Dto3D(5).landmarks = lmksQR_img;  % Store the landmarks for the quarter right-side image
% end
% 
% 
