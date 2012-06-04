function RewriteSegData(DatasetDir, DatasetName)
global CONSTANTS CellHulls ConnectedDist

% fname=[CONSTANTS.rootImageFolder '\' CONSTANTS.datasetName '_t' SignificantDigits(1) '.TIF'];
% [im map]=imread(fname);
% if isempty(im)
%     fprintf('error - unable to extract image size - tracking will fail\n');
% end
sz = CONSTANTS.imageSize;

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
        [r c]=ind2sub(sz,CellHulls(hashedHulls{i}(j)).indexPixels);
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