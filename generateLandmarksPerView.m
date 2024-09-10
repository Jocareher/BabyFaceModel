function map_2Dto3D = generateLandmarksPerView(viewType, myMesh, myTexture, cam, tform, dist, scale_for_imgSize, lmks, outDir, outFile, deg)
% generateLandmarksPerView Generates and saves images for different views of a 3D mesh and overlays landmarks if available.
%
%   map_2Dto3D = generateLandmarksPerView(viewType, myMesh, myTexture, cam, tform, dist, scale_for_imgSize, lmks, outDir, outFile, deg)
%   generates a 2D image of a 3D mesh from a specified view ('frontal', 'left', or 'right'), performs z-buffering to
%   project the mesh onto the 2D plane, and optionally overlays landmarks if provided. The function supports saving the
%   generated images with and without landmarks, and storing landmark coordinates in a .pts file.
%
% INPUTS:
%   viewType        - A string specifying the view ('left', 'right', or 'frontal') for which the image is generated.
%   myMesh          - A structure containing the 3D mesh with fields 'verts' (vertices) and 'faces' (triangulation).
%   myTexture       - Texture map applied to the mesh.
%   cam             - Camera matrix used for projection.
%   tform           - Transformation matrix applied to the mesh before projection.
%   dist            - Distortion parameters for camera projection.
%   scale_for_imgSize - Scaling factor for adjusting the image size.
%   lmks            - Optional, a set of landmark coordinates to be projected onto the 2D image.
%   outDir          - Directory where the output images and .pts files will be saved.
%   outFile         - Base name for the output files (image and .pts).
%   deg             - Rotation angle used for specific views (left or right).
%
% OUTPUTS:
%   map_2Dto3D      - A structure containing the 2D-to-3D mapping, the generated image, and the file paths for the output images.

    originalVerts = myMesh.verts;  % Save the original vertex coordinates

    % Close any open figures to avoid conflicts with previous figures
    close all;

    % Perform specific rotation based on the viewType
    if strcmp(viewType, 'left')
        % Rotation matrix for the left view (rotate -75 degrees around the Y-axis)
        deg = -75;
        rad = deg * pi / 180;  % Convert degrees to radians
        Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];  % Rotation matrix
        myMesh.verts = Ry * originalVerts;  % Apply the rotation
    elseif strcmp(viewType, 'right')
        % Rotation matrix for the right view (rotate 75 degrees around the Y-axis)
        deg = 75;
        rad = deg * pi / 180;  % Convert degrees to radians
        Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];  % Rotation matrix
        myMesh.verts = Ry * originalVerts;  % Apply the rotation
    elseif strcmp(viewType, 'quarter_right')
        % Rotation matrix for the quarter-right view (rotate 45 degrees around the Y-axis)
        deg = 45;
        rad = deg * pi / 180;  % Convert degrees to radians
        Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];  % Rotation matrix
        myMesh.verts = Ry * originalVerts;  % Apply the rotation
    elseif strcmp(viewType, 'quarter_left')
        % Rotation matrix for the quarter-left view (rotate 45 degrees around the Y-axis)
        deg = -45;
        rad = deg * pi / 180;  % Convert degrees to radians
        Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];  % Rotation matrix
        myMesh.verts = Ry * originalVerts;  % Apply the rotation
    end

    % Perform z-buffering projection with or without landmarks
    if ~isempty(lmks)
        % If landmarks are provided, perform z-buffering and also compute 2D landmark positions
        [~, ~, img, map, lmks_img] = z_buffering_modif(myMesh.verts, myMesh.faces, myTexture, cam, tform, dist, 'Landmarks', lmks, 'scale_for_imgSize', scale_for_imgSize);
    else
        % Perform z-buffering without landmarks
        [~, ~, img, map] = z_buffering_modif(myMesh.verts, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize);
        lmks_img = [];  % No landmarks to project
    end

    % Create a figure for displaying the image
    figureHandle = figure('Visible', 'off');  % Create the figure but don't show it immediately
    imshow(uint8(img));  % Display the generated image
    hold on;  % Hold the figure open to overlay landmarks if necessary

    % If landmarks exist, plot them on the image
    if ~isempty(lmks_img)
        numOriginalLandmarks = 23;  % Number of original landmarks
        plotLandmarks(lmks_img, numOriginalLandmarks);  % Call the function to plot landmarks
    end

    % Save or display the image depending on the presence of outFile
    if isempty(outFile)
        % If no file name is provided, show the figure with the image and landmarks
        set(figureHandle, 'Visible', 'on');  % Set the figure visibility to 'on' to display it
    else
        % Ensure the output directory exists before saving files
        if ~exist(outDir, 'dir')
            mkdir(outDir);  % Create the directory if it doesn't exist
        end

        % Save the image without landmarks
        imwrite(uint8(img), [outDir, outFile, sprintf('_%s.jpg', viewType)]);

        % If landmarks exist, save the image with landmarks and the landmark coordinates in a .pts file
        if ~isempty(lmks_img)
            saveas(figureHandle, [outDir, outFile, sprintf('_%s_with_landmarks.jpg', viewType)]);  % Save the figure with landmarks
            Write_PTS_Landmarks2D([outDir, outFile, sprintf('_%s.pts', viewType)], lmks_img');  % Save landmarks to a .pts file
        end
    end

    % Close the figure to prevent figure accumulation in memory
    close(figureHandle);

    % Populate the output structure map_2Dto3D with image data and file paths
    map_2Dto3D.file = [outDir, outFile, sprintf('_%s.jpg', viewType)];
    map_2Dto3D.image = img;
    map_2Dto3D.map = map;
    map_2Dto3D.angle = deg;
    map_2Dto3D.landmarks = lmks_img;

    % Restore the original vertex coordinates for the next iteration
    myMesh.verts = originalVerts;
end

function plotLandmarks(lmks_img, numOriginalLandmarks)
% plotLandmarks Plots original and additional landmarks on the current figure.
%
%   plotLandmarks(lmks_img, numOriginalLandmarks) plots the landmarks
%   on the image in the current figure. The first set of landmarks is
%   plotted in red, and any additional landmarks are plotted in blue.
%
% INPUTS:
%   lmks_img            - A matrix of 2D projected landmark coordinates.
%   numOriginalLandmarks - The number of original landmarks to plot in red.
%
% This function is called within generateLandmarksPerView to overlay landmarks
% on the generated 2D images.
    
    % Plot original landmarks (first numOriginalLandmarks) in red
    if size(lmks_img, 1) >= numOriginalLandmarks
        plot2pts(lmks_img(1:numOriginalLandmarks, :)', '*r');  % Plot original landmarks in red
    end

    % Plot additional landmarks (if any) in blue
    if size(lmks_img, 1) > numOriginalLandmarks
        plot2pts(lmks_img(numOriginalLandmarks+1:end, :)', '*b');  % Plot additional landmarks in blue
    end
end