function Write_PTS_Landmarks2D( fileName, myLmk )
% Write_PTS_Landmarks( fileName, myLmk )
    
if size( myLmk, 1 ) ~= 2
    error('Input landmarks must be a 2 x nL matrix');
end

[fid, msg] = fopen( fileName, 'wt' );
if fid == -1
    error( msg );
end

fprintf(fid, 'Version 1.0\n');
fprintf(fid, '%d\n', size( myLmk, 2 ));
for jL = 1 : size( myLmk, 2 )
    fprintf(fid, 'S%04d  %f  %f \n', ...
        jL-1, myLmk(1,jL), myLmk(2,jL) );
end       

fclose( fid );
