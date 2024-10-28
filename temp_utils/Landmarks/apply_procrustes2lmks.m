function [new_face2, new_lmks2, transform] = apply_procrustes2lmks(lmks1, lmks2, face2)
% apply_procrustes2lmks Applies a Procrustes transformation to align two sets of landmarks.
%
% This function determines a linear transformation (translation, reflection,
% orthogonal rotation, and scaling) to best align the points in lmks2 to the points
% in lmks1. It then applies this transformation to the landmarks and the 3D face mesh.
%
% INPUT:
% - lmks1: Matrix of size kx3 containing the reference landmark coordinates.
% - lmks2: Matrix of size kx3 containing the target landmark coordinates.
% - face2: Matrix of size 3xN containing the vertices of the 3D face mesh to be transformed.
%
% OUTPUT:
% - new_face2: Transformed vertices of the 3D face mesh.
% - new_lmks2: Transformed landmark coordinates.
% - transform: Structure containing the transformation parameters (scaling, rotation, translation).


    
% Check if the landmarks are cell arrays and convert to matrices if necessary
    if iscell(lmks1), lmks1 = cell2mat(lmks1(:,2:4)); end
    if iscell(lmks2), lmks2 = cell2mat(lmks2(:,2:4)); end
    
    % Perform Procrustes analysis to determine the transformation
    [~, ~, transform] = procrustes(lmks1, lmks2, 'Reflection', false);

    % Apply the Procrustes transformation to the target landmarks
    new_lmks2 = transform.b * lmks2 * transform.T + transform.c;
    
    % Prepare the transformation components for the face mesh
    t = repmat(transform.c(1, :), [size(face2, 2), 1]);
    R = transform.T;
    s = transform.b;
   
    % Apply the transformation to the face mesh vertices
    new_face2 = (s * face2' * R + t)';
end

