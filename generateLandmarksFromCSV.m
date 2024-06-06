function generateLandmarksFromCSV(folder_path, k)
% GENERATELANDMARKSFROMCSV Generates landmarks from CSV files.
%   generateLandmarksFromCSV(FOLDER_PATH, K) reads all CSV files in the
%   specified folder, applies k-means clustering to find K regions, calculates the
%   five nearest vertices to each region's centroid, and saves the result as a MAT file.
%
%   Each CSV file should have the following format:
%   - The first row contains headers: "vtkOriginalPointIds", "Points:0", "Points:1", "Points:2".
%   - Each subsequent row contains the vertex index and its x, y, z coordinates.
%
%   Inputs:
%   - folder_path: Path to the folder containing the CSV files.
%   - k: Number of clusters (regions) to find using k-means clustering.
%
%   Outputs:
%   - Saves a MAT file 'averaged_landmarks.mat' containing the closest vertices for each cluster.

    % Get the list of CSV files in the specified folder
    files = dir(fullfile(folder_path, '*.csv'));
    num_files = length(files);
        
    % Initialize counters
    total_vertices = 0;
    
    % First pass to count the total number of vertices
    for i = 1:num_files
        file_name = files(i).name;
        file_path = fullfile(folder_path, file_name);
        
        % Count the number of lines (vertices) in the file
        fid = fopen(file_path, 'rt');
        num_lines = 0;
        while fgets(fid) ~= -1
            num_lines = num_lines + 1;
        end
        fclose(fid);
        
        % Subtract the header line
        num_lines = num_lines - 1;
        
        % Update total_vertices
        total_vertices = total_vertices + num_lines;
    end
    
    % Preallocate arrays
    all_vertices = zeros(total_vertices, 3);
    all_indices = zeros(total_vertices, 1);
    
    % Second pass to read the data
    current_idx = 1;
    for i = 1:num_files
        file_name = files(i).name;
        file_path = fullfile(folder_path, file_name);
        
        % Read the CSV file
        fileID = fopen(file_path, 'r');
        data = textscan(fileID, '%s', 'Delimiter', '\n', 'HeaderLines', 1);
        fclose(fileID);
        
        % Parse the data
        data = data{1};
        num_data = length(data);
        for j = 1:num_data
            line = strsplit(data{j}, ',');
            index = str2double(line{1});
            x_coord = str2double(line{2});
            y_coord = str2double(line{3});
            z_coord = str2double(line{4});
            
            % Append vertices and indices to the arrays
            all_vertices(current_idx, :) = [x_coord, y_coord, z_coord];
            all_indices(current_idx) = index;
            current_idx = current_idx + 1;
        end
    end
    
    % Apply k-means clustering to find k regions
    [idx, centroids] = kmeans(all_vertices, k);
    
    % Initialize the cell array to store the closest vertices for each cluster
    closest_vertices = cell(1, k);
    
    % Calculate the closest vertices for each cluster
    for region = 1:k
        cluster_points = all_vertices(idx == region, :);
        cluster_indices = all_indices(idx == region);
        
        % Calculate the distances from each point to the centroid
        distances = sqrt(sum((cluster_points - centroids(region, :)).^2, 2));
        
        % Find the indices of the five closest vertices
        [~, sorted_indices] = sort(distances);
        closest_vertices{region} = cluster_indices(sorted_indices(1:5));
    end
    
    % Save the results in a MAT file
    save('averaged_landmarks.mat', 'closest_vertices');
end