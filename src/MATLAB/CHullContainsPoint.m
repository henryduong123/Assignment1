function bInHull = CHullContainsPoint(pt, hulls)
    bInHull = boolean(zeros(length(hulls),1));
    
    for i=1:length(hulls)
        
        if ( size(hulls(i).points,1) <= 1 )
            continue;
        end
        
        cvpts = hulls(i).points;
        hullvec = diff(cvpts);
        
        outnrm = [-hullvec(:,2) hullvec(:,1)];
        %outnrm = outnrm ./ sqrt(sum(outnrm.^2,2));
        
        ptvec = cvpts(1:end-1,:) - ones(size(outnrm,1),1)*pt;
        %ptvec = ptvec ./ sqrt(sum(ptvec.^2,2));
        
        chkIn = sign(sum(outnrm .* ptvec,2));
        
        bInHull(i) = all(chkIn >= 0);
    end
end