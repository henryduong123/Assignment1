function bValid = ValidUIHandle(hCheck)
    if ( isempty(hCheck) )
        bValid = false;
        return;
    end
    
    bValid = false(size(hCheck));
    for i=1:numel(hCheck)    
        if ( ~ishandle(hCheck(i)) )
            continue;
        end
        
        bValid(i) = true;
    end
end
