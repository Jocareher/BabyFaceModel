clear
close all

%% Set Image Landmarks 

% ADD PATHS

addpath('utils','optimisations', 'mesh_utilities','plywrite','Babies');

dir_images = 'Babies/' ; % Directory in which there are the images

directories = dir(dir_images);
directories=directories(~ismember({directories.name},{'.','..','.DS_Store'})); % get all the folders

for i = 1:length(directories)
    
    all_images = dir([dir_images,directories(i).name,'/*.png']); % get all the images in the folder

    for j= 1:length(all_images)
        
        im= imread(all_images(j).name); 
        [landmarks] = lanmarker_2d(im,[dir_images,directories(i).name,'/'],all_images(j).name(1:end-4));

%         figure;
%         imagesc(im);
%         hold on;
%         axis image;
%         axis off;
%         plot(landmarks(1,:),landmarks(2,:),'r.','markersize',15);  
%         label = cellstr(num2str([1:length(landmarks)]'));
%         text(landmarks(1,:),landmarks(2,:),label,'VerticalAlignment','bottom','HorizontalAlignment','right')
%    
    end
end

%% LOAD 2D LANDMARKS .pts
landmarks = Read_PTS_Landmarks2D('1C.pts');
im= imread('1C.png');

figure;
imagesc(im);
hold on;
axis image;
axis off;
plot(landmarks(1,:),landmarks(2,:),'r.','markersize',15);  
label = cellstr(num2str([1:length(landmarks)]'));
text(landmarks(1,:),landmarks(2,:),label,'VerticalAlignment','bottom','HorizontalAlignment','right')

%% REMEMBER TO PUT THIS LINE IN THE CODE --> 
landmarks(2,:) = size(im,1)+1-landmarks(2,:); % is how the code interpret the image landmarks 

