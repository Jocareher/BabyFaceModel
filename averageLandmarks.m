% RUN_GENERATE_LANDMARKS Script to generate averaged landmarks from CSV files.
%   This script calls the function generateLandmarksFromCSV with the path
%   to the folder containing the CSV files, and generates a MAT file with
%   the averaged landmarks.

% Path to the folder containing the CSV files
folder_path = '/Users/jocareher/Library/CloudStorage/OneDrive-Personal/Educación/PhD_UPF_2023/babyfm_matlab/landmarks_regions/version_2';

% Output filename
output_filename = "centroids_landmarks_49";

% Number of clusters
k = 49;

% Mode of vertices selection
selection_mode = "centroid";

% Leer el archivo CSV con los vértices iniciales
initial_vertices = readtable("/Users/jocareher/Library/CloudStorage/OneDrive-Personal/Educación/PhD_UPF_2023/babyfm_matlab/landmarks_regions/initial_vertices.csv");

% Convertir la tabla a un array para obtener las coordenadas de los puntos iniciales
initial_centroids = table2array(initial_vertices(:, 2:4));

% Mostrar las coordenadas iniciales para verificar
disp(initial_centroids);

% Call the function to generate the averaged landmarks
generateLandmarksFromCSV(folder_path, k, initial_centroids, selection_mode, output_filename);



