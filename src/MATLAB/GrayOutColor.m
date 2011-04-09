function grayedColor = GrayOutColor(color)
%This will take the given color and give back a grayed out color of similar
%hue

%--Eric Wait

grayedColor = [0 0 0];
parfor i=1:3
    if(0==color(i))
        grayedColor(i) = 0.15;
    else
        grayedColor(i) = color(i) * 0.4;
    end
end
end
