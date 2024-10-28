function map_2Dto3D = render_images_FLR(read_files, x3d_filepath, stereo_img_filepath, rotAnglesXYZ, varargin)
% INPUT
% x3d_filepath: path and file name of the x3D file
% stereo_img_filepath: path and file name of the stereo image
% rotAngleXYZ: angles in x, y and z that positions the scan into frontal position
%


if ~read_files
    myMesh = x3d_filepath;
    myTexture = stereo_img_filepath;
    clearvars x3d_filepath stereo_img_filepath
end
    


scale_for_imgSize = 13e-5;
lmksF = [];
lmksR = [];
lmksL = [];
outDir = '';
outFile = '';
verbose = false;
render = 'FRL';

while ~isempty(varargin)
    if strcmpi(varargin{1},'LandmarksF')
        lmksF = varargin{2};
        varargin(1:2) = [];
        continue;
    end
    if strcmpi(varargin{1},'LandmarksR')
        lmksR = varargin{2};
        varargin(1:2) = [];
        continue;
    end
    if strcmpi(varargin{1},'LandmarksL')
        lmksL = varargin{2};
        varargin(1:2) = [];
        continue;
    end
    if strcmpi(varargin{1},'scale_for_imgSize')
        scale_for_imgSize = varargin{2};
        varargin(1:2) = [];
        continue;
    end
    if strcmp(varargin{1},'save_output')
        outDir = varargin{2};
        outFile = varargin{3};
        varargin(1:3) = [];
		if outDir(end) ~= '/', outDir = [outDir,'/'];
		end
        continue;
    end
    if strcmp(varargin{1},'render')
        render = varargin{2};
        varargin(1:2) = [];
        continue;
    end
    if strcmp(varargin{1},'verbose')
        verbose = true;
        varargin(1) = [];
        continue;
    end
    error('Unexpected input argument.')
end




%     addpath(genpath('E:\PhD\Matlab_codes'))

    outFile = strsplit(outFile,'.');
    outFile = outFile{1};

    if read_files
        if verbose, fprintf('Reading X3D file\n'), end
        [coord, faces_coord, faces_tex, tex_coord_img, texture] = read_x3d(x3d_filepath, stereo_img_filepath);
        myMesh.verts = coord; myMesh.faces = faces_coord;
    end
    myMesh.verts = eul2rotm(rotAnglesXYZ,'XYZ') * myMesh.verts;
    myMesh.verts = myMesh.verts - mean(myMesh.verts,2);
    

    %% camera setup 

    %setup camera with focal length 1, centre 0.1,0.2
%     cam = [ 1,0,0.1;
%             0,1,0.2;
%             0,0,1];
    cam = eye(3);

    %create a tform matrix
    %%% angles = [Z Rotation, Y Rotation, X Rotation] = [roll, yaw, pitch]
    tform = eye(4); % tform(1:3,1:3) = rotation matrix
%     tform(1:3,4) = [0,0,1]; %position;
%     tform(3,4) = max(abs(coord_frontal(3,:)))*10;

    %distorsion
    dist = [0,0,0,0,0]; %[k1,k2,p1,p2,k3]


    
    
    %% Images
    
    %%%%%%%%% FRONTAL %%%%%%%%%%
    deg = 180; rad = deg*pi/180;
    Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];
    myMesh.verts = Ry*myMesh.verts;    
    
    if read_files
        if verbose, fprintf('Upsampling the mesh\n'), end
        texture_struct.faces_tex = faces_tex; texture_struct.RGB = texture;
        texture_struct.tex_coord_img = tex_coord_img; texture_struct.stereo_img = imread(stereo_img_filepath);
        [myMesh, myTexture] = mesh_upSample_triEdges(myMesh, 'texture', texture_struct);
    end
    
    cam(1,3) = -min(myMesh.verts(1,:));
    cam(2,3) = -min(myMesh.verts(2,:));
    tform(3,4) = max(myMesh.verts(3,:))*10;
    if contains(render,'F')
        if verbose
            fprintf('Z-buffering frontal\t')
            if ~isempty(lmksF)
                [~, ~, img, map, lmksF_img] = z_buffering(myMesh.verts, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'Landmarks',lmksF,'verbose');
            else
                [~, ~, img, map] = z_buffering(myMesh.verts, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'verbose');
                lmksF_img = [];
            end
            fprintf('\n')
        else
            if ~isempty(lmksF)
                [~, ~, img, map, lmksF_img] = z_buffering(myMesh.verts, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'Landmarks',lmksF );
            else
                [~, ~, img, map] = z_buffering(myMesh.verts, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize);
                lmksF_img = [];
            end
        end

        if isempty(outFile)
            figure; imshow(uint8(img));
            if ~isempty(lmksF_img), hold on, plot2pts(lmksF_img', '*r'); end
        else
            imwrite(uint8(img),[outDir, outFile,'_frontal.jpg']);
            if ~isempty(lmksF_img)
                Write_PTS_Landmarks2D([outDir, outFile,'_frontal.pts'],lmksF_img');
            end
        end

    %     if verbose, fprintf('\nSaving upsampled PLY'), end
    %     ply_writeMesh(newMesh, [outDir,'\',outFile,'_upsampled_frontal.ply'])

        map_2Dto3D(1).file = [outDir, outFile,'_frontal.jpg'];
        map_2Dto3D(1).image = img;
        map_2Dto3D(1).map = map;
        map_2Dto3D(1).angle = 0;
        map_2Dto3D(1).landmarks = lmksF_img;
    end
    
    
    %%%%%%%%% TURN RIGHT %%%%%%%%%%
    if contains(render,'L')
        deg = -75; rad = deg*pi/180;
        Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];
        coord_right = Ry*myMesh.verts;

        if verbose
            fprintf('Z-buffering right\t')
            if ~isempty(lmksL)
                [~, ~, img, map, lmksR_img] = z_buffering(coord_right, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'Landmarks',lmksL,'verbose');
            else
                [~, ~, img, map] = z_buffering(coord_right, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'verbose');
                lmksR_img = [];
            end
            fprintf('\n')
        else
            if ~isempty(lmksL)
                [~, ~, img, map, lmksR_img] = z_buffering(coord_right, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'Landmarks',lmksL );
            else
                [~, ~, img, map] = z_buffering(coord_right, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize);
                lmksR_img = [];
            end
        end

        if isempty(outFile)
            figure; imshow(uint8(img));
            if ~isempty(lmksR_img), hold on, plot2pts(lmksR_img', '*r'); end
        else
            imwrite(uint8(img),[outDir, outFile,'_leftside.jpg']);
            if ~isempty(lmksR_img)
                Write_PTS_Landmarks2D([outDir, outFile,'_leftside.pts'],lmksR_img');
            end
        end

    %     disp('Saving PLY')
    %     ply_writeMesh(newMesh, [file_name,'_upsampled_leftside.ply'])

        map_2Dto3D(3).file = [outDir, outFile,'_leftside.jpg'];
        map_2Dto3D(3).image = img;
        map_2Dto3D(3).map = map;
        map_2Dto3D(3).angle = deg;
        map_2Dto3D(3).landmarks = lmksR_img;
    end
    
    
    %%%%%%%%% TURN LEFT %%%%%%%%%%
    if contains(render,'R')
        deg = 75; rad = deg*pi/180;
        Ry = [cos(rad), 0, sin(rad); 0, 1, 0; -sin(rad), 0, cos(rad)];
        coord_left = Ry*myMesh.verts;

        if verbose
            fprintf('Z-buffering left\t')
            if ~isempty(lmksR)
                [~, ~, img, map, lmksL_img] = z_buffering(coord_left, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'Landmarks',lmksR,'verbose');
            else
                [~, ~, img, map] = z_buffering(coord_left, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'verbose');
                lmksL_img = [];
            end
            fprintf('\n')
        else
            if ~isempty(lmksR)
                [~, ~, img, map, lmksL_img] = z_buffering(coord_left, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize, 'Landmarks',lmksR );
            else
                [~, ~, img, map] = z_buffering(coord_left, myMesh.faces, myTexture, cam, tform, dist, 'scale_for_imgSize', scale_for_imgSize);
                lmksL_img = [];
            end
        end

        if isempty(outFile)
            figure; imshow(uint8(img));
            if ~isempty(lmksL_img), hold on, plot2pts(lmksL_img', '*r'); end
        else
            imwrite(uint8(img),[outDir, outFile,'_rightside.jpg']);
            if ~isempty(lmksL_img)
                Write_PTS_Landmarks2D([outDir, outFile,'_rightside.pts'],lmksL_img');
            end
        end

    %     disp('Saving PLY')
    %     ply_writeMesh(newMesh, [file_name,'_upsampled_rightside.ply'])

        map_2Dto3D(2).file = [outDir,outFile,'_rightside.jpg'];
        map_2Dto3D(2).image = img;
        map_2Dto3D(2).map = map;
        map_2Dto3D(2).angle = deg;
        map_2Dto3D(2).landmarks = lmksL_img;
    end
end