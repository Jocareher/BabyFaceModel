
clear all

inDir= '/Users/Antonia/Desktop/Nuevos Datos US/';
outDir= '/Users/Antonia/Desktop/TFG/Bebes/Datos_US_new/';
all_subjects=dir([inDir,'FLA*']);


% LOAD BABY MODEL

load('BabyFM_P21.mat')


% scaling
scale = 1.2;

for j = 1
    
% all_meshes= dir([all_subjects(j).folder,'/',all_subjects(j).name,'/*.ply'])
all_lmks = dir([all_subjects(j).folder,'/',all_subjects(j).name,'/*.fcsv']);

mkdir([ outDir all_subjects(j).name ]);

for i= 1:length(all_lmks)
       %% SCALING AND SAVING THE NEW SCALED MESH
   
   mesh = ply_readMesh([all_lmks(i).folder,'/',all_lmks(i).name(1:end-5),'.ply']);
   mesh.verts = scale.*mesh.verts; % Scaling mesh as it is 20 % smaller than in the real space
   
   

   ply_writeMesh(mesh,[outDir,all_subjects(j).name,'/',all_lmks(i).name(1:end-5),'.ply']);
    
    
    %% LADMARKS DEFINITION
    
    % 1) CHANGE DEFAULD EXTENSION OF THE FISUCIALS (3D SLICER)
    
    % change extencion of .fcsv to csv in order to be able to read it
    file = fullfile(all_lmks(i).folder, all_lmks(i).name);
    [tempDir, tempFile] = fileparts(file); 
    status = copyfile(file, fullfile(tempDir, [tempFile, '.csv']));
    
    % 2) DELETE .fcsv file
    
   % delete(file) ;
    
    % 3) READ .CSV
    
    T = readtable([all_lmks(i).folder,'/',all_lmks(i).name(1:end-5),'.csv']);
    
    % 4) LMKS IDENTIFICATION
    
    lmks=NaN(3,length(FaceModel.landmark_names));
    
    for k = 1:length(FaceModel.landmark_names)
        idx = strcmp(T.label, FaceModel.landmark_names{1,k});
        if sum(idx)==1
            lmks(1,k)= T.x(idx);
            lmks(2,k)= T.y(idx);
            lmks(3,k)= T.z(idx);
        end
    end
    
%     % Plot
%     figure; mesh_plot(mesh); hold on;
%     plot3(scale.*lmks(1,:), scale.*lmks(2,:), scale.*lmks(3,:),'*r');
%     label = FaceModel.landmark_names;
%     text(scale.*lmks(1,:),scale.*lmks(2,:),scale.*lmks(3,:),label,'VerticalAlignment','bottom','HorizontalAlignment','right')

    % 5) LMKS SCALING AND SAVE AS .PTS
    
   Write_PTS_Landmarks( [outDir,all_subjects(j).name,'/',all_lmks(i).name(1:end-5),'.pts'], scale.*lmks );
   
end
    
    
end

