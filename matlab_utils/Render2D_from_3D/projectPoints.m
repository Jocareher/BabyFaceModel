function [projected, valid] = projectPoints(points, K, T, D, imageSize, sortPoints)
% PROJECTPOINTS Projects 3D points onto a plane using a camera model.
% 
% This function applies a standard pinhole camera model with optional
% distortion parameters to project 3D points onto a 2D image plane.
%
% INPUTS:
% - points: nxm matrix of 3D points, where the first 3 columns are the point (x, y, z) locations,
%           and the remaining columns are intensity values (i1, i2, etc.).
% - K: 3x3 or 3x4 camera matrix.
% - T: 4x4 transformation matrix to apply to points before projecting them (default is identity matrix).
% - D: 1xq distortion vector matching OpenCV's implementation [k1, k2, p1, p2, k3], where q can be 1 to 5.
%      Any values not given are set to 0 (default is [0, 0, 0, 0, 0]).
% - imageSize: 1x2 vector that gives the size of the image (y, x) the points will be projected onto.
%              Points outside this size or negative will be treated as invalid (default is []).
% - sortPoints: Binary value (true/false). If true, points are sorted by their distance from the camera
%               (useful for rendering points). Default is false.
%
% OUTPUTS:
% - projected: nx(m-1) matrix of 2D points, where the first 2 columns give the points (x, y) location,
%              and the remaining columns are intensity values (i1, i2, etc.). Points behind the camera
%              are assigned NaN as their position.
% - valid: nx1 binary vector, true if a 2D point is in front of the camera and projects onto a plane
%          of size imageSize.
%
% REFERENCES:
% The equations used in this implementation were taken from:
% http://docs.opencv.org/doc/tutorials/calib3d/camera_calibration/camera_calibration.html
% http://www.vision.caltech.edu/bouguetj/calib_doc/htmls/parameters.html
%
% This code is a more user-friendly version of the code used in generating results for the
% conference paper "Motion-Based Calibration of Multimodal Sensor Arrays"
% http://www.zjtaylor.com/welcome/download_pdf?pdf=ICRA2015.pdf and other publications.
%
% Author: Zachary Taylor
% Email: zacharyjeremytaylor@gmail.com
% Website: http://www.zjtaylor.com


% Validate and preprocess inputs
validateattributes(points, {'numeric'}, {'2d'}); % Ensure points is a 2D numeric array
if size(points, 2) < 3
    error('points must have at least 3 columns, currently has %i', size(points, 2));
end
points = double(points); % Convert points to double precision

% Ensure K is a 3x4 matrix
if size(K, 2) == 3
    K(end, 4) = 0;
end
validateattributes(K, {'numeric'}, {'size', [3, 4]}); % Validate camera matrix K
K = double(K); % Convert K to double precision

% Handle optional inputs and set defaults
if nargin < 3
    T = [];
end
if isempty(T)
    T = eye(4); % Default transformation matrix is the identity matrix
else
    validateattributes(T, {'numeric'}, {'size', [4, 4]}); % Validate transformation matrix T
end
T = double(T); % Convert T to double precision

if nargin < 4
    D = [];
end
if isempty(D)
    D = [0, 0, 0, 0, 0]; % Default distortion vector
else
    validateattributes(D, {'numeric'}, {'nrows', 1}); % Validate distortion vector D
end
if size(D, 2) > 5
    error('distortion vector D must have 5 or fewer columns, currently has %i', size(D, 2));
end
D = double(D); % Convert D to double precision

if nargin < 5
    imageSize = [];
end
if ~isempty(imageSize)
    validateattributes(imageSize, {'numeric'}, {'size', [1, 2], 'positive'}); % Validate imageSize
end

if nargin < 6
    sortPoints = [];
end
if isempty(sortPoints)
    sortPoints = false; % Default is not to sort points
else
    validateattributes(sortPoints, {'logical'}, {'scalar'}); % Validate sortPoints
end

%% Project points

% Split distortion into radial and tangential components
if size(D, 2) < 5
    D(1, 5) = 0; % Ensure D has 5 elements
end
k = [D(1), D(2), D(5)]; % Radial distortion coefficients
p = [D(3), D(4)]; % Tangential distortion coefficients

% Split points into locations and color
if size(points, 2) > 3
    colour = points(:, 4:end); % Extract color information
    points = points(:, 1:3); % Extract 3D point locations
else
    colour = zeros(size(points, 1), 0); % No color information
end

% Transform points
points = (T * [points, ones(size(points, 1), 1)]')';

% Sort points by distance from camera if requested
if sortPoints
    dist = sum(points(:, 1:3).^2, 2); % Calculate distance
    [~, idx] = sort(dist, 'descend'); % Sort distances in descending order
    points = points(idx, :); % Reorder points
    colour = colour(idx, :); % Reorder color
end

% Reject points behind camera
valid = points(:, 3) > 0; % Valid if z-coordinate is positive
points = points(valid, :); % Keep valid points
colour = colour(valid, :); % Keep corresponding colors

% Project onto a plane using normalized image coordinates
x = points(:, 1) ./ points(:, 3);
y = points(:, 2) ./ points(:, 3);

% Compute radial distance
r2 = x.^2 + y.^2;

% Compute tangential distortion
xTD = 2 * p(1) * x .* y + p(2) * (r2 + 2 * x.^2);
yTD = p(1) * (r2 + 2 * y.^2) + 2 * p(2) * x .* y;

% Compute radial distortion
xRD = x .* (1 + k(1) * r2 + k(2) * r2.^2 + k(3) * r2.^3);
yRD = y .* (1 + k(1) * r2 + k(2) * r2.^2 + k(3) * r2.^3);

% Combine distorted points
x = xRD + xTD;
y = yRD + yTD;

% Project distorted points back into 3D
points = [x, y, ones(size(x, 1), 1)] .* repmat(points(:, 3), 1, 3);

% Project using camera matrix
points = (K * [points, ones(size(points, 1), 1)]')';
points = points(:, 1:2) ./ repmat(points(:, 3), 1, 2);

% Output NaNs for points behind camera
projected = nan(size(valid, 1), 2 + size(colour, 2));
projected(valid, :) = [points, colour];

% Set points outside of the image region as invalid
if ~isempty(imageSize)
    inside = points(:, 1) < imageSize(2);
    inside = and(inside, points(:, 2) < imageSize(1));
    inside = and(inside, points(:, 1) >= 0);
    inside = and(inside, points(:, 2) >= 0);
    valid(valid) = inside;
end
