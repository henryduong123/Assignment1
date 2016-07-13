
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2016 Drexel University
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
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

function WriteSegData(DatasetDir, DatasetName)
global CellHulls ConnectedDist

% fname=Helper.GetFullImagePath(1);
% im = Helper.LoadIntensityImage(fname);
% if isempty(im)
%     fprintf('error - unable to extract image size - tracking will fail\n');
% end
rcImageDims = Metadata.GetDimensions('rc');

th = max([CellHulls.time]);
hashedHulls = cell(th,1);

% reset tracking info
for n=1:length(CellHulls)
    hashedHulls{CellHulls(n).time}=[hashedHulls{CellHulls(n).time};n];
end

fname = fullfile(DatasetDir, ['SegObjs_' DatasetName '.txt']);
fid=fopen(fname,'wt');
fprintf(fid,'%d %d\n',th,length(CellHulls) );
for i=1:length(hashedHulls)
    fprintf(fid,'%d\n',length(hashedHulls{i}) );
    for j=1:length(hashedHulls{i})
        [r c]=ind2sub(rcImageDims,CellHulls(hashedHulls{i}(j)).indexPixels);
        COM=round(mean([r c],1));
        fprintf(fid,'%d %d %d %d:',COM(2),COM(1),length(r),size(ConnectedDist{hashedHulls{i}(j)},1) );
        for k=1:size(ConnectedDist{hashedHulls{i}(j)},1)
            fprintf(fid,' %d,%f', ConnectedDist{hashedHulls{i}(j)}(k,1), ConnectedDist{hashedHulls{i}(j)}(k,2));
        end
         fprintf(fid,'\n');
    end
end

fclose(fid);
end
