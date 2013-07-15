% bool = HaveFluor()
% Returns 1 or 0 depending if there is fluorescence data

function bool = HaveFluor()
global FluorData

if isempty(FluorData)
    bool =0;
else
    bool = 1;
end

end

