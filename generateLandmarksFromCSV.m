function generateLandmarksFromCSV(folder_path, k, ring_size)
    % generateLandmarksFromCSV Generates landmarks from CSV files.
    %   generateLandmarksFromCSVByRings(folder_path, K, ring_size) reads all CSV files in the
    %   specified folder, applies k-means clustering to find K regions, calculates the
    %   nearest vertices to each region's centroid based on connectivity rings, and saves the result as a MAT file.
    %
    %   Each CSV file should have the following format:
    %   - The first row contains headers: "vtkOriginalPointIds", "Points:0", "Points:1", "Points:2".
    %   - Each subsequent row contains the vertex index and its x, y, z coordinates.
    %
    %   Inputs:
    %   - folder_path: Path to the folder containing the CSV files.
    %   - k: Number of clusters (regions) to find using k-means clustering.
    %   - ring_size: Number of rings to consider for selecting vertices.
    %
    %   Outputs:
    %   - Saves a MAT file 'averaged_landmarks_per_ring.mat' containing the closest vertices for each cluster.
    %
    %   The function follows these steps:
    %   1. Counts the total number of vertices from all CSV files.
    %   2. Reads and stores the vertices and their indices.
    %   3. Applies k-means clustering to group vertices into k regions.
    %   4. For each region, selects vertices in concentric rings around the centroid.
    %   5. Saves the selected vertices for each region in a MAT file.

    % Get the list of CSV files in the specified folder
    files = dir(fullfile(folder_path, '*.csv')); % Get the list of CSV files in the specified folder
    num_files = length(files); % Count the number of CSV files
    
    % Initialize counters
    total_vertices = 0;
    
    % First pass to count the total number of vertices
    for i = 1:num_files
        % Get the name of the file
        file_name = files(i).name;
        % Construct the full file path
        file_path = fullfile(folder_path, file_name); 
        
        % Count the number of lines (vertices) in the file
        % Open the file in text read mode
        fid = fopen(file_path, 'rt');
         % Initialize the line counter
        num_lines = 0;
        while fgets(fid) ~= -1
            num_lines = num_lines + 1; % Count each line in the file
        end
        fclose(fid); % Close the file
        
        % Subtract the header line
        num_lines = num_lines - 1;
        
        % Update total_vertices
        total_vertices = total_vertices + num_lines;
    end
    
    % Preallocate arrays (for vertex and indices)
    all_vertices = zeros(total_vertices, 3);
    all_indices = zeros(total_vertices, 1);
    
    % Second pass to read the data
    % Initialize the current index
    current_idx = 1; 
    for i = 1:num_files
        file_name = files(i).name; 
        file_path = fullfile(folder_path, file_name);
        
        % Read the CSV file
        fileID = fopen(file_path, 'r');
        % Read the CSV file, skipping the header
        data = textscan(fileID, '%s', 'Delimiter', '\n', 'HeaderLines', 1);
        fclose(fileID); 
        
        % Parse the data
         % Extract the data from the cell array
        data = data{1};
         % Count the number of data lines
        num_data = length(data);
        for j = 1:num_data
            line = strsplit(data{j}, ','); % Split the line into components
            index = str2double(line{1}); % Convert the index to a number
            % Convert the x, y, z coordinates to a number
            x_coord = str2double(line{2});
            y_coord = str2double(line{3});
            z_coord = str2double(line{4});
            
            % Append vertices and indices to the arrays
            % Store the vertex coordinates
            all_vertices(current_idx, :) = [x_coord, y_coord, z_coord];
            % Store the vertex index
            all_indices(current_idx) = index;
            current_idx = current_idx + 1;
        end
    end
    
    % Display the vertices and indices (for debugging)
    disp('All vertices:');
    disp(all_vertices); 
    disp('All indices:');
    disp(all_indices);
    
    % Apply k-means clustering to find k regions
    [~, centroids] = kmeans(all_vertices, k);
    
    % Display centroids for debugging
    disp('Centroids:');
    disp(centroids);
    
    % Initialize the cell array to store the closest vertices for each cluster
    closest_vertices = cell(1, k);
    
    % Load the triangulation data (previously computed)
    % Connectivity should be a cell array where each cell contains the indices of connected vertices
    load('connectivity.mat', 'connectivity'); 

    % Calculate the closest vertices for each cluster using ring-based selection
    for region = 1:k
        % Get the central vertex of the cluster
        central_vertex = centroids(region, :);
        
        % Find the closest vertex in all_vertices to the centroid
        distances = sqrt(sum((all_vertices - central_vertex).^2, 2)); % Calculate the distance of each vertex to the centroid
        [~, min_idx] = min(distances); % Find the index of the closest vertex
        ring_vertices = min_idx; % Initialize the ring vertices with the closest vertex
        
        % Display the ring vertices for debugging
        disp(['Ring vertices for region ', num2str(region), ':']);
        disp(ring_vertices);
        
        % Initialize all selected vertices with the ring vertices
        all_selected_vertices = ring_vertices; 
        
        for r = 1:ring_size
            % Initialize a list for the new ring vertices
            new_ring_vertices = []; 
            for v = ring_vertices'
                % Add the connected vertices to the ring
                new_ring_vertices = [new_ring_vertices; connectivity{v}(:)];
            end
            % Remove duplicate vertices
            new_ring_vertices = unique(new_ring_vertices);
            % Add the new ring vertices to the selected vertices
            all_selected_vertices = [all_selected_vertices; new_ring_vertices];
            % Update the ring vertices
            ring_vertices = new_ring_vertices;
        end
        % Remove duplicate vertices
        all_selected_vertices = unique(all_selected_vertices);
        
        % Select the vertices for this cluster
        closest_vertices{region} = all_selected_vertices(1:min(5, length(all_selected_vertices)));
        
        % Display the selected vertices for debugging
        disp(['Selected vertices for region ', num2str(region), ':']);
        disp(closest_vertices{region});
    end
    
    % Save the results in a MAT file
    save('averaged_landmarks_per_ring.mat', 'closest_vertices', 'centroids', 'all_vertices', 'all_indices'); % Save the results in a MAT file
end
