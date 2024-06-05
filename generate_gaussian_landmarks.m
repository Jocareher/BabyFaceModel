function generate_gaussian_landmarks(mean_vertices, mean_mesh, var, num_points)
    % GENERATE_GAUSSIAN_LANDMARKS Generates new points around the mean using Gaussian distribution.
    % mean_vertices: Array of vertex indices (1x6) from averaged_landmarks.
    % mean_mesh: Mesh structure containing the vertices and faces.
    % var: Variance for the Gaussian distribution.
    % num_points: Number of points to generate around each mean point.

    % Extract the coordinates of the mean vertices from the mesh
    mean_points = mean_mesh.verts(:, mean_vertices)';
    
    % Number of mean points
    num_means = size(mean_points, 1);
    
    % Initialize cell array to store the new points
    new_points = cell(1, num_means);
    
    % Generate points around each mean
    for i = 1:num_means
        % Mean point
        mu = mean_points(i, :);
        
        % Covariance matrix (assuming isotropic Gaussian for simplicity)
        Sigma = var * eye(3);
        
        % Generate new points using multivariate normal distribution
        points = mvnrnd(mu, Sigma, num_points);
        
        % Store the generated points
        new_points{i} = points;
    end
    
    % Save the new points in a MAT file
    save('gaussian_landmarks.mat', 'new_points');
end
