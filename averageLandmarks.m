% RUN_GENERATE_LANDMARKS Script to generate averaged landmarks from CSV files.
%   This script calls the function generateLandmarksFromCSV with the path
%   to the folder containing the CSV files, and generates a MAT file with
%   the averaged landmarks.

% Path to the folder containing the CSV files
folder_path = '/Users/jocareher/Library/CloudStorage/OneDrive-Personal/Educación/PhD_UPF_2023/babyfm_matlab/landmarks_regions';

% Call the function to generate the averaged landmarks
generateLandmarksFromCSV(folder_path, 8, 5);
