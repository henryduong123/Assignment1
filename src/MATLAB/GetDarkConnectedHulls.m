% GetDarkConnectedHulls.m - Calculate connected-component distance from
% segmentation results.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function objsSegment = GetDarkConnectedHulls(objsSegment)


global CONSTANTS

th=max([objsSegment.t]);

fname=[CONSTANTS.rootImageFolder '\' CONSTANTS.datasetName '_t' SignificantDigits(1) '.TIF'];
[im map]=imread(fname);
HashedHulls=cell(th,1);

for n=1:length(objsSegment)
    objsSegment(n).imSize=size(im);
    objsSegment(n).DarkConnectedHulls=[];
    [r c]=ind2sub(objsSegment(n).imSize,objsSegment(n).indPixels);
    objsSegment(n).COM=mean([r c],1);
    HashedHulls{objsSegment(n).t}=[HashedHulls{objsSegment(n).t};n];
end

for t=1:th-1
    
    if mod(t,20)==0
        fprintf(1,[num2str(t) ', ']);
    end
    if mod(t,200)==0
        fprintf(1,'\n');
    end
    
    
    objsSegment=GetDistances(objsSegment,HashedHulls,t,t+1);
    if t<th-1
        objsSegment=GetDistances(objsSegment,HashedHulls,t,t+2);
    end
end


    function objsSegment=GetDistances(objsSegment,HashedHulls,t1,t2)
        for i=1:length(HashedHulls{t1})
            hi=HashedHulls{t1}(i);
            ipix=objsSegment(hi).indPixels;
            for j=1:length(HashedHulls{t2})
                hj=HashedHulls{t2}(j);
                dCOM=norm(objsSegment(hi).COM-objsSegment(hj).COM);
                if dCOM>(t2-t1)*CONSTANTS.dMaxCenterOfMass
                    continue
                end
                jpix=objsSegment(hj).indPixels;
                isect = intersect(ipix,jpix);
                if ~isempty(isect)
                    isectDist = 1 - (length(isect) / min(length(ipix), length(jpix)));
                    objsSegment(hi).DarkConnectedHulls=[objsSegment(hi).DarkConnectedHulls; hj isectDist];
                else
                    if length(ipix)<length(jpix)  % p1 smaller
                        p1=ipix;
                        p2=jpix;
                    else
                        p1=jpix;
                        p2=ipix;
                    end
                    [r1 c1]=ind2sub(objsSegment(hi).imSize,p1);
                    [r2 c2]=ind2sub(objsSegment(hj).imSize,p2);
                    dCCmin=Inf;
                    for k=1:length(r1)
                        dd=( (r2-r1(k)).^2+(c2-c1(k)).^2);
                        d=sqrt(min(dd));
                        if d<dCCmin
                            dCCmin=d;
                        end
                        if d<1
                            break
                        end
                    end
                    if 1==t2-t1
                        dmax=CONSTANTS.dMaxConnectComponent;
                    else
                        dmax=1.5*CONSTANTS.dMaxConnectComponent;
                    end
                    if dCCmin<dmax
                        objsSegment(hi).DarkConnectedHulls=[objsSegment(hi).DarkConnectedHulls; hj dCCmin];
                    end
                end
            end
        end
    end


    function bwHalo=GetHalo(t)
        
        fname=[CONSTANTS.rootImageFolder '\' CONSTANTS.datasetName '_t' SignificantDigits(t) '.TIF'];
        [im map]=imread(fname);
        im=mat2gray(im);
        
        
        level=CONSTANTS.imageAlpha*graythresh(im);
        bwHalo=im2bw(im,level);
    end

    function bwCombo=GetCombo(bwHalo1,bwHalo2,objsSegment,HashedHulls,t1,t2)
        
        bwCombo=0*bwHalo1;
        for i=1:length(HashedHulls{t1})
            bwCombo(objsSegment(HashedHulls{t1}(i)).indTailPixels)=1;
        end
        for i=1:length(HashedHulls{t2})
            bwCombo(objsSegment(HashedHulls{t2}(i)).indTailPixels)=1;
        end
        bwCombo(bwHalo1)=0;
        bwCombo(bwHalo2)=0;
    end
end