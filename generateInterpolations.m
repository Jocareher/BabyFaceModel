function generateInterpolations(mean_mesh, synthetic_meshes, steps, closest_vertices)
% GENERATEINTERPOLATIONS Generates interpolations between the mean mesh and synthetic meshes.
%   generateInterpolations(mean_mesh, synthetic_meshes, steps, closest_vertices)
%   creates interpolated meshes between a given mean mesh and synthetic
%   meshes, saving the intermediate steps and generating videos from different angles.
%
%   Inputs:
%       mean_mesh (struct): Structure with fields 'verts' and 'faces' representing the mean mesh.
%       synthetic_meshes (cell array): Cell array of structures representing the synthetic meshes.
%       steps (int): Number of intermediate steps to generate for the interpolation.
%       closest_vertices (cell array): Cell array of closest landmark vertex indices for each region.
%
%   Outputs:
%       Saves interpolated meshes as PLY files and generates AVI videos from different angles.

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
        % Loop through each interpolation step
        for s = 0:steps
            % Linear interpolation coefficient
            alpha = s / steps;
            % Perform linear interpolation of vertices
            interpolated_verts = (1 - alpha) * mean_mesh.verts + alpha * synthetic_meshes{i}.verts;

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
%
%   Inputs:
%       interpolated_mesh (struct): Interpolated mesh structure with fields 'verts' and 'faces'.
%       closest_vertices (cell array): Cell array of closest landmark vertex indices for each region.
%       azimuth_angle (double): Azimuth angle for the view.
%       elevation_angle (double): Elevation angle for the view.
%       video_writer (VideoWriter): VideoWriter object to save the frame.
%
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