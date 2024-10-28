% Read ply 

inDir= ''; % add input directory
fileName='4_26s_20.ply';
mesh= ply_readMesh([inDir,fileName]); % loaded as an struct:
                                            % mesh.verts ( 3 x numver vertices ) 
                                            % mesh.faces ( 3 x number of faces )

% Visualize the 3D mesh
figure; mesh_plot(mesh)

%% Example Cropping & Remove non conected components
mesh2= ply_readMesh('4_26s_20_var_90_landmarks_trasnform.ply'); 

  % Crop images range
all_neig = rangesearch( mesh.verts', mesh2.verts(:,1:15:end)', 10); % aligned aproximation search 
all_verts = sort(unique(horzcat(all_neig{:})));
color=zeros(1, length( mesh_i.verts));
color(all_verts)= 1;

% Visualize vertex we want to keep 
figure; mesh_plot(mesh,color);
   
verts_to_keep= double(color); % vertex we want to keep
v_to_clean= find(~verts_to_keep ==1); % vertex we want to remove           

% Find 
outMesh2= mesh_RemoveVerts_fast( mesh_i, v_to_clean); % new mesh cropped

% Remove non connected components
[~, myMesh_fix2, ~] = mesh_findConnectedComponents_fast( outMesh2, 'clean', 'silent' );

        
