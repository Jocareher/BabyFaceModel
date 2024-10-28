function initial_centroids = calculateInitialCentroids(folder_path, num_landmarks)
    % Get the list of CSV files in the specified folder
    files = dir(fullfile(folder_path, '*.csv'));
    num_files = length(files);
    
    % Initialize a cell array to store the vertices for each landmark
    all_landmarks = cell(1, num_landmarks);
    for i = 1:num_landmarks
        all_landmarks{i} = [];
    end
    
    % Read the data from each CSV file
    for i = 1:num_files
        file_name = files(i).name;
        file_path = fullfile(folder_path, file_name);
        
        % Read the CSV file
        data = readtable(file_path);
        
        % Append the vertices to the corresponding landmark array
        for j = 1:num_landmarks
            landmark_data = data(data.vtkOriginalPointIds == j - 1, {'Points_0', 'Points_1', 'Points_2'});
            all_landmarks{j} = [all_landmarks{j}; table2array(landmark_data)];
        end
    end
    
    % Calculate the mean of each landmark group
    initial_centroids = zeros(num_landmarks, 3);
    for i = 1:num_landmarks
        initial_centroids(i, :) = mean(all_landmarks{i}, 1);
    end
end