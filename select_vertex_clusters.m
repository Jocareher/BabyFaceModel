function select_vertex_clusters(folder_path, k)
    % Select clusters of vertices instead of a single average vertex.
    % folder_path: Path to the folder containing CSV files with vertex data.
    % k: Number of clusters to form.

    % Get the list of CSV files in the specified folder
    files = dir(fullfile(folder_path, '*.csv'));
    num_files = length(files);
    
    % Initialize arrays to store the vertices and indices across all files
    all_vertices = [];
    all_indices = [];
    
    for i = 1:num_files
        file_name = files(i).name;
        file_path = fullfile(folder_path, file_name);
        
        % Read the CSV file as text
        data = readmatrix(file_path, 'NumHeaderLines', 1);
        
        % Parse the data
        for j = 1:size(data, 1)
            line = strsplit(data{j}, ',');
            index = str2double(line{1});
            x_coord = str2double(line{2});
            y_coord = str2double(line{3});
            z_coord = str2double(line{4});
            
            % Append vertices and indices to the arrays
            all_vertices = [all_vertices; x_coord, y_coord, z_coord];
            all_indices = [all_indices; index];
        end
    end
    
    % Apply k-means clustering to find k regions
    [idx, ~] = kmeans(all_vertices, k);
    
    % Initialize the array to store the vertex clusters
    vertex_clusters = cell(1, k);
    
    % Store the indices of the vertices in each cluster
    for region = 1:k
        cluster_indices = all_indices(idx == region);
        vertex_clusters{region} = cluster_indices;
    end
    
    % Save the vertex clusters in a MAT file
    save('vertex_clusters.mat', 'vertex_clusters');
end
