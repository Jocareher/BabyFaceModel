function plot2pts( XY, varargin )

% plot2pts( XY )
%
% This function is just a wrapper to plot so that we pass a single
% parameter: the matrix XY, of size 2 * N (therefore, each COLUMN
% is a point in 2D
%

if not( size( XY, 1 ) == 2 )
    error('Input matrix muxt be of size 2*N');
end

plot( XY(1,:), XY(2,:), varargin{:});
