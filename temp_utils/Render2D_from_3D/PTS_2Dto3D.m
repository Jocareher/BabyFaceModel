addpath(genpath('E:\PhD\Matlab_codes'))
load('maps_2Dto3D.mat');

folder = 'ProjectedPicLandmarks\';
pts2D_files = dir([folder,'*.pts']);

for i = 1:length(pts2D_files)
    pts2D_file = pts2D_files(i).name;
    
    aux = strsplit(pts2D_file,'.'); aux = aux{1};
    aux = strsplit(aux,'_'); name = strjoin(aux(1:3),'_');
    position = aux(4:end);
    %rightside = positive angle, leftside = negative angle
    if strcmp(position{1}, 'frontal') == 1, angle = 0;
    elseif strcmp(position{1}, 'leftside') == 1, angle = -str2double(position{2});
    elseif strcmp(position{1}, 'rightside') == 1, angle = str2double(position{2});
    end
    
    
    ind = find(strcmp({maps_2Dto3D.file}, name)==1 & [maps_2Dto3D.angle] == angle);
    fprintf('file = %s, angle = %i, ind = %i\n',pts2D_file,angle,ind)
    map = maps_2Dto3D(ind).map;
    PTS_from2Dto3D(map, angle, [folder,pts2D_file])
    
end