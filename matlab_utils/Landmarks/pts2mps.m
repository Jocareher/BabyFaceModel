clear all

fileID = fopen('E:\PhD\Ultrasonido\NRRD_pruebas\Landmarks\1632364_3D_lmks.pts','r');
fgetl(fileID);
nOfLmks = str2double(fgetl(fileID));

lmks = [];
for i = 1:nOfLmks
    line = fgetl(fileID);
    line = strsplit(line);
    lmks = [lmks; -str2double(line{2}) -str2double(line{3}) str2double(line{4})];
end

fclose(fileID);



fileID = fopen('E:\PhD\Ultrasonido\NRRD_pruebas\Landmarks\newMPS.mps','w');

fprintf(fileID,'%s\n','<?xml version="1.0" encoding="UTF-8" ?>');
fprintf(fileID,'%s\n','<point_set_file>');
fprintf(fileID,'\t%s\n','<file_version>0.1</file_version>');
fprintf(fileID,'\t%s\n','<point_set>');
fprintf(fileID,'\t\t%s\n','<time_series>');
fprintf(fileID,'\t\t\t%s\n','<time_series_id>0</time_series_id>');
fprintf(fileID,'\t\t\t%s\n','<Geometry3D ImageGeometry="false" FrameOfReferenceID="0">');
fprintf(fileID,'\t\t\t\t%s\n','<IndexToWorld type="Matrix3x3" m_0_0="1" m_0_1="0" m_0_2="0" m_1_0="0" m_1_1="1" m_1_2="0" m_2_0="0" m_2_1="0" m_2_2="1" />');
fprintf(fileID,'\t\t\t\t%s\n','<Offset type="Vector3D" x="0" y="0" z="0" />');
fprintf(fileID,'\t\t\t\t%s\n','<Bounds>');

min_lmks = min(lmks,[],1);
max_lmks = max(lmks,[],1); if min_lmks == max_lmks, max_lmks=max_lmks+1; end
fprintf(fileID,'\t\t\t\t\t%s%f%s%f%s%f%s\n','<Min type="Vector3D" x="',min_lmks(1),'" y="', min_lmks(2),'" z="', min_lmks(3), '" />');
fprintf(fileID,'\t\t\t\t\t%s%f%s%f%s%f%s\n','<Max type="Vector3D" x="', max_lmks(1),'" y="', max_lmks(2),'" z="',max_lmks(3),'" />');

fprintf(fileID,'\t\t\t\t%s\n','</Bounds>');
fprintf(fileID,'\t\t\t%s\n','</Geometry3D>');

for i = 1:nOfLmks
    fprintf(fileID,'\t\t\t%s\n','<point>');
    fprintf(fileID,'\t\t\t\t%s%d%s\n','<id>',i-1,'</id>');
    fprintf(fileID,'\t\t\t\t%s%d%s\n','<specification>',i-1,'</specification>');
    fprintf(fileID,'\t\t\t\t%s%f%s\n','<x>',lmks(i,1),'</x>');
    fprintf(fileID,'\t\t\t\t%s%f%s\n','<y>',lmks(i,2),'</y>');
    fprintf(fileID,'\t\t\t\t%s%f%s\n','<z>',lmks(i,3),'</z>');
    fprintf(fileID,'\t\t\t%s\n','</point>');

end

fprintf(fileID,'\t\t%s\n','</time_series>');
fprintf(fileID,'\t%s\n','</point_set>');
fprintf(fileID,'%s\n','</point_set_file>');

fclose(fileID);