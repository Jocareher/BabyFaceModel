function pts2fcsv(ptsfile, outfile, varargin)

% ptsfile = 'E:\PhD\Washington\Model_CNH\Model\landmarks23\324_180329074157.pts';
% outfile = 'E:\PhD\FaceAtlas\ICPD_FaceAtlas\324_180329074157.fcsv';
% lmksNames_file = 'E:\PhD\Washington\Model_CNH\Model\landmarks23\Landmarks_names_abbrev.txt';



    lmks = Read_PTS_Landmarks(ptsfile);
    if nargin > 0
        fileID = fopen(varargin{1},'r');
        lmkNames = textscan(fileID,'%s');
        lmkNames = lmkNames{1};
        fclose(fileID);
        if length( lmkNames ) ~= size(lmks,2)
            warning('Mismatch in number of provided landmark names and landmarks. Ignoring landmark names.')
            lmkNames = repmat({''}, 1, size(lmks,2) );
        end
    else
        lmkNames = repmat({''}, 1, size(lmks,2) );
    end

    fid = fopen( outfile, 'w' );

    % Header
    fprintf( fid, '# Markups fiducial file version = 4.10\n' );
    fprintf( fid, '# CoordinateSystem = 0\n' );
    fprintf( fid, '# columns = id,x,y,z,ow,ox,oy,oz,vis,sel,lock,label,desc,associatedNodeID\n' );


    % Landmarks
    for jL = 1:size(lmks,2)
        if ~any( isnan(lmks(:,jL)) )
            fprintf( fid, 'vtkMRMLMarkupsFiducialNode_%02i,', jL );
            fprintf( fid, '%.3f,%.3f,%.3f,', lmks(:,jL) );
            fprintf( fid, '%.3f,%.3f,%.3f,%.3f,', zeros(1,3), 1 );
            fprintf( fid, '%i,%i,%i,', 1, 1, 0);
            fprintf( fid, '%s,vtkMRMLModelNode30\n', lmkNames{jL} );
        end
    end
    fclose( fid );

end