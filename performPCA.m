function [coeff, score, latent, mean_verts] = performPCA(meshes)
    % performPCA Performs Principal Component Analysis (PCA) on a set of meshes.
    %   [coeff, score, latent, mean_verts] = performPCA(meshes) takes a cell array of meshes,
    %   reshapes the vertex data for PCA, computes the PCA, and returns the PCA coefficients,
    %   scores, latent values (eigenvalues), and the mean vertices.
    %
    %   Assumes meshes is a cell array of structs with fields 'verts' and 'faces'.
    %
    %   Inputs:
    %   - meshes: Cell array of structs where each struct has fields 'verts' and 'faces'.
    %
    %   Outputs:
    %   - coeff: Principal component coefficients (eigenvectors).
    %   - score: Principal component scores (projection of the data onto the principal components).
    %   - latent: Eigenvalues of the covariance matrix (variance explained by each principal component).
    %   - mean_verts: Mean vertex positions across all meshes.
    %
    %   The function follows these steps:
    %   1. Reshapes the mesh vertex data into a format suitable for PCA.
    %   2. Performs PCA on the reshaped data.
    %   3. Computes the mean vertex positions.

    % Reshape data for PCA
    % Get the number of meshes
    num_meshes = length(meshes);
    % Get the number of vertices and dimensions
    [num_points, dim] = size(meshes{1}.verts);
    % Preallocate array for reshaped data
    reshaped_data = zeros(num_points * dim, num_meshes);
    
    for i = 1:num_meshes
        reshaped_data(:, i) = meshes{i}.verts(:); % Reshape each mesh's vertices into a column vector
    end
    
    % Perform PCA
    [coeff, score, latent] = pca(reshaped_data'); % Perform PCA on the transposed reshaped data
    
    % Calculate mean vertices
    mean_verts = mean(reshaped_data, 2);
    % Reshape the mean vertices back into the original format
    mean_verts = reshape(mean_verts, [num_points, dim]); 
end
