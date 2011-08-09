%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function color = GetNextColor()
%Takes the global Colors list and selects the next in the list and returns
%it

global Colors
persistent index

%init index
if(isempty(index))
    index=1;
end

if isempty(Colors)
    Colors  = CreateColors();
end

color.background = Colors(index,1:3);
color.text = Colors(index,4:6);
color.backgroundDark = Colors(index,7:9);

%increment index or roll over
if(index >= length(Colors))
    index = 1;
else
    index = index + 1;
end
end
