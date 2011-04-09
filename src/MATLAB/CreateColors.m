function colors = CreateColors()
%Creates a table of default colors in the format:
%background (r,g,b), text (r,g,b)
%the text is typicaly white or black depending on the darkness of the
%background

%--Eric Wait

colors = [1,0,0,0,0,0,0.4,0.15,0.15;...
    1,0.5,0,0,0,0,0.4,0.2,0.15;...
    1,1,0,0,0,0,0.4,0.4,0.15;...
    0,1,0,0,0,0,0.15,0.4,0.15;...
    0,1,1,0,0,0,0.15,0.4,0.4;...
    0,0.5,1,1,1,1,0.15,0.2,0.4;...
    0.5,0,1,1,1,1,0.2,0.15,0.4;...
    1,0,0.5,0,0,0,0.4,0.15,0.2;...
    0,0.5,0,1,1,1,0.15,0.2,0.15;...
    0,0.75,0.75,0,0,0,0.15,0.3,0.3;...
    0.75,0,0.75,1,1,1,0.3,0.15,0.3;...
    0.75,0.75,0,0,0,0,0.3,0.3,0.15;...
    0.7969,0,0.3984,1,1,1,0.31876,0.15,0.15936;...
    0.5977,0.3984,0,1,1,1,0.23908,0.15936,0.15;...
    0,0.7969,1,0,0,0,0.15,0.31876,0.4;...
    1,0.5977,0.3984,0,0,0,0.4,0.23908,0.15936;...
    0,0.7969,0,0,0,0,0.15,0.31876,0.15;...
    0.7969,0.5977,0,1,1,1,0.31876,0.23908,0.15;];
end
