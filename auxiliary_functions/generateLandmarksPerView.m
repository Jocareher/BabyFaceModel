function map_2Dto3D = generateLandmarksPerView(viewType, myMesh, myTexture, cam, tform, dist, scale_for_imgSize, lmks, outDir, outFile, deg)
% generateLandmarksPerView Generates and saves 2D images from different views of a 3D mesh
% and overlays landmarks if available.
%
% This function takes a 3D mesh, its texture, and various view settings (frontal, left, right,
% quarter views) to render 2D images. It computes the z-buffer for visibility checks and overlays 
% landmarks, if provided, with visibility information.
%
% INPUT:
%   viewType         - A string indicating the type of view ('frontal', 'left', 'right', etc.)
%   myMesh           - A structure containing the 3D mesh with 'verts' and 'faces'.
%   myTexture        - The texture image to apply to the mesh.
%   cam              - Camera matrix (intrinsic parameters).
%   tform            - Transformation matrix to position the mesh.
%   dist             - Distortion coefficients for camera lens.
%   scale_for_imgSize- Scaling factor for the image size.
%   lmks             - Indices of the landmarks on the mesh.
%   outDir           - Directory to save output images.
%   outFile          - Base file name for saving images.
%   deg              - Angle of rotation for non-frontal views.
%
% OUTPUT:
%   map_2Dto3D       - A structure array containing image file paths, image data, angle, and landmark positions.

    originalVerts = myMesh.verts;  % Save original vertex coordinates of the mesh

    % Close any open figures to avoid conflicts
    close all;

    % Perform specific rotation based on viewType
    if strcmp(viewType, 'left')
        deg = -75;
        rad = deg * pi / 180;  % Convert degrees to radians
        Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];  % Rotation matrix around Y-axis
        myMesh.verts = Ry * originalVerts;  % Apply the rotation
    elseif strcmp(viewType, 'right')
        deg = 75;
        rad = deg * pi / 180;
        Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];
        myMesh.verts = Ry * originalVerts;
    elseif strcmp(viewType, 'quarter_right')
        deg = 45;
        rad = deg * pi / 180;
        Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];
        myMesh.verts = Ry * originalVerts;
    elseif strcmp(viewType, 'quarter_left')
        deg = -45;
        rad = deg * pi / 180;
        Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];
        myMesh.verts = Ry * originalVerts;
    end

    % Perform z-buffering projection with landmarks
    if ~isempty(lmks)
        % Compute 2D landmark positions and visibility using z-buffering
        [~, ~, img, map, lmks_img, lmk_visibility] = z_buffering_modif(myMesh.verts, myMesh.faces, myTexture, cam, tform, dist, 'Landmarks', lmks, 'scale_for_imgSize', scale_for_imgSize);
    else
        % Perform z-buffering without landmarks
        [~, ~, img, map] = z_buffering_modif(myMesh.verts, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize);
        lmks_img = [];
        lmk_visibility = [];
    end

    % Create a figure for displaying the image
    figureHandle = figure('Visible', 'off');
    imshow(uint8(img));  % Display the generated image
    hold on;  % Hold the figure to overlay landmarks if necessary

    % Plot landmarks if available
    if ~isempty(lmks_img)
        plotLandmarks(lmks_img, lmk_visibility);  % Overlay landmarks with visibility
    end

    % Save the image or display it
    if isempty(outFile)
        set(figureHandle, 'Visible', 'on');  % Display the figure
    else
        if ~exist(outDir, 'dir')
            mkdir(outDir);  % Create output directory if it doesn't exist
        end
        imwrite(uint8(img), [outDir, outFile, sprintf('_%s.jpg', viewType)]);  % Save image without landmarks
        saveas(figureHandle, [outDir, outFile, sprintf('_%s_with_landmarks.jpg', viewType)]);  % Save image with landmarks
        Write_PTS_Landmarks2D([outDir, outFile, sprintf('_%s.pts', viewType)], lmks_img');  % Save landmarks in .pts file
    end

    % Close the figure
    close(figureHandle);

    % Populate the output structure with image data and landmark positions
    map_2Dto3D.file = [outDir, outFile, sprintf('_%s.jpg', viewType)];
    map_2Dto3D.image = img;
    map_2Dto3D.map = map;
    map_2Dto3D.angle = deg;
    map_2Dto3D.landmarks = lmks_img;

    % Restore original vertex coordinates for next iteration
    myMesh.verts = originalVerts;
end

function plotLandmarks(lmks_img, lmk_visibility)
% plotLandmarks Plots landmarks on a 2D image, differentiating visible and non-visible landmarks.
%
% INPUT:
%   lmks_img        - 2D coordinates of landmarks projected onto the image.
%   lmk_visibility  - Boolean array indicating the visibility of each landmark.
%
% The function plots visible landmarks in red ('*r') and non-visible landmarks in blue ('*b').

    % Separate visible and non-visible landmarks
    visible_lmks = lmks_img(lmk_visibility, :);
    non_visible_lmks = lmks_img(~lmk_visibility, :);

    % Plot visible landmarks in red
    if ~isempty(visible_lmks)
        plot2pts(visible_lmks', '*r');
    end

    % Plot non-visible landmarks in blue
    if ~isempty(non_visible_lmks)
        plot2pts(non_visible_lmks', '*b');
    end
end