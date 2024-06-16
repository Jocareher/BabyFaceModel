function generateModesOfVariation(mean_mesh, coeff, mean_verts, num_modes, steps, closest_vertices, save_meshes)
    % generateModesOfVariation Generates and visualizes modes of variation.
    %   generateModesOfVariation(mean_mesh, coeff, mean_verts, num_modes, steps, closest_vertices, save_meshes)
    %   creates visualizations of the principal modes of variation.
    %
    %   Inputs:
    %       mean_mesh (struct): Structure with fields 'verts' and 'faces' representing the mean mesh.
    %       coeff (matrix): PCA coefficients.
    %       mean_verts (matrix): Mean vertices.
    %       num_modes (int): Number of principal modes to visualize.
    %       steps (int): Number of interpolation steps.
    %       closest_vertices (cell array): Cell array of closest landmark vertex indices for each region.
    %       save_meshes (bool): Flag to save the interpolated meshes as PLY files.
    %
    %   Outputs:
    %       Generates visualizations of the principal modes of variation.

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
                filename = sprintf('mode_%d_step_%d.ply', mode, s + steps + 1);
                interpolated_mesh_surface = surfaceMesh(interpolated_mesh.verts', interpolated_mesh.faces');
                writeSurfaceMesh(interpolated_mesh_surface, filename);
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
