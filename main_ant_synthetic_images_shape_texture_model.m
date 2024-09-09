%% Create texture and shape training
% Clear all variables from the workspace
clear;
close all;

% Define an anonymous function to reshape matrices into blocks of 3 rows
rsp = @(x) reshape(x,[3,length(x)/3]);

% Add all subfolders of 'matlab_utils' to the search path
addpath(genpath('matlab_utils'))

%%% DIRS
% Define the output directory for synthetic images
outDir = 'synthetic_images_train/';
% Create the output directory if it doesn't exist
if ~exist(outDir, 'dir')
    mkdir(outDir)
end

% Ensure the output directory path ends with a '/'
if outDir(end) ~= '/'
    outDir = [outDir, '/'];
end

% Define the name of the model file to load
model_dir = 'BabyFaceModel_with_landmarks_struct.mat';
model_name = 'BabyFaceModelWithLandmarks';

% Load a normalized texture and shape model
load('TextureShapeModelNormalized_symmetric_corrected.mat')
% Extract the mean normalization texture value
%std_v = TextureShapeModelNormalized.mean_normalization_texture;
% Extract the standard deviation normalization texture value
%mean_v = TextureShapeModelNormalized.std_normalization_texture;
% Extract the mean texture shape
%mu = TextureShapeModelNormalized.meanTextureShape;

% Load shape and texture samples
load 'shape_texture_samples_10e4.mat'

% Number of modes needed to explain the desired variance
nOfModes = find(cumsum(TextureShapeModelNormalized.pctVar_per_eigen) > var, 1);

%%% MODEL LMKS IND
% Load the model from the .mat file
loaded_model = load(model_dir, model_name);
model = loaded_model.(model_name);
% Assign the landmark vertices of the model to lmks23
lmks = model.landmarks_all;

%%% CREATE MEAN MESH FROM MODEL TO FIND FRONTAL ROTATION ANGLES
% Assign the reference shape of the model to meanMesh.verts
meanMesh.verts = model.refShape;
% Assign the triangulation of the model to meanMesh.faces
meanMesh.faces = model.triang;
% Define the rotation angle in radians
rad_x = -11 * pi / 180;
% Create a rotation matrix for the X-axis
Rx = [1, 0, 0; 0, cos(rad_x), -sin(rad_x); 0, sin(rad_x), cos(rad_x)];
% Apply the rotation to the vertices of meanMesh
meanMesh.verts = Rx * meanMesh.verts;

% Reassign the mean normalization texture value
std_v = TextureShapeModelNormalized.mean_normalization_texture;
% Reassign the standard deviation normalization texture value
mean_v = TextureShapeModelNormalized.std_normalization_texture;
% Reassign the mean texture shape
mu = TextureShapeModelNormalized.meanTextureShape;
% Assign the lambda variable from the model
lambda = TextureShapeModelNormalized.lambda;
% Assign the eigenVectors from the model
eigenVec = TextureShapeModelNormalized.eigenVectors;
% Assign the eigenValues from the model
eigenVal = TextureShapeModelNormalized.eigenValues;
% Assign the percentage of variance explained by each eigenvector
pctVar = TextureShapeModelNormalized.pctVar_per_eigen;
% Assign the triangulation from the model
triang = TextureShapeModelNormalized.triang;
% Assign the vertices of the mean mesh
meanMesh_verts = meanMesh.verts;

% Save the variables into a .mat file
save('var_synt_render_new.mat', 'meanMesh_verts', 'triang', "pctVar", "eigenVal", "eigenVec", "mu", "lmks", 'mean_v', 'std_v', 'lambda', 'Rx', 'var', 'chi_squared')
% Clear the model_name variable from the workspace
clearvars model_name;

% Iterate over the number of shape and texture samples
for i = 4 %1:size(b_shape_texture, 2) 
    % Define the output directory for the current samp
    outDir_i = sprintf('%ssynthetic_shape_%05i/', outDir, i);

    % Create the directory if it doesn't exist
    if ~exist(outDir_i, 'dir')
        mkdir(outDir_i);
    end

    % Start the timern
    tic;

    % Check if the image already exists and skip if found
    if exist(sprintf('%ssynthetic_shape_%05i_qrightside.jpg', outDir_i, i), 'file')
        fprintf(' -> FOUND\n')
        continue;
    end
    fprintf('\n------------------\n')

    %%% RECOVER SHAPE AND TEXTURE

    % Extract the shape and texture coefficients for the current sample
    b = b_shape_texture(:, i);
    % Reconstruct the shape and texture from the coefficients and eigenVectors
    shapetexture = mu + b' * TextureShapeModelNormalized.eigenVectors(:, 1:nOfModes)';

    % Separate the shape data
    shape = rsp(shapetexture(1:93081));
    % Separate and normalize the texture data
    texture = rsp(shapetexture(93081+1:end) ./ TextureShapeModelNormalized.lambda);

    % Assign the shape to myShape
    myShape = shape;
    % Assign the triangulation
    triang = TextureShapeModelNormalized.triang;

    % Assign the texture to myTexture
    myTexture = texture;
    % Adjust the texture with normalization values
    myTexture = myTexture .* (mean(std_v) + TextureShapeModelNormalized.epsilon) + mean(mean_v)';
    % Rescale the texture to the range [0, 255]
    myTexture = rescale(myTexture) * 255;

    %%% COMPUTE ROTATION ANGLES TO FRONTALISE ORIGINAL MESH
    % Apply Procrustes to align the mean mesh with the current shape
    [~, ~, transform] = apply_procrustes2lmks(meanMesh.verts(:, lmks)', myShape(:, lmks)', myShape);
    % Convert the transformation matrix to Euler angles
    rotAnglesXYZ = rotm2eul(transform.T', 'XYZ');

    % Visualization of the shape and texture
    figure;
    % Plot the mesh with texture
    mesh_plot(struct('faces', triang, 'verts', myShape), myTexture ./ 255);
    material([0.9 0.8 0]);
    figure;
    % Plot the mesh without texture
    mesh_plot(struct('faces', triang, 'verts', myShape));
    material([0.3 0.7 0]);
    colormap([0.9 0.9 0.9]);

    %%% GENERATE SYNTHETIC IMAGES
    % Initialize flag for appropriate size
    good_sizes = false;
    % Define a scaling factor for image size
    scale_for_imgSize = 1e-4;
    while ~good_sizes
        % Render synthetic images and save the results
        map = render_images_FLR_modif(false, struct('faces', triang, 'verts', myShape), myTexture', rotAnglesXYZ, ...
            'LandmarksF', lmks, 'LandmarksL', lmks, 'LandmarksR', lmks, 'LandmarksQR', lmks, 'LandmarksQL', lmks, ...
            'save_output', outDir_i, sprintf('synthetic_shape_%05i', i), ...% 'verbose', ...
            'scale_for_imgSize', scale_for_imgSize);
        % Verify that all images have a size greater than 112x112
        good_sizes = all(cellfun(@(x) all(size(x, 1:2) > 112), {map.image}));
        % Adjust the scaling factor if the size is not appropriate
        scale_for_imgSize = scale_for_imgSize - 1e-4;
    end

    % Print the time taken to process the current sample
    fprintf('\t%.2f sec\n', toc)
end
