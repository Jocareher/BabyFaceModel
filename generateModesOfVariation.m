function generateModesOfVariation(mean_mesh, coeff, mean_verts, num_modes, steps, closest_vertices, save_meshes)
    % generateModesOfVariation Generates and visualizes modes of variation.
    %   This function creates visualizations of the principal modes of variation 
    %   in a set of 3D meshes using Principal Component Analysis (PCA). 
    %   It interpolates between the mean shape and variations along the principal modes,
    %   generates animations of these variations, and optionally saves the interpolated 
    %   meshes as PLY files with colored landmarks.
    %
    %   Inputs:
    %       mean_mesh (struct): Structure with fields 'verts' and 'faces' representing the mean mesh.
    %       coeff (matrix): PCA coefficients (eigenvectors) where each column corresponds to a principal mode.
    %       mean_verts (matrix): Mean vertices of the mesh.
    %       num_modes (int): Number of principal modes to visualize.
    %       steps (int): Number of interpolation steps between -alpha and +alpha.
    %       closest_vertices (cell array): Cell array of closest landmark vertex indices for each region.
    %       save_meshes (bool): Flag to save the interpolated meshes as PLY files.
    %
    %   Outputs:
    %       Generates visualizations of the principal modes of variation.
    %       If save_meshes is true, saves the interpolated meshes as PLY files with colored landmarks.

    % Display size of coeff for debugging
    disp(size(coeff));

    % Ensure num_modes does not exceed the number of columns in coeff
    num_modes = min(num_modes, size(coeff, 2));

    % Prepare the video writers for different angles
    v_frontal = VideoWriter('modes_of_variation_frontal.avi');
    v_right = VideoWriter('modes_of_variation_right.avi');
    v_left = VideoWriter('modes_of_variation_left.avi');

    % Set the frame rate for the videos
    v_frontal.FrameRate = 10;
    v_right.FrameRate = 10;
    v_left.FrameRate = 10;

    % Open the video writers
    open(v_frontal);
    open(v_right);
    open(v_left);

    % Fixed elevation angle for the views
    elevation_angle = 30;

    % Loop through each principal mode
    for mode = 1:num_modes
        % Loop through each interpolation step
        for s = -steps:steps
            % Linear interpolation coefficient
            alpha = s / steps;

            % Modify the mean vertices by the principal mode
            interpolated_verts = mean_verts(:) + alpha * coeff(:, mode);

            % Reshape to the original vertex size
            interpolated_verts = reshape(interpolated_verts, size(mean_mesh.verts));

            % Create the interpolated mesh structure
            interpolated_mesh.verts = interpolated_verts;
            interpolated_mesh.faces = mean_mesh.faces;

            % Plot and save frames from different angles
            plotAndSaveFrame(interpolated_mesh, closest_vertices, 0, elevation_angle, v_frontal);
            plotAndSaveFrame(interpolated_mesh, closest_vertices, 90, elevation_angle, v_right);
            plotAndSaveFrame(interpolated_mesh, closest_vertices, -90, elevation_angle, v_left);

            % Save the interpolated mesh to a PLY file if specified
            if save_meshes
                % Create a matrix for colors (vertices are white by default)
                colors = repmat([255, 255, 255], size(interpolated_verts, 2), 1);
                
                % Change the color of the landmarks to red
                for k = 1:length(closest_vertices)
                    colors(closest_vertices{k}, :) = repmat([255, 0, 0], length(closest_vertices{k}), 1);
                end
                
                % Save the mesh with colors
                savePlyWithColors(interpolated_mesh.verts', interpolated_mesh.faces', colors, sprintf('mode_%d_step_%d.ply', mode, s + steps + 1));
            end

            % Add a pause to make the animation slower
            pause(0.2); % Pause for 0.2 seconds
        end
    end

    % Close the video writers
    close(v_frontal);
    close(v_right);
    close(v_left);
end
