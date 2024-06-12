function generateInterpolations(mean_mesh, synthetic_meshes, steps, closest_vertices, coeff, score, mean_verts)
    % Number of synthetic meshes
    num_meshes = length(synthetic_meshes);

    % Prepare the video writers for different angles
    v_frontal = VideoWriter('interpolated_animation_frontal.avi');
    v_right = VideoWriter('interpolated_animation_right.avi');
    v_left = VideoWriter('interpolated_animation_left.avi');

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

            % Save the interpolated mesh to a PLY file
            filename = sprintf('interpolated_mesh_%d_step_%d.ply', i, s);
            interpolated_mesh_surface = surfaceMesh(interpolated_mesh.verts', interpolated_mesh.faces');
            writeSurfaceMesh(interpolated_mesh_surface, filename);

            % Add a pause to make the animation slower
            pause(0.2); % Pause for 0.2 seconds
        end
    end

    % Close the video writers
    close(v_frontal);
    close(v_right);
    close(v_left);
end

function plotAndSaveFrame(interpolated_mesh, closest_vertices, azimuth_angle, elevation_angle, video_writer)
    % Plot the interpolated mesh, plot landmarks, and save the frame to a video.
    figure;
    % Plot the interpolated mesh
    mesh_plot(interpolated_mesh);
    material([0.3 0.7 0]);
    colormap([0.9 0.9 0.9]);
    hold on;

    % Plot the closest landmarks on the interpolated mesh
    for k = 1:length(closest_vertices)
        plot3(interpolated_mesh.verts(1, closest_vertices{k}), interpolated_mesh.verts(2, closest_vertices{k}), interpolated_mesh.verts(3, closest_vertices{k}), '*b');
    end

    % Set the camera view
    view(azimuth_angle, elevation_angle);

    % Capture the frame for the animation
    frame = getframe(gcf);
    writeVideo(video_writer, frame);
    close(gcf);
end
