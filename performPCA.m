function [coeff, score, latent, mean_verts] = performPCA(meshes)
    % Assumes meshes is a cell array of structs with fields 'verts' and 'faces'
    
    % Reshape data for PCA
    num_meshes = length(meshes);
    [num_points, dim] = size(meshes{1}.verts);
    reshaped_data = zeros(num_points * dim, num_meshes);
    
    for i = 1:num_meshes
        reshaped_data(:, i) = meshes{i}.verts(:);
    end
    
    % Perform PCA
    [coeff, score, latent] = pca(reshaped_data');
    
    % Calculate mean vertices
    mean_verts = mean(reshaped_data, 2);
    mean_verts = reshape(mean_verts, [num_points, dim]);
end
