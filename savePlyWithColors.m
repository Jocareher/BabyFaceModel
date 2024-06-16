function savePlyWithColors(vertices, faces, colors, filename)
    % savePlyWithColors Save a PLY file with colored vertices.
    %
    %   Inputs:
    %       vertices (matrix): Vertex coordinates.
    %       faces (matrix): Face indices.
    %       colors (matrix): Vertex colors.
    %       filename (string): Output PLY filename.

    % Open the file for writing
    fileID = fopen(filename, 'w');

    % Write the PLY header
    fprintf(fileID, 'ply\n');
    fprintf(fileID, 'format ascii 1.0\n');
    fprintf(fileID, 'element vertex %d\n', size(vertices, 1));
    fprintf(fileID, 'property float x\n');
    fprintf(fileID, 'property float y\n');
    fprintf(fileID, 'property float z\n');
    fprintf(fileID, 'property uchar red\n');
    fprintf(fileID, 'property uchar green\n');
    fprintf(fileID, 'property uchar blue\n');
    fprintf(fileID, 'element face %d\n', size(faces, 1));
    fprintf(fileID, 'property list uchar int vertex_indices\n');
    fprintf(fileID, 'end_header\n');

    % Write the vertex data with colors
    for i = 1:size(vertices, 1)
        fprintf(fileID, '%f %f %f %d %d %d\n', vertices(i, :), colors(i, :));
    end

    % Write the face data
    for i = 1:size(faces, 1)
        fprintf(fileID, '3 %d %d %d\n', faces(i, :) - 1); % PLY uses zero-based indexing
    end

    % Close the file
    fclose(fileID);
end