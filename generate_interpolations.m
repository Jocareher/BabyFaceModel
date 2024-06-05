function generate_interpolations(mean_mesh, synthetic_meshes, steps)
    % Generate interpolations between the mean mesh and synthetic meshes.
    % mean_mesh: Structure with fields 'verts' and 'faces' representing the mean mesh.
    % synthetic_meshes: Cell array of structures representing the synthetic meshes.
    % steps: Number of intermediate steps to generate.
    % averaged_landmarks: Array of averaged landmark vertex indices.

    % Number of synthetic meshes
    num_meshes = length(synthetic_meshes);

    for i = 1:num_meshes
        % Get the vertices of the mean mesh and the current synthetic mesh
        mean_verts = mean_mesh.verts;
        synth_verts = synthetic_meshes{i}.verts;

        % Generate intermediate meshes
        for s = 0:steps
            % Linear interpolation
            alpha = s / steps;
            interpolated_verts = (1 - alpha) * mean_verts + alpha * synth_verts;

            % Create the interpolated mesh structure
            interpolated_mesh.verts = interpolated_verts;
            interpolated_mesh.faces = mean_mesh.faces;

            % Save the interpolated mesh to a PLY file
            filename = sprintf('interpolated_mesh_%d_step_%d.ply', i, s);
            interpolated_mesh_surface = surfaceMesh(interpolated_mesh.verts', interpolated_mesh.faces');
            writeSurfaceMesh(interpolated_mesh_surface, filename);
        end
    end
end