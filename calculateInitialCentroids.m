function initial_centroids = calculateInitialCentroids(folder_path, num_clusters)
    % calculateInitialCentroids Calculates initial centroids from clusters of vertices.
    %   This function reads CSV files from the specified folder, which contain clusters of vertices.
    %   It calculates the centroid of each cluster and returns these centroids.
    %
    % Inputs:
    %   folder_path (string): Path to the folder containing the CSV files.
    %   num_clusters (int): Number of clusters.
    %
    % Outputs:
    %   initial_centroids (matrix): Initial centroids for k-means clustering.

    % Get the list of CSV files in the specified folder
    files = dir(fullfile(folder_path, '*.csv')); % Get the list of CSV files in the specified folder
    num_files = length(files); % Count the number of CSV files

    % Initialize array to store initial centroids
    initial_centroids = zeros(num_clusters, 3);
    current_cluster = 1;

    % Read each file and calculate centroids
    for i = 1:num_files
        file_name = files(i).name;
        file_path = fullfile(folder_path, file_name);

        % Read the CSV file
        fileID = fopen(file_path, 'r');
        % Skip the header
        data = textscan(fileID, '%f %f %f %f', 'Delimiter', ',', 'HeaderLines', 1);
        fclose(fileID);

        % Extract vertices
        vertices = cell2mat(data(2:4));

        % Calculate the centroid of the cluster
        centroid = mean(vertices, 1);

        % Store the centroid
        initial_centroids(current_cluster, :) = centroid;
        current_cluster = current_cluster + 1;
        
        % Stop if we have the required number of clusters
        if current_cluster > num_clusters
            break;
        end
    end

    % Ensure we have the exact number of clusters
    initial_centroids = initial_centroids(1:num_clusters, :);
end
