% Define an anonymous function to reshape input to 3xN format
rsp = @(x) reshape(x, 3,[]);

% LOAD BABY MODEL
% Add the path to the Matlab utilities
addpath(genpath('Matlab_utils'))
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

% Load averaged landmarks
load('vertex_clusters.mat');

% MEAN + LANDMARKS MODEL
figure;
% Plot the mean mesh
mesh_plot(mean_mesh);
% Set the material properties for the plot
material([0.3 0.7 0]);
% Set the colormap for the plot
colormap([0.9 0.9 0.9]);
hold on;

% Plot the vertex clusters on the mesh
colors = ['r', 'g', 'b', 'c', 'm', 'y'];
for i = 1:length(vertex_clusters)
    cluster = vertex_clusters{i};
    plot3(mean_mesh.verts(1, cluster), mean_mesh.verts(2, cluster), mean_mesh.verts(3, cluster), '*', 'Color', colors(i));
    for j = 1:length(cluster)
        text(mean_mesh.verts(1, cluster(j)), mean_mesh.verts(2, cluster(j)), mean_mesh.verts(3, cluster(j)) + 0.001, sprintf('C%d-%d', i, j), 'FontSize', 14, 'Color', colors(i));
    end
end

%% GENERATE SYNTHETIC DATASET
% Number of samples to generate
nOfSamples = 10;
% Chi-squared value for the synthetic data generation
chi_squared = 0.99; % 0.99
% Variance for the synthetic data generation
var = 99; % 99
% Determine the number of modes needed to reach the specified variance
nOfModes = find(cumsum(FaceModel.pctVar_per_eigen) > var, 1);

% Calculate the chi-squared inverse for the number of modes
beta2 = chi2inv(chi_squared, nOfModes);

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

    % Calculate the chi-squared inverse for the number of modes
    beta2 = chi2inv(chi_squared, nOfModes);
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

% Plot the vertex clusters on the synthetic mesh
hold on;
for k = 1:length(vertex_clusters)
    cluster = vertex_clusters{k};
    plot3(mesh_s.verts(1, cluster), mesh_s.verts(2, cluster), mesh_s.verts(3, cluster), '*', 'Color', colors(k));
    for j = 1:length(cluster)
        text(mesh_s.verts(1, cluster(j)), mesh_s.verts(2, cluster(j)), mesh_s.verts(3, cluster(j)) + 0.001, sprintf('C%d-%d', k, j), 'FontSize', 14, 'Color', colors(k));
    end
end

% Export the synthetic mesh to PLY using surfaceMesh
synthetic_mesh_surface = surfaceMesh(mesh_s.verts', mesh_s.faces');
writeSurfaceMesh(synthetic_mesh_surface, sprintf('synthetic_mesh_%d.ply', i));
end

% Generate interpolations between the mean mesh and synthetic meshes
steps = 10; % Number of intermediate steps
generate_interpolations(mean_mesh, synthetic_meshes, steps);

% Plotting the vertex clusters on interpolated meshes
for i = 1:length(synthetic_meshes)
    for s = 0:steps
        filename = sprintf('interpolated_mesh_%d_step_%d.ply', i, s);
        interpolated_mesh = readMesh(filename);
        figure;
        mesh_plot(interpolated_mesh);
        material([0.3 0.7 0]);
        colormap([0.9 0.9 0.9]);
        hold on;
        for k = 1:length(vertex_clusters)
            cluster = vertex_clusters{k};
            plot3(interpolated_mesh.verts(1, cluster), interpolated_mesh.verts(2, cluster), interpolated_mesh.verts(3, cluster), '*', 'Color', colors(k));
            for j = 1:length(cluster)
                text(interpolated_mesh.verts(1, cluster(j)), interpolated_mesh.verts(2, cluster(j)), interpolated_mesh.verts(3, cluster(j)) + 0.001, sprintf('C%d-%d', k, j), 'FontSize', 14, 'Color', colors(k));
            end
        end
    end
end
