function [theta, phi] = sphericalMapping(vertices)
    % Convert Cartesian coordinates to spherical coordinates
    [phi, theta, ~] = cart2sph(vertices(:, 1), vertices(:, 2), vertices(:, 3));
end