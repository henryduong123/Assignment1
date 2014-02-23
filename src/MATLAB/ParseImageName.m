function [sigDigits imageDataset] = ParseImageName(imageName)    

    namePattern = 'imageNamePattern';
    
    tIndex = strfind(imageName,'t');
    
    if (isempty(tIndex))
        error('File name does not have time component: %s',imageName);
    end
    
    endIndex = strfind(imageName,'.');
    tIndex = tIndex(find(tIndex<endIndex,1,'last'));
    
    if (tIndex+1==endIndex)
        %TODO the t comes after the number
        error('File name pattern is not yet supported: %s',imageName);
    end
    
    nanIndex = tIndex;
    for i=1:endIndex-tIndex
        if(isnan(str2double(imageName(tIndex+i))))
            nanIndex = tIndex+i;
            break;
        end
    end
    
    if (nanIndex~=tIndex)
        endIndex = nanIndex;
    end
    
    sigDigits = endIndex - tIndex - 1;
    imageDataset = imageName(1:(tIndex)-1);
end
