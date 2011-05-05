%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [dTotal dSize] = HullDist(hulls, h1, h2, dmax_CC, dmax_COM)
    global CONSTANTS
    
    pix1=hulls(h1).indexPixels;
    pix2=hulls(h2).indexPixels;
    if length(pix2)<length(pix1)
        temp=pix2;
        pix2=pix1;
        pix1=temp;
    end
    [r1 c1]=ind2sub(CONSTANTS.imageSize,pix1);
    [r2 c2]=ind2sub(CONSTANTS.imageSize,pix2);
    dCCmin=Inf;
    for i=1:length(r1)
        dd=( (r2-r1(i)).^2+(c2-c1(i)).^2);
        d=sqrt(min(dd));
        if d<dCCmin
            dCCmin=d;
        end
    end

    com1=mean([r1 c1],1);
    com2=mean([r2 c2],1);
    dCOM=sqrt( (com1(1)-com2(1))^2 + (com1(2)-com2(2))^2);

    b1=mean(hulls(h1).imagePixels);
    b2=mean(hulls(h2).imagePixels);

    dBrightness=( max(b1,b2) - min(b1,b2) ) / max(b1,b2);
    l1=length(pix1);
    l2=length(pix2);

    dSize=(max(l1,l2)-min(l1,l2))/max(l1,l2);
    if dCOM>dmax_COM || dCCmin>dmax_CC
        dTotal= Inf;
    else
        dTotal= 0.5*dCOM + 1000*dCCmin + 20*dSize + dBrightness;
    %     dTotal= dCOM + dCCmin;
    end
end

