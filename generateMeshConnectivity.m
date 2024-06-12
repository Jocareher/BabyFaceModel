function generateMeshConnectivity(trilist, num_vertices)
% GENERATEMESHCONNECTIVITY Generates vertex connectivity from mesh triangulation.
%   generateMeshConnectivity(TRILIST, NUM_VERTICES) generates a connectivity
%   matrix from the mesh triangulation list and saves it as 'connectivity.mat'.
%
%   Inputs:
%   - trilist: Nx3 matrix where each row contains indices of vertices forming a triangle.
%   - num_vertices: Total number of vertices in the mesh.
%
%   Outputs:
%   - Saves a MAT file 'connectivity.mat' containing the connectivity cell array.

    connectivity = cell(num_vertices, 1);
    
    % Loop through each face in the triangulation list
    for i = 1:size(trilist, 1)
        vertices = trilist(i, :);
        for j = 1:3
            for k = 1:3
                if j ~= k
                    connectivity{vertices(j)} = [connectivity{vertices(j)}, vertices(k)];
                end
            end
        end
    end
    
    % Remove duplicate entries in connectivity
    for i = 1:num_vertices
        connectivity{i} = unique(connectivity{i});
    end
    
    % Save the connectivity matrix
    save('connectivity.mat', 'connectivity');
end
