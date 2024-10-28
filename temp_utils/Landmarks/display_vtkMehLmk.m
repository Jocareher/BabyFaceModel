function display_vtkMehLmk( dbFILES, theShapes, varargin)
%
% display_vtkMehLmk( dbFILES, theShapes);
% display_vtkMehLmk( dbFILES, theShapes, theShapes2);
% display_vtkMehLmk( dbFILES, theShapes, 'radius', r);
% 
% If a single mesh is to be displayed you can also use
% display_vtkMehLmk( meshName, theShape, 'radius', r);
%

theShapes2 = [];
r_Lmk = 2;
opac_val = 0.7;

if not( isempty( varargin ))
    if length( varargin ) > 1        
        while not( isempty( varargin ))
            if strcmpi( varargin{1}, 'radius' )
                r_Lmk = varargin{2};
                varargin(1:2) = [];
                continue;
            end                        
            
            if strcmpi( varargin{1}, 'opacity' )
                opac_val = varargin{2};
                varargin(1:2) = [];
                continue;
            end            
              
            if strcmpi( varargin{1}, 'shape2' )
                theShapes2 = varargin{2};
                varargin(1:2) = [];
                continue;
            end                  
                        
            error('Unrecognized input argument');            
        end
    else
        theShapes2 = varargin{1};
    end
end
    
if not( isstruct( dbFILES ))
    if size( theShapes, 1 ) == 1
        plyFullName = dbFILES;
        dbFILES = struct('plyFullName',{});
        dbFILES(1).plyFullName = plyFullName;
    else
        error('Input names must be organized in a struct');
    end
end
    

% % For creating a PTS file
% % ===========================================================
for j = 1 : size( theShapes, 1 )
    [fid,msg] = fopen('temp.cor', 'wt');
    if fid == -1
        error( msg );
    end

    nLandmarks = size( theShapes, 2) / 3;
    fprintf(fid,'@Automatically located landmarks\n');
    for jL = 1 : nLandmarks; 
        fprintf(fid, 'L%02d \tX: %f \tY: %f \tZ: %f\n',...
            jL, theShapes(j, jL*3-2:jL*3)); 
    end

    fclose( fid );
    
    dosCommand = sprintf('%s -opacity %f -radius %.3f %s temp.cor',...
        'E:\\PhD\\Results\\Compute_error\\Landmarker\\vtkViewMeshLmk.exe',...
        opac_val, r_Lmk, dbFILES(j).plyFullName );
    
    if not( isempty( theShapes2 ))
        [fid,msg] = fopen('temp2.cor', 'wt');
        if fid == -1
            error( msg );
        end

        nLandmarks = size( theShapes2, 2) / 3;
        fprintf(fid,'@Automatically located landmarks\n');
        for jL = 1 : nLandmarks; 
            fprintf(fid, 'L%02d \tX: %f \tY: %f \tZ: %f\n',...
                jL, theShapes2(j, jL*3-2:jL*3)); 
        end

        fclose( fid );    
        dosCommand = sprintf('%s temp2.cor', dosCommand);
            
    end
    
    dosCommand = [dosCommand, ' > temp.txt'];
    dos( dosCommand );

end



