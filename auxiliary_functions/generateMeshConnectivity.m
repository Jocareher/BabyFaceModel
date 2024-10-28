function generateMeshConnectivity(trilist, num_vertices)
% generateMeshConnectivity Generates vertex connectivity from mesh triangulation.
%   generateMeshConnectivity(trilist, num_vertices) generates a connectivity
%   matrix from the mesh triangulation list and saves it as 'connectivity.mat'.
%
%   This function takes a list of triangles (each defined by three vertex indices)
%   and the total number of vertices in the mesh. It constructs a connectivity matrix
%   where each entry lists the neighboring vertices connected to a given vertex by an edge.
%   The result is saved to a MAT file for later use.
%
%   Inputs:
%   - trilist: Nx3 matrix where each row contains indices of vertices forming a triangle.
%   - num_vertices: Total number of vertices in the mesh.
%
%   Outputs:
%   - Saves a MAT file 'connectivity.mat' containing the connectivity cell array.

    % Initialize a cell array to store the connectivity information for each vertex.
    connectivity = cell(num_vertices, 1);
    
    % Loop through each face in the triangulation list
    for i = 1:size(trilist, 1)
        % Get the vertex indices for the current face (triangle)
        vertices = trilist(i, :);
        fprintf('Processing face %d: vertices %d, %d, %d\n', i, vertices(1), vertices(2), vertices(3));
        % Loop through each vertex in the current face
        for j = 1:3
            % Loop through the other vertices in the current face
            % To verify connectivity with other vertex triangles
            for k = 1:3
                % If the vertices are not the same (to avoid self-connectivity)
                if j ~= k
                    % Add the vertex k to the connectivity list of vertex j
                    connectivity{vertices(j)} = [connectivity{vertices(j)}, vertices(k)];
                end
            end
        end
    end
    
    % Remove duplicate entries in connectivity
    for i = 1:num_vertices
        % Use the unique function to remove duplicates from each vertex's connectivity list
        connectivity{i} = unique(connectivity{i});
    end
    
    % Display connectivity for debugging
    disp(connectivity);
    
    % Save the connectivity matrix to a MAT file
    save('connectivity.mat', 'connectivity');
end
