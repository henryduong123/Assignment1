%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function bInHull = CHullContainsPoint(pt, hulls)
    bInHull = false(length(hulls),1);
    
    for i=1:length(hulls)
        
        if ( size(hulls(i).points,1) <= 1 )
            continue;
        end
        
%         cvpts = hulls(i).points;
%         hullvec = diff(cvpts);
%         
%         outnrm = [-hullvec(:,2) hullvec(:,1)];
%         %outnrm = outnrm ./ sqrt(sum(outnrm.^2,2));
%         
%         ptvec = cvpts(1:end-1,:) - ones(size(outnrm,1),1)*pt;
%         %ptvec = ptvec ./ sqrt(sum(ptvec.^2,2));
%         
%         chkIn = sign(sum(outnrm .* ptvec,2));
%         
%         bInHull(i) = all(chkIn >= 0);

        bInHull(i) = inpolygon(pt(1), pt(2), hulls(i).points(:,1), hulls(i).points(:,2));
    end
end