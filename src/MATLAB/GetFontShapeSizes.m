function [fontSize shapeSize] = GetFontShapeSizes(stringLength)

    fontSize = 10;
    switch (stringLength)
        case 1
            shapeSize=10;
        case 2
            shapeSize=15;
        case 3
            shapeSize=18;
        otherwise
            shapeSize=26;
            fontSize = 9;
    end
end