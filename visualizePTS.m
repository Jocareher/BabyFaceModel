% Clear workspace and close all figures
clear;
close all;

% Add the path to the Matlab utilities
addpath(genpath('matlab_utils'))

% Specify the folder containing the .pts files
folderPath = '/Users/jocareher/Library/CloudStorage/OneDrive-Personal/Educación/PhD_UPF_2023/babyfm_matlab/synthetic_images_train/Synthetic_shape_00002'; % Update this path to your specific folder

% Get a list of all .pts files in the specified folder
ptsFiles = dir(fullfile(folderPath, '*.pts'));

% Loop through each .pts file and visualize the landmarks
for i = 1:length(ptsFiles)
    % Construct the full file name
    fileName = fullfile(ptsFiles(i).folder, ptsFiles(i).name);
    
    % Read the landmarks from the .pts file using Read_PTS_Landmarks2D function
    landmarks = Read_PTS_Landmarks2D(fileName);
    
    % Create a new figure for each .pts file
    figure;
    hold on;
    title(['Landmarks from: ', ptsFiles(i).name]);
    
    % Plot the landmarks
    plot(landmarks(1, :), landmarks(2, :), 'ro', 'MarkerSize', 5, 'MarkerFaceColor', 'r');
    
    % Set plot properties
    xlabel('X');
    ylabel('Y');
    axis equal; % Ensure the x and y axes have equal scaling
    grid on; % Turn on the grid
    hold off;
end
