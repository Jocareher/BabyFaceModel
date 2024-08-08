% Load the original BabyFaceModel.mat file
matFile = 'BabyFaceModel.mat';
load(matFile);

% Extract the original 23 landmark indices
original_landmarks_indices = BabyFaceModel.landmark_verts;

% Read additional landmark indices from the CSV file
csvFile = './landmarks_regions/landmarks_template.csv';
fileID = fopen(csvFile, 'r');

% Read the CSV file, skipping the header
data = textscan(fileID, '%s', 'Delimiter', '\n', 'HeaderLines', 1);
fclose(fileID);

% Extract the data from the cell array
data = data{1};

% Initialize an array for additional landmark indices
num_additional_landmarks = length(data);
additional_landmarks_indices = zeros(num_additional_landmarks, 1);

% Parse the CSV data to extract the indices
for j = 1:num_additional_landmarks
    line = strsplit(data{j}, ','); % Split the line into components
    % Convert the index to a number and store it
    additional_landmarks_indices(j) = str2double(line{1});
end

% Combine the 23 original indices with the additional indices
landmarks_all = [original_landmarks_indices, additional_landmarks_indices'];

% Display the combined landmark indices for verification
disp('Combined landmark indices (23 original + 49 additional):');
disp(landmarks_all);

% Prepare new struct to include the combined landmark indices
BabyFaceModelWithLandmarks = BabyFaceModel;
BabyFaceModelWithLandmarks.landmarks_all = landmarks_all;

% Save the new structure into a new MAT file
newMatFile = 'BabyFaceModel_with_landmarks.mat';
save(newMatFile, '-struct', 'BabyFaceModelWithLandmarks');

disp('The new MAT file with combined landmark indices has been created: BabyFaceModel_with_landmarks.mat');

% Cargar el archivo con las variables individuales
data = load('BabyFaceModel_with_landmarks.mat');

% Crear una nueva estructura que contenga todas las variables necesarias
BabyFaceModelWithLandmarks = struct();

% Añadir las variables existentes a la estructura
BabyFaceModelWithLandmarks.refShape = data.refShape;
BabyFaceModelWithLandmarks.meanDeformation = data.meanDeformation;
BabyFaceModelWithLandmarks.triang = data.triang;
BabyFaceModelWithLandmarks.landmark_names = data.landmark_names;
BabyFaceModelWithLandmarks.landmark_verts = data.landmark_verts;
BabyFaceModelWithLandmarks.eigenValues = data.eigenValues;
BabyFaceModelWithLandmarks.pctVar_per_eigen = data.pctVar_per_eigen;
BabyFaceModelWithLandmarks.eigenFunctions = data.eigenFunctions;

% Añadir el nuevo conjunto de landmarks
BabyFaceModelWithLandmarks.landmarks_all = data.landmarks_all;

% Guardar la nueva estructura en un archivo MAT
save('BabyFaceModel_with_landmarks_struct.mat', 'BabyFaceModelWithLandmarks');
