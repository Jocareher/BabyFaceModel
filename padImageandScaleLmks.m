function processImagesWithPadding(rootDir, paddingFactor, outputDir)
% processImagesWithPadding Applies padding to images, rescales landmarks,
% and saves results.
%
% This function reads all images (.jpg) in the specified root directory and its subdirectories,
% along with their associated .pts files. It applies padding to each image, rescales landmarks
% accordingly, and saves the padded images and updated .pts files in the specified output directory.
%
% INPUT:
% - rootDir: String, path to the root directory containing subdirectories with images and .pts files.
% - paddingFactor: Scalar, percentage of the image size to use as padding (e.g., 0.25 for 25%).
% - outputDir: String, path to the directory where the processed images and .pts files will be saved.
%
% OUTPUT:
% This function does not return any variables. Processed images and .pts files are saved in the outputDir.
%
% Example usage:
%   processImagesWithPadding('input_images/', 0.25, 'output_images/');

    % Get list of all .jpg files in rootDir and its subdirectories
    imageFiles = dir(fullfile(rootDir, '**', '*.jpg'));
    imageFiles = imageFiles(~contains({imageFiles.name}, '_with_landmarks')); % Exclude images with '_with_landmarks' in name

    % Preallocate cell arrays to store processed images, landmarks, and file names
    numFiles = length(imageFiles);
    processedImages = cell(1, numFiles);
    processedLandmarks = cell(1, numFiles);
    fileNames = cell(1, numFiles);

    % Loop through each image file
    for idx = 1:numFiles
        % Load image
        imagePath = fullfile(imageFiles(idx).folder, imageFiles(idx).name);
        img = imread(imagePath);

        % Load landmarks from .pts file
        ptsFile = strrep(imagePath, '.jpg', '.pts');
        [landmarks, visibility] = Read_PTS_Landmarks2D(ptsFile);

        % Apply padding and rescale landmarks
        [imgPadded, landmarksPadded] = applyPaddingAndRescale(img, landmarks, paddingFactor);

        % Store data for visualization
        processedImages{idx} = imgPadded;
        processedLandmarks{idx} = landmarksPadded;
        fileNames{idx} = imageFiles(idx).name; % Store the file name for display

        % Prepare output paths
        [~, name, ~] = fileparts(imageFiles(idx).name);
        outputImageDir = fullfile(outputDir, imageFiles(idx).folder(length(rootDir)+1:end)); % Preserve subfolder structure
        if ~exist(outputImageDir, 'dir')
            mkdir(outputImageDir);
        end
        outputImagePath = fullfile(outputImageDir, [name, '.jpg']);
        outputPtsPath = fullfile(outputImageDir, [name, '.pts']);

        % Save padded image
        imwrite(imgPadded, outputImagePath);

        % Save updated landmarks to .pts file
        Write_PTS_Landmarks2D(outputPtsPath, landmarksPadded, visibility);
    end

    % Display a random sample of images with landmarks and their file names for verification
    displayRandomImages(processedImages, processedLandmarks, fileNames, 8);
end

function [imgPadded, landmarksPadded] = applyPaddingAndRescale(img, landmarks, paddingFactor)
    % applyPaddingAndRescale Adds padding to an image and rescales landmarks.
    %
    % INPUT:
    % - img: Original image to be padded.
    % - landmarks: 2xN matrix of [x; y] landmark coordinates.
    % - paddingFactor: Percentage of the original image size to use as padding.
    %
    % OUTPUT:
    % - imgPadded: Padded image.
    % - landmarksPadded: Rescaled landmarks according to the padding.

    % Calculate padding sizes
    [height, width, ~] = size(img);
    padX = round(paddingFactor * width);
    padY = round(paddingFactor * height);

    % Apply padding to the image
    imgPadded = padarray(img, [padY, padX], 255, 'both');

    % Rescale landmarks
    landmarksPadded = landmarks;
    landmarksPadded(1, :) = landmarks(1, :) + padX; % Shift x-coordinates
    landmarksPadded(2, :) = landmarks(2, :) + padY; % Shift y-coordinates
end

function displayRandomImages(images, landmarks, fileNames, numToDisplay)
% displayRandomImages Displays a random sample of images with landmarks.
%
% INPUT:
% - images: Cell array of processed images.
% - landmarks: Cell array of processed landmarks corresponding to the images.
% - fileNames: Cell array of strings, containing the file names for each image.
% - numToDisplay: Integer, number of images to display. Defaults to 6 if not provided or if greater than available images.

    % Set default number of images to display if not provided
    if nargin < 4 || isempty(numToDisplay)
        numToDisplay = 6;
    end

    % Determine the number of images to display based on availability
    numImages = length(images);
    numToDisplay = min(numToDisplay, numImages); % Limit to the total number of images

    % Randomly select images to display
    sampleIndices = randperm(numImages, numToDisplay);

    % Determine the grid size for the subplot
    gridRows = ceil(sqrt(numToDisplay));
    gridCols = ceil(numToDisplay / gridRows);

    % Create figure for displaying images
    figure;
    for i = 1:numToDisplay
        idx = sampleIndices(i);
        subplot(gridRows, gridCols, i);
        imshow(images{idx});
        hold on;
        plot(landmarks{idx}(1, :), landmarks{idx}(2, :), 'r*'); % Plot landmarks in red
        title(fileNames{idx}, 'Interpreter', 'none'); % Show file name as title
        hold off;
    end
end

% Add all subfolders of 'matlab_utils' to the search path
addpath(genpath('matlab_utils'))

processImagesWithPadding('/Users/jocareher/Documents/synthetic_images_train_test', 0.50, '/Users/jocareher/Documents/synthetic_images_train_scaled');
