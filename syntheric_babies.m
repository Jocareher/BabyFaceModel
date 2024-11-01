clear all;
close all;


% Define an anonymous function para reshape input to 3xN format
rsp = @(x) reshape(x, 3,[]);

% LOAD BABY MODEL
% Add all subfolders of 'matlab_utils' to the search path
addpath(genpath('matlab_utils'))

% Add all subfolders of 'auxiliary_functions' to the search path
addpath(genpath('auxiliary_functions'))

% Add all subfolders of 'mat_files' to the search path
addpath(genpath('mat_files'))

% Load the baby face model from a .mat file
load('BabyFaceModel.mat');
% Assign the loaded model to a variable
FaceModel = BabyFaceModel;

% Baby morphable model characteristics

% Set the variance for the model
options.var = 98;
var = '_var_98';
% Set the chi-squared value for the model
options.chi_squared = 0.9999999999999999; % 0.9999999999999999
% Determine the number of dimensions needed to reach the specified variance
options.ndims = find(cumsum(FaceModel.pctVar_per_eigen) > options.var, 1);
% Reshape the reference shape into a 1xN format
options.shapeMU = reshape(FaceModel.refShape, 1, []);
% Get the landmark vertices indices from the model
options.lmks_vertsIND = FaceModel.landmark_verts;
% Get the eigenvalues up to the specified number of dimensions
options.shapeEV = FaceModel.eigenValues(1:options.ndims);
% Get the eigenfunctions up to the specified number of dimensions
options.shapePC = FaceModel.eigenFunctions(:, 1:options.ndims);
% Get the triangulation of the face model
options.trilist = FaceModel.triang;

% New model
% Set the mean deformation from the model
options.meanDeformation = FaceModel.meanDeformation;
% Calculate the scale factor based on the size of the reference shape
options.scale_factor = sqrt(size(FaceModel.refShape, 2));

% Mesh structure creation mesh.verts and mesh.faces
% Reshape the mean to put in 3xN vertex representation
mean_mesh.verts = reshape(options.shapeMU, 3, []);
% Set the mesh triangulation (convert to double)
mean_mesh.faces = double(options.trilist);

% mean_mesh.verts shape = 3xM
% mean_mesh.faces shape = 3xM
% Export the mean mesh to PLY using surfaceMesh
mean_mesh_surface = surfaceMesh(mean_mesh.verts', mean_mesh.faces');
writeSurfaceMesh(mean_mesh_surface, "mean_mesh.ply");

% Check trilist and num_vertices
%disp('Triangulation List:');
%disp(options.trilist);

% Generate the connectivity matrix
%num_vertices = size(mean_mesh.verts, 2);
%disp('Number of vertices:');
%disp(num_vertices);
%generateMeshConnectivity(options.trilist', num_vertices);

% LSCM Projection
%vertices = reshape(FaceModel.refShape, 3, [])';
%faces = double(FaceModel.triang)';

% Selección de puntos de anclaje (esquinas de los ojos)
%anchor_points = [find(strcmp(FaceModel.landmark_names, 'exR')), find(strcmp(FaceModel.landmark_names, 'exL'))];

%[u, v] = lscm(vertices, faces, anchor_points);

% Display the projection with edges
%figure;
%trimesh(faces, u, v, zeros(size(u)), 'EdgeColor', 'k');
%title('LSCM Projection of 3D Mesh to 2D');
%xlabel('u');
%ylabel('v');
%axis equal;


% Load the appropriate landmarks file
load('centroids_landmarks_49_fixed.mat');

% MEAN + LANDMARKS MODEL
figure;
% Plot the mean mesh
mesh_plot(mean_mesh);
% Set the material properties for the plot
material([0.3 0.7 0]);
% Set the colormap for the plot
colormap([0.9 0.9 0.9]);
hold on;
% Plot the original landmarks on the mesh
plot3(mean_mesh.verts(1, options.lmks_vertsIND(:)), mean_mesh.verts(2, options.lmks_vertsIND(:)), mean_mesh.verts(3, options.lmks_vertsIND(:)), '*r');
% Add text labels for the original landmarks
text(mean_mesh.verts(1, options.lmks_vertsIND(:)), mean_mesh.verts(2, options.lmks_vertsIND(:)), mean_mesh.verts(3, options.lmks_vertsIND(:)) + 0.001, BabyFaceModel.landmark_names, 'FontSize', 14);

% Plot the averaged landmarks on the mesh
for k = 1:length(closest_vertices)
    plot3(mean_mesh.verts(1, closest_vertices{k}), mean_mesh.verts(2, closest_vertices{k}), mean_mesh.verts(3, closest_vertices{k}), '*b');
end

% Display additional debug information
%disp('Averaged landmarks:');
%disp(closest_vertices);

%% GENERATE SYNTHETIC DATASET
% Number of samples to generate
nOfSamples = 1;
% Chi-squared value for the synthetic data generation
chi_squared = 0.99; % 0.99
% Variance for the synthetic data generation
var = 99; % 99
% Determine the number of modes needed to reach the specified variance
nOfModes = find(cumsum(FaceModel.pctVar_per_eigen) > var, 1);

% Generate random coefficients for the eigenvalues within a range
b = FaceModel.eigenValues(1:nOfModes) .* (-3 + (3 + 3) * rand(nOfModes, nOfSamples)) * 10^6;
%b = b';
% Calculate the Mahalanobis distance squared
dMah2 = diag(b' * diag(1 ./ FaceModel.eigenValues(1:nOfModes)) * b);

synthetic_meshes = cell(1, nOfSamples);

% Loop to generate and plot synthetic samples
for i = 1:nOfSamples % nOfSamples
    % Compute the new shape by adding mean deformation, mean shape, and the weighted eigenfunctions
    aux = FaceModel.meanDeformation' + options.shapeMU' + (FaceModel.eigenFunctions(:, 1:nOfModes) * b(:, i));
    % Reshape the result to 3xN format
    rec = rsp(aux);

    figure;
    % Create a structure for the synthetic mesh
    mesh_s.verts = rec;
    mesh_s.faces = double(options.trilist);
    synthetic_meshes{i} = mesh_s;

    % Plot the synthetic mesh
    mesh_plot(mesh_s);
    % Set the material properties for the plot
    material([0.3 0.7 0]);
    % Set the colormap for the plot
    colormap([0.9 0.9 0.9]);

    % Plot the closest landmarks on the synthetic mesh
    hold on;
    for k = 1:length(closest_vertices)
        idx = closest_vertices{k}; 
        plot3(mesh_s.verts(1, idx), mesh_s.verts(2, idx), mesh_s.verts(3, idx), '*b');
    end
    
    % Plot the original landmarks on the synthetic mesh
    for k = 1:length(options.lmks_vertsIND)
        idx = options.lmks_vertsIND(k);
        plot3(mesh_s.verts(1, idx), mesh_s.verts(2, idx), mesh_s.verts(3, idx), '*r');
    end
    
    % Export the synthetic mesh to PLY using surfaceMesh
    synthetic_mesh_surface = surfaceMesh(mesh_s.verts', mesh_s.faces');
    writeSurfaceMesh(synthetic_mesh_surface, sprintf('synthetic_mesh_%d.ply', i));
end

% Convert mean_mesh to cell and concatenate with synthetic_meshes
all_meshes = [{mean_mesh}, synthetic_meshes];

% Perform PCA on the mean mesh and synthetic meshes
[coeff, score, latent, mean_verts] = performPCA(all_meshes);

% Generate interpolations between the mean mesh and synthetic meshes
%steps = 3; % Number of intermediate steps
%generateInterpolations(mean_mesh, synthetic_meshes, steps, closest_vertices, coeff, score, mean_verts, false);

% Generate and visualize mode of variations
num_modes = 5; % Num of principal modes to visualize
steps = 10;
sigma = 0.1;
save_meshes = true;

% Generate mode of variation between the mean mesh and synthetic meshes
generateModesOfVariation(mean_mesh, coeff, mean_verts, num_modes, steps, closest_vertices, options.lmks_vertsIND, sigma, save_meshes);

