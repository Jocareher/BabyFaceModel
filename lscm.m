function [u, v] = lscm(vertices, faces, anchor_points)
    % Número de vértices y caras
    num_vertices = size(vertices, 1);
    num_faces = size(faces, 1);

    % Crear matrices sparse para los coeficientes de la ecuación lineal
    A = sparse(2*num_faces, num_vertices);
    b = zeros(2*num_faces, 2);

    % Construir las matrices A y b
    for i = 1:num_faces
        face = faces(i, :);
        v1 = vertices(face(1), :);
        v2 = vertices(face(2), :);
        v3 = vertices(face(3), :);

        % Coordenadas de las aristas en 3D
        e1 = v2 - v1;
        e2 = v3 - v1;

        % Coordenadas en 2D
        A(2*i-1, face) = [1, 0, 0];
        A(2*i, face) = [0, 1, 0];

        % Condiciones de ortogonalidad y mismo tamaño de gradientes
        b(2*i-1, :) = [e1(1), e2(1)];
        b(2*i, :) = [e1(2), e2(2)];
    end

    % Aplicar restricciones de puntos de anclaje
    A(anchor_points, :) = 0;
    A(anchor_points + num_vertices, :) = 0;
    for i = 1:length(anchor_points)
        A(anchor_points(i), anchor_points(i)) = 1;
        A(anchor_points(i) + num_vertices, anchor_points(i) + num_vertices) = 1;
    end

    % Resolver el sistema lineal
    uv = A \ b;

    % Extraer coordenadas u y v
    u = uv(1:num_vertices, 1);
    v = uv(1:num_vertices, 2);
end
