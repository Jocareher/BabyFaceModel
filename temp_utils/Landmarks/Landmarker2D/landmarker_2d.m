function [landmarks] = landmarker_2d(im,outPath,varargin)
%SUMMARY 
% INPUT -> image 
%          outPath: path (dir + file name) where we want to save de .pts file
%                      

%    Description : the user select the positions that want as landmarks in
%    the image clicking with the mouse. If a position is not visible the 
%    landmark is set as point outside the image that then will be
%    interpreted as NaN

%    [xi,yi] = getpts lets you choose points in the current figure using 
%    the mouse. 

    %    Use normal button clicks to add points. 
    
    %    A shift-, right-, or -click adds a final point and ends the selection.

    %    Pressing Return or Enter ends the selection without adding a final
    %    point. 

    %    Pressing Backspace or Delete removes the previously selected
    %    point.


% OUTPUT ->  2D landmarks of the image


%     close all
    [h,w,z] = size(im);
    f = figure;
    imshow(im);

    if ~isempty(varargin)
        lmks_old = varargin{1};
        lmks_old(isnan(lmks_old) | lmks_old==0) = 0.5;
        P = drawpolyline('Position',lmks_old','LineWidth',1e-5);
        x_lan = customWait(P);
        x_lan = x_lan';
        
    else
        [x,y] = getpts;
        x_lan= [x,y]';
    end
    
    landmarks= NaN(size(x_lan));

    ind = ~sum([sum(x_lan < 1) ; x_lan(1,:)> w  ; x_lan(2,:)> h]) > 0 ;

    landmarks(:,ind) = x_lan(:,ind);
    
    Write_PTS_Landmarks2D( outPath, landmarks )
    close(f);
end

function pos = customWait(hROI)

% Listen for mouse clicks on the ROI
l = addlistener(hROI,'ROIClicked',@clickCallback);

% Block program execution
uiwait;

% Remove listener
delete(l);

% Return the current position
pos = hROI.Position;

end

function clickCallback(~,evt)

if strcmp(evt.SelectionType,'double')
    uiresume;
end

end

