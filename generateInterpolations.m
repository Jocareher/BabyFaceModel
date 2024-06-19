function generateInterpolations(mean_mesh, synthetic_meshes, steps, closest_vertices, coeff, score, mean_verts, save_meshes)
    % generateInterpolations Generates interpolations between the mean mesh and synthetic meshes.
    %   generateInterpolations(mean_mesh, synthetic_meshes, steps, closest_vertices, coeff, score, mean_verts, save_meshes)
    %   creates interpolated meshes between a given mean mesh and synthetic meshes, saving the intermediate steps and generating videos from different angles.
    %
    %   Inputs:
    %   - mean_mesh: Struct with fields 'verts' and 'faces' representing the mean mesh.
    %   - synthetic_meshes: Cell array of structs representing the synthetic meshes.
    %   - steps: Number of intermediate steps to generate for the interpolation.
    %   - closest_vertices: Cell array of closest landmark vertex indices for each region.
    %   - coeff: Principal component coefficients from PCA.
    %   - score: Principal component scores from PCA.
    %   - mean_verts: Mean vertex positions from PCA.
    %   - save_meshes: Boolean indicating whether to save the interpolated meshes to PLY files.
    %
    %   Outputs:
    %   - Generates AVI videos from different angles and optionally saves interpolated meshes as PLY files.

    % Number of synthetic meshes
    num_meshes = length(synthetic_meshes);

    % Prepare the video writers for different angles
    v_frontal = VideoWriter('interpolated_animation_frontal.avi');
    v_right = VideoWriter('interpolated_animation_right.avi');
    v_left = VideoWriter('interpolated_animation_left.avi');

    % Set the frame rate for the videos
    v_frontal.FrameRate = 15;
    v_right.FrameRate = 15;
    v_left.FrameRate = 15;

    % Open the video writers
    open(v_frontal);
    open(v_right);
    open(v_left);

    % Fixed elevation angle for the views
    elevation_angle = 30;

    % Loop through each synthetic mesh
    for i = 1:num_meshes
        % Get the synthetic score for the current mesh
        synthetic_score = score(i + 1, :);  % +1 because the first row is the mean mesh

        % Loop through each interpolation step
        for s = 0:steps
            % Linear interpolation coefficient
            alpha = s / steps;

            % Interpolate in the PCA space
            interpolated_score = alpha * synthetic_score;

            % Convert the interpolated score back to vertex space
            interpolated_verts = mean_verts(:) + coeff * interpolated_score';

            % Reshape to the original vertex size
            interpolated_verts = reshape(interpolated_verts, size(mean_mesh.verts));

            % Create the interpolated mesh structure
            interpolated_mesh.verts = interpolated_verts;
            interpolated_mesh.faces = mean_mesh.faces;

            % Plot and save frames from different angles
            plotAndSaveFrame(interpolated_mesh, closest_vertices, 0, elevation_angle, v_frontal);
            plotAndSaveFrame(interpolated_mesh, closest_vertices, 90, elevation_angle, v_right);
            plotAndSaveFrame(interpolated_mesh, closest_vertices, -90, elevation_angle, v_left);

            % Save the interpolated mesh to a PLY file if save_meshes is true
            if save_meshes
                filename = sprintf('interpolated_mesh_%d_step_%d.ply', i, s);
                interpolated_mesh_surface = surfaceMesh(interpolated_mesh.verts', interpolated_mesh.faces');
                writeSurfaceMesh(interpolated_mesh_surface, filename);
            end

            % Add a pause to make the animation slower
            pause(0.5); % Pause for 0.2 seconds
        end
    end

    % Close the video writers
    close(v_frontal);
    close(v_right);
    close(v_left);
end