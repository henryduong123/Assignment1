function WriteSegData(objsSegment,DatasetName)
sz=[1024 1344];
th=max([objsSegment.t]);
HashedHulls=cell(th,1);

% reset tracking info
for n=1:length(objsSegment)
    HashedHulls{objsSegment(n).t}=[HashedHulls{objsSegment(n).t};n];
end
fname=['SegObjs_' DatasetName '.txt'];
fid=fopen(fname,'wt');
fprintf(fid,'%d %d\n',th,length(objsSegment) );
for i=1:length(HashedHulls)
    fprintf(fid,'%d\n',length(HashedHulls{i}) );  
    for j=1:length(HashedHulls{i})
        [r c]=ind2sub(sz,objsSegment(HashedHulls{i}(j)).indPixels);
        COM=round(mean([r c],1));
        %i,t,xCOM,yCOM
        fprintf(fid,'%d %d %d %d:',COM(2),COM(1),length(r),size(objsSegment(HashedHulls{i}(j)).DarkConnectedHulls,1) );
        for k=1:size(objsSegment(HashedHulls{i}(j)).DarkConnectedHulls,1)
            fprintf(fid,' %d,%f', objsSegment(HashedHulls{i}(j)).DarkConnectedHulls(k,1),objsSegment(HashedHulls{i}(j)).DarkConnectedHulls(k,2));
        end
         fprintf(fid,'\n');
    end
end

fclose(fid);
end