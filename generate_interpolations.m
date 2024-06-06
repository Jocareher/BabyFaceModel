function generate_interpolations(mean_mesh, synthetic_meshes, steps, closest_vertices)
    % Generate interpolations between the mean mesh and synthetic meshes.
    % mean_mesh: Structure with fields 'verts' and 'faces' representing the mean mesh.
    % synthetic_meshes: Cell array of structures representing the synthetic meshes.
    % steps: Number of intermediate steps to generate.
    % closest_vertices: Cell array of closest landmark vertex indices for each region.

    % Number of synthetic meshes
    num_meshes = length(synthetic_meshes);

    % Prepare the video writers for different angles
    v_frontal = VideoWriter('interpolated_animation_frontal.avi');
    v_right = VideoWriter('interpolated_animation_right.avi');
    v_left = VideoWriter('interpolated_animation_left.avi');

    v_frontal.FrameRate = 10; % Set the frame rate
    v_right.FrameRate = 10;
    v_left.FrameRate = 10;

    open(v_frontal);
    open(v_right);
    open(v_left);

    % Camera rotation angles
    azimuth_angles = linspace(0, 0, steps+1);
    elevation_angle = 30; % Fixed elevation

    for i = 1:num_meshes
        for s = 0:steps
            % Linear interpolation
            alpha = s / steps;
            interpolated_verts = (1 - alpha) * mean_mesh.verts + alpha * synthetic_meshes{i}.verts;

            % Create the interpolated mesh structure
            interpolated_mesh.verts = interpolated_verts;
            interpolated_mesh.faces = mean_mesh.faces;

            % Plot the interpolated mesh for frontal view
            figure;
            mesh_plot(interpolated_mesh);
            material([0.3 0.7 0]);
            colormap([0.9 0.9 0.9]);
            hold on;
            for k = 1:length(closest_vertices)
                plot3(interpolated_mesh.verts(1, closest_vertices{k}), interpolated_mesh.verts(2, closest_vertices{k}), interpolated_mesh.verts(3, closest_vertices{k}), '*b');
            end
            view(0, elevation_angle); % Frontal view
            frame = getframe(gcf);
            writeVideo(v_frontal, frame);
            close(gcf);

            % Plot the interpolated mesh for right side view
            figure;
            mesh_plot(interpolated_mesh);
            material([0.3 0.7 0]);
            colormap([0.9 0.9 0.9]);
            hold on;
            for k = 1:length(closest_vertices)
                plot3(interpolated_mesh.verts(1, closest_vertices{k}), interpolated_mesh.verts(2, closest_vertices{k}), interpolated_mesh.verts(3, closest_vertices{k}), '*b');
            end
            view(90, elevation_angle); % Right side view
            frame = getframe(gcf);
            writeVideo(v_right, frame);
            close(gcf);

            % Plot the interpolated mesh for left side view
            figure;
            mesh_plot(interpolated_mesh);
            material([0.3 0.7 0]);
            colormap([0.9 0.9 0.9]);
            hold on;
            for k = 1:length(closest_vertices)
                plot3(interpolated_mesh.verts(1, closest_vertices{k}), interpolated_mesh.verts(2, closest_vertices{k}), interpolated_mesh.verts(3, closest_vertices{k}), '*b');
            end
            view(-90, elevation_angle); % Left side view
            frame = getframe(gcf);
            writeVideo(v_left, frame);
            close(gcf);

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
