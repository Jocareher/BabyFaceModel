function [new_face2, new_lmks2, transform] = apply_procrustes2lmks(lmks1, lmks2, face2)
    %%% Determine a linear transformation (translation, reflection, orthogonal rotation, and scaling)
    %%% of the points in lmks2 to best conform them to the points in lmks1.
    %%% Then transform face2 according to the procrustes transformation.
    %%% face2 = 3xN
    %%% lmks = kx3
    
    if iscell(lmks1), lmks1 = cell2mat(lmks1(:,2:4)); end
    if iscell(lmks2), lmks2 = cell2mat(lmks2(:,2:4)); end
    
    [~, ~, transform] = procrustes(lmks1,lmks2,'Reflection',false);

    new_lmks2 = transform.b*lmks2*transform.T + transform.c;
    
    t = repmat(transform.c(1,:),[size(face2,2),1]);
    R = transform.T;
    s = transform.b;
   
    new_face2 = (s*face2'*R + t)';
end

