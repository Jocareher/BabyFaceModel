function generate_landmarks_from_csv(folder_path)
% GENERATE_LANDMARKS_FROM_CSV Generates averaged landmarks from CSV files.
%   generate_landmarks_from_csv(FOLDER_PATH) reads all CSV files in the
%   specified folder, applies clustering to find regions, calculates the
%   average coordinates for each region, and saves the result as a MAT file.
%
%   Each CSV file should have the following format:
%   - The first row contains headers: "vtkOriginalPointIds", "Points:0", "Points:1", "Points:2".
%   - Each subsequent row contains the vertex index and its x, y, z coordinates.

    % Get the list of CSV files in the specified folder
    files = dir(fullfile(folder_path, '*.csv'));
    num_files = length(files);
    
    % Initialize a cell array to store the vertices of each region across all files
    all_vertices = [];
    all_indices = [];
    
    for i = 1:num_files
        file_name = files(i).name;
        file_path = fullfile(folder_path, file_name);
        
        % Read the CSV file
        fileID = fopen(file_path, 'r');
        data = textscan(fileID, '%s', 'Delimiter', '\n', 'HeaderLines', 1);
        fclose(fileID);
        
        % Parse the data
        data = data{1};
        for j = 1:length(data)
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
    
    % Apply k-means clustering to find 6 regions
    k = 8;
    [idx, ~] = kmeans(all_vertices, k);
    
    % Initialize the array to store the averaged landmarks
    averaged_landmarks = zeros(1, 6);
    
    % Calculate the average coordinates for each cluster
    for region = 1:k
        cluster_points = all_vertices(idx == region, :);
        cluster_indices = all_indices(idx == region);
        
        % Calculate the mean coordinates
        mean_coords = mean(cluster_points, 1);
        
        % Find the closest vertex to the mean coordinates
        distances = sqrt(sum((cluster_points - mean_coords).^2, 2));
        [~, min_idx] = min(distances);
        
        % The closest vertex index is the average landmark
        averaged_landmarks(region) = cluster_indices(min_idx);
    end
    
    % Save the results in a MAT file
    save('averaged_landmarks.mat', 'averaged_landmarks');
end
