function [ ] = showPtsOnImg(imgFilePathName, ptsFilePathName, varargin)
        
    % read image    
    im = imread(imgFilePathName);
    
    % read pts
    try
        pts = Read_PTS_Landmarks2D(ptsFilePathName);
    catch
        ptsFileId=fopen(ptsFilePathName);
        points=textscan(ptsFileId,'%f %f');
        pts = cell2mat(points)';
        fclose(ptsFileId);
    end
    
    x = pts(1,:);
    y = pts(2,:);
    texts(:,1) = 1:length(x); %should point index sequency
    
    f = figure;  % create new figure with specified size 
    imshow(im);
    hold on;
    plot(x,y, '.r', 'MarkerSize', 10);
    hold on; 
    text(x,y, num2str(texts(:,1)), 'Color','k','FontSize',14);
    axis on;
    
    
    if nargin > 2
        outFile = varargin{1};
        savefig(gcf,outFile);
        close(f);
    end
    
end
