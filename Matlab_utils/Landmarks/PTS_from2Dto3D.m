function lmks_3D = PTS_from2Dto3D(map, angle, pts2D_file, print2file)
    fid = fopen(pts2D_file);
    lmk = fgetl(fid);
    lmks_3D = [];
    Ry = [cos(-angle*pi/180), 0, sin(-angle*pi/180); 0, 1, 0; -sin(-angle*pi/180), 0, cos(-angle*pi/180)];
    while ischar(lmk)
        px = round(str2num(lmk))+1;
        lmk3D = reshape(map(px(2),px(1),:), [1,3]);
        lmks_3D = [lmks_3D; (Ry*lmk3D')'];

        lmk = fgetl(fid);
    end
    fclose(fid);

    if print2file
        fid = fopen([pts2D_file(1:end-4),'_3D.pts'],'w');
        fprintf(fid,'Version 1.0\n');
        fprintf(fid,'%d\n',size(lmks_3D,1));
        for i = 1:size(lmks_3D,1)
            fprintf(fid,'S%03d  %f %f %f\n',i-1,lmks_3D(i,1),lmks_3D(i,2),lmks_3D(i,3));
        end
        fclose(fid);
    end
end