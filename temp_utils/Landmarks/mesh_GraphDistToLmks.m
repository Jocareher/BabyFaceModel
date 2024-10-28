function [graphDist_to_Lmk_Map] = mesh_GraphDistToLmks( mesh_3D, lmk_pts )

    [vertFaces, vertFaces_N] = mesh_vertexFaces( mesh_3D );
    vertEdges_v = cell(1, length( vertFaces_N ));
    vertEdges_d2 = cell(1, length( vertFaces_N ));
    for jv = 1 : length( vertFaces_N )
        % Get adjacent faces and all vertices involved
        f = vertFaces(jv, 1:vertFaces_N(jv));
        vv = mesh_3D.faces(:, f);
        vv = unique_vecFast( vv(:) );
        vv( vv == jv ) = [];

        vertEdges_v{ jv } = vv;
        vertEdges_d2{ jv } = sqrt( sum(( mesh_3D.verts(:, vv) - ...
            repmat( mesh_3D.verts(:, jv), [1 length(vv)]) ).^2))';
    end

    % For each landmark, compute
    NV = length( vertFaces_N );
    NL = size( lmk_pts, 2 );
    graphDist_to_Lmk_Map = inf * ones( NL, NV);

    for jL_idx = 1 : NL
        fprintf(1, '.');

        % Find closest vertex to landmark coordinate
        dist_v = mesh_3D.verts - repmat( lmk_pts(:,jL_idx), [1 NV] );
        [~, v0] = min( sum( dist_v.^2 ) );

        visited_nodes = zeros(1, NV);
        unvisited_v = [];
        graphDist_to_Lmk_Map( jL_idx, v0 ) = 0;

        cNode = v0;
        while 1
            % Update neighbors           
            neig_v = vertEdges_v{ cNode };
            graphDist_to_Lmk_Map( jL_idx, neig_v ) = ...
                min(graphDist_to_Lmk_Map(jL_idx, neig_v), graphDist_to_Lmk_Map(jL_idx, cNode) + 1);
            
            % Mark current node as visited
            visited_nodes( cNode ) = 1;

            unvisited_v = unique_vecFast([unvisited_v; neig_v]);
            unvisited_v = unvisited_v( visited_nodes( unvisited_v ) == 0 );
            %unvisited_v( unvisited_v == cNode ) = [];
            
%             % Select next
%             unvisited_v = find( visited_nodes == 0 );
            if isempty( unvisited_v ), break; end

            [min_d2, u_idx] = min( graphDist_to_Lmk_Map( jL_idx, unvisited_v ));
            if isinf( min_d2 ), break; end

            cNode = unvisited_v( u_idx );
        end

    end
    fprintf('\n')