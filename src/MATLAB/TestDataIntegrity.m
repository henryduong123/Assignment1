function TestDataIntegrity(correct)
%TestDataIntegrity(correct) tests to make sure that the database is consistant.
%Takes the CellTracks as the most accurate.  If correct==1, this
%function will attempt to correct the error using the data from CellTracks
%***USE SPARINGLY, TAKES A LOT OF TIME***

%--Eric Wait

global CellTracks CellHulls CellFamilies HashedCells

hullsList = [];
fprintf('Checking CellTracks...');
AddFields();
progress = 0;
iterations = length(CellTracks);
for i=1:length(CellTracks)
    progress = progress+1;
    Progressbar(progress/iterations);
%     fprintf(', %d',i);
    %% Check child/parent/sibling relationships
    if(~isempty(CellTracks(i).parentTrack))
        if(isempty(find(CellTracks(CellTracks(i).parentTrack).childrenTracks==i, 1)))
            error(['Parent ' num2str(CellTracks(i).parentTrack) ' does not recognize track ' num2str(i) ' as a child']);
        end
        if(CellTracks(CellTracks(i).siblingTrack).siblingTrack~=i)
            error(['Track ' num2str(CellTracks(i).siblingTrack) ' does not recognize track ' num2str(i) ' as a sibling']);
        end
    end
    currentFamily = CellTracks(i).familyID;
    if(~isempty(CellTracks(i).childrenTracks))
        for j=1:length(CellTracks(i).childrenTracks)
            if(CellTracks(CellTracks(i).childrenTracks(j)).parentTrack~=i)
                error(['Child ' num2str(CellTracks(i).childrenTracks(j)) ' does not recognize track ' num2str(i) ' as a parent']);
            end
            if(CellTracks(CellTracks(i).childrenTracks(j)).familyID~=currentFamily)
                error(['Track ' num2str(i) ' and child ' num2str(CellTracks(i).childrenTracks(j)) ' do not agree on family ' num2str(currentFamily)]);
            end
        end
    end
%     if(isempty(CellTracks(i).familyID) || isempty(CellTracks(i).hulls) || isempty(CellTracks(i).startTime) || isempty(CellTracks(i).endTime) || isempty(CellTracks(i).color))
%         if(~isempty(CellTracks(i).familyID) || ~isempty(CellTracks(i).hulls) || ~isempty(CellTracks(i).startTime) || ~isempty(CellTracks(i).endTime) || ~isempty(CellTracks(i).color))
%             ClearTrack(i);
%             error(['Track ' num2str(i) ' is suppose to cleared out but still has data']);
%         end
%     end
    
    %% check if the current track is in the correct family and not in any
    %other
    if(~isempty(currentFamily))
        index = find(CellFamilies(currentFamily).tracks==i);
        if(isempty(index))
            if(correct)
                CellFamilies(currentFamily).tracks(end+1) = i;
                fprintf('Track %d added to family %d\n',i,currentFamily);
            else
                error(['Track ' num2str(i) ' not in family ' num2str(currentFamily)])
            end
        elseif(1<length(index))
            if(correct)
                for j=2:length(index)
                    CellFamilies(currentFamily).tracks(index(j)) = 0;
                end
                CellFamilies(currentFamily).tracks = find(CellFamilies(currentFamily).tracks);
                fprintf('Removed additional(s) track %d from family %d\n',i,currentFamily);
            else
                error(['Too many of track ' num2str(i) ' in family ' num2str(currentFamily)]);
            end
        end
        
        %check for parent familyIDs
        if(~isempty(CellTracks(i).parentTrack))
            if(CellTracks(CellTracks(i).parentTrack).familyID~=currentFamily)
                error(['Track ' num2str(i) ' and its parent ' num2str(CellTracks(i).parentTrack) ' do not agree on a family ' num2str(currentFamily)]);
            end
        end
        
        for j=1:length(CellFamilies)
%             fprintf('CellFamilies %d ',j);
            if(currentFamily==j),continue,end
            index = find(CellFamilies(j).tracks==i);
            if(~isempty(index))
                if(correct)
                    CellFamilies(j).tracks(index) = [];
                    fprintf('Removed track %d from family %d\n',i,j);
                else
                    error(['Track ' num2str(i) ' is in family ' num2str(j) ' as well']);
                end
            end
        end
    end
    
    %% check hulls for a given track
    for j=1:length(CellTracks(i).hulls)
%         fprintf('Hulls %d ',j);
        if(~CellTracks(i).hulls(j)),continue,end
        if(any(ismember(hullsList,CellTracks(i).hulls(j))))
            tracks = [];
            for q=1:i
                if(~isempty(CellTracks(q).hulls) && ~isempty(find(CellTracks(q).hulls==CellTracks(i).hulls(j), 1)))
                    tracks = [tracks q];
                end
            end
            error(['Hull ' num2str(CellTracks(i).hulls(j)) ' is in track ' num2str(i) ' as well as other tracks']);
        end
        hullsList = [hullsList CellTracks(i).hulls(j)];
        time = j + CellTracks(i).startTime - 1;
        if(time ~= CellHulls(CellTracks(i).hulls(j)).time)
            error(['Hull ' num2str(CellTracks(i).hulls(j)) ' is not hashed correctly in track ' num2str(i)]);
        end
        index = find([HashedCells{time}.hullID]==CellTracks(i).hulls(j));
        if(isempty(index))
            error(['Hull ' num2str(CellTracks(i).hulls(j)) ' is not found in HashedCells at ' num2str(time)]);
        elseif(1<length(index))
            error(['Hull ' num2str(CellTracks(i).hulls(j)) ' is in HashedCells more than once at ' num2str(time)]);
        end
        if(HashedCells{time}(index).trackID~=i)
            error(['Hull ' num2str(CellTracks(i).hulls(j)) ' does not have the correct track ' num2str(i)]);
        end
    end
    
end
% fprintf('\n');

%% check CellHulls
% if(length(hullsList)~=length(find([CellHulls.deleted]==0)))
missingHulls = find(~[CellHulls.deleted]);
missingHulls = missingHulls(find(~ismember(missingHulls,hullsList)));
if(~isempty(missingHulls))
    if(correct)
        progress = 0;
        iterations = length(missingHulls); 
        for i=1:length(missingHulls)
            progress = progress+1;
            Progressbar(progress/iterations);
%             if(isempty(CellHulls(missingHulls(i)).points))
                if(any([HashedCells{CellHulls(missingHulls(i)).time}.hullID]==missingHulls(i)))
                    RemoveHullFromTrack(missingHulls(i),...
                        HashedCells{CellHulls(missingHulls(i)).time}(find([HashedCells{CellHulls(missingHulls(i)).time}.hullID]==missingHulls(i))).trackID);
                    HashedCells{CellHulls(missingHulls(i)).time}(find([HashedCells{CellHulls(missingHulls(i)).time}.hullID]==missingHulls(i))) = [];
                end
                CellHulls(missingHulls(i)).deleted = 1;
%             end
        end
    else
        error('HullsList ~= CellHulls');
    end
 end

progress = 0;
iterations = length(CellHulls);
for i=1:length(CellHulls)
    progress = progress+1;
    Progressbar(progress/iterations);
    if(~CellHulls(i).deleted && isempty(find([HashedCells{CellHulls(i).time}.hullID]==i, 1)))
        error(['Hull ' num2str(i) ' is not hashed to the correct time']);
    end
    if(CellHulls(i).deleted && ~isempty(find([HashedCells{CellHulls(i).time}.hullID]==i, 1)))
        if(correct)
            RemoveHullFromTrack(i,...
                HashedCells{CellHulls(i).time}([HashedCells{CellHulls(i).time}.hullID]==i).trackID);
            HashedCells{CellHulls(i).time}([HashedCells{CellHulls(i).time}.hullID]==i) = [];
        else
            error(['Hull ' num2str(i) ' should have been removed from HashedCells']);
        end
    end
end
Progressbar(1);%clear it out

fprintf('\nDone\n');
end
