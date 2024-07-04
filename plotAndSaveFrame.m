function plotAndSaveFrame(mesh, closest_vertices, original_landmarks, azimuth_angle, elevation_angle, video_writer)
    % plotAndSaveFrame Plots the interpolated mesh, plots landmarks, and saves the frame to a video.
    %   plotAndSaveFrame(interpolated_mesh, closest_vertices, azimuth_angle, elevation_angle, video_writer)
    %   plots the interpolated mesh, plots landmarks, sets the camera view, captures the frame, and writes it to the video.
    %
    %   Inputs:
    %   - interpolated_mesh: Interpolated mesh structure with fields 'verts' and 'faces'.
    %   - closest_vertices: Cell array of closest landmark vertex indices for each region.
    %   - original_landmarks: Array of original landmark vertex indices.
    %   - azimuth_angle: Azimuth angle for the view.
    %   - elevation_angle: Elevation angle for the view.
    %   - video_writer: VideoWriter object to save the frame.
    
    figure; % Create a new figure
    % Plot the interpolated mesh
    mesh_plot(interpolated_mesh); 
    material([0.3 0.7 0]); % Set material properties
    colormap([0.9 0.9 0.9]); % Set colormap
    hold on; % Hold on to add landmarks

    % Plot the closest landmarks on the interpolated mesh
    for k = 1:length(closest_vertices)
        plot3(interpolated_mesh.verts(1, closest_vertices{k}), interpolated_mesh.verts(2, closest_vertices{k}), interpolated_mesh.verts(3, closest_vertices{k}), '*b');
    end

    % Plot the original landmarks on the mesh
    for k = 1:length(original_landmarks)
        idx = original_landmarks(k);
        plot3(mesh.verts(1, idx), mesh.verts(2, idx), mesh.verts(3, idx), '*r');
    end

    % Set the camera view
    view(azimuth_angle, elevation_angle);

    % Capture the frame for the animation
    frame = getframe(gcf);
    writeVideo(video_writer, frame); % Write the frame to the video
    close(gcf); % Close the figure
end
