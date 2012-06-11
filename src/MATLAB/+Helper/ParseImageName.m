% [sigDigits imageDataset] = ParseImageName(imageName)

function [sigDigits imageDataset] = ParseImageName(imageName)
    sigDigits = 0;
    
    index = strfind(imageName,'_t');
    if ( ~isempty(index) )
        indexEnd = strfind(imageName,'.');
        sigDigits = indexEnd - index - 2;
        
        imageDataset = imageName(1:(index(length(index))-1));
    end
end