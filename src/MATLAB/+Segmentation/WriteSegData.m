% WriteSegData.m - Write cell segmentation data to a file for use by the
% standalone tracker (MTC.exe).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function WriteSegData(objsSegment,DatasetName)

global CONSTANTS;

fname=[CONSTANTS.rootImageFolder '\' CONSTANTS.datasetName '_t' Helper.SignificantDigits(1) '.TIF'];
[im map]=imread(fname);
if isempty(im)
    fprintf('error - unable to extract image size - tracking will fail\n');
end
sz=size(im);

th=max([objsSegment.t]);
HashedHulls=cell(th,1);

% reset tracking info
for n=1:length(objsSegment)
    HashedHulls{objsSegment(n).t}=[HashedHulls{objsSegment(n).t};n];
end
fname=['.\segmentationData\SegObjs_' DatasetName '.txt'];
fid=fopen(fname,'wt');
fprintf(fid,'%d %d\n',th,length(objsSegment) );
for i=1:length(HashedHulls)
    fprintf(fid,'%d\n',length(HashedHulls{i}) );  
    for j=1:length(HashedHulls{i})
        [r c]=ind2sub(sz,objsSegment(HashedHulls{i}(j)).indPixels);
        COM=round(mean([r c],1));
        fprintf(fid,'%d %d %d %d:',COM(2),COM(1),length(r),size(objsSegment(HashedHulls{i}(j)).DarkConnectedHulls,1) );
        for k=1:size(objsSegment(HashedHulls{i}(j)).DarkConnectedHulls,1)
            fprintf(fid,' %d,%f', objsSegment(HashedHulls{i}(j)).DarkConnectedHulls(k,1),objsSegment(HashedHulls{i}(j)).DarkConnectedHulls(k,2));
        end
         fprintf(fid,'\n');
    end
end

fclose(fid);
end