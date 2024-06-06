% Load the closest vertices from the MAT file
load('averaged_landmarks.mat');

% Load the mean mesh (or any representative mesh to get the vertex positions)
load('BabyFaceModel.mat');
FaceModel = BabyFaceModel;
options.shapeMU = reshape(FaceModel.refShape, 3, []);

% Create a CSV file to store the landmark points
fileID = fopen('closest_vertices.csv', 'w');
fprintf(fileID, 'ID,X,Y,Z\n');

% Loop through the closest vertices and write to the CSV file
for k = 1:length(closest_vertices)
    for v = 1:length(closest_vertices{k})
        vert_idx = closest_vertices{k}(v);
        fprintf(fileID, '%d,%f,%f,%f\n', vert_idx, options.shapeMU(1, vert_idx), options.shapeMU(2, vert_idx), options.shapeMU(3, vert_idx));
    end
end

fclose(fileID);
