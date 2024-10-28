function  [landmarks, varargout] = Read_PTS_Landmarks( fileName )
    
[fid, msg] = fopen( fileName, 'rt' );
if fid == -1
    error( msg );
end

fgetl(fid); % Skip version id
nLandmarks = str2num( fgetl(fid) );
landmarks = zeros(3, nLandmarks);

landmarks_names = cell(1,nLandmarks);
for j = 1 : nLandmarks
    newLine = fgetl( fid );
    [token, remain] = strtok( newLine );
    landmarks_names{j} = token;
    [token, remain] = strtok(remain);
    landmarks(1, j) = str2num( token );
    [token, remain] = strtok(remain);
    landmarks(2, j) = str2num( token );
    landmarks(3, j) = str2num( remain );   
end       

fclose( fid );

if nargout > 1
    varargout{1} = landmarks_names;
end
end
