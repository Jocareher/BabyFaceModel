function generate_interpolations(mean_mesh, synthetic_meshes, steps, closest_vertices)
    % Generate interpolations between the mean mesh and synthetic meshes.
    % mean_mesh: Structure with fields 'verts' and 'faces' representing the mean mesh.
    % synthetic_meshes: Cell array of structures representing the synthetic meshes.
    % steps: Number of intermediate steps to generate.
    % closest_vertices: Cell array of closest landmark vertex indices for each region.

    % Number of synthetic meshes
    num_meshes = length(synthetic_meshes);

    % Prepare the video writer
    v = VideoWriter('interpolated_animation.avi');
    v.FrameRate = 10; % Set the frame rate
    open(v);

    % Camera rotation angles
    azimuth_angles = linspace(0, 360, steps+1); % Full rotation
    elevation_angle = 30; % Fixed elevation

    for i = 1:num_meshes
        for s = 0:steps
            % Linear interpolation
            alpha = s / steps;
            interpolated_verts = (1 - alpha) * mean_mesh.verts + alpha * synthetic_meshes{i}.verts;

            % Create the interpolated mesh structure
            interpolated_mesh.verts = interpolated_verts;
            interpolated_mesh.faces = mean_mesh.faces;

            % Plot the interpolated mesh
            figure;
            mesh_plot(interpolated_mesh);
            material([0.3 0.7 0]);
            colormap([0.9 0.9 0.9]);
            hold on;
            for k = 1:length(closest_vertices)
                plot3(interpolated_mesh.verts(1, closest_vertices{k}), interpolated_mesh.verts(2, closest_vertices{k}), interpolated_mesh.verts(3, closest_vertices{k}), '*b');
            end

            % Set the camera view
            azimuth_angle = azimuth_angles(s+1);
            view(azimuth_angle, elevation_angle);

            % Capture the frame for the animation
            frame = getframe(gcf);
            writeVideo(v, frame);
            close(gcf);

            % Save the interpolated mesh to a PLY file
            filename = sprintf('interpolated_mesh_%d_step_%d.ply', i, s);
            interpolated_mesh_surface = surfaceMesh(interpolated_mesh.verts', interpolated_mesh.faces');
            writeSurfaceMesh(interpolated_mesh_surface, filename);

            % Add a pause to make the animation slower
            pause(0.2); % Pause for 0.2 seconds
        end
    end

    % Close the video writer
    close(v);
end