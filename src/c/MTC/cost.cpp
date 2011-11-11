//***********************************************************************
//
//    Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
// 
//    This file is part of LEVer - the tool for stem cell lineaging. See
//    https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
// 
//    LEVer is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
// 
//    LEVer is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the//    GNU General Public License for more details.
// 
//    You should have received a copy of the GNU General Public License
//    along with LEVer in file "gnu gpl v3.txt".  If not, see 
//    <http://www.gnu.org/licenses/>.
//
//
//***********************************************************************

#include "tracker.h"


#undef max
#undef min

// Convenience defines
#define SQR(x) ((x)*(x))
#define DOT(x1,y1,x2,y2) ((x1)*(x2) + (y1)*(y2))
#define LENGTH(x,y) (sqrt((SQR(x))+(SQR(y))))
#define SIGN(x) (((x) >= 0.0) ? (1.0) : (-1.0) )

const double costEpsilon = 1e-3;

#define VMAX 80.0
#define CCMAX 40.0

double CCDist(int t0,int i0,int t1,int i1)
{
	int i;
	int nHull1;

	nHull1=GetGlobalIdx(t1, i1);

	for (i=0;i<rgDetect[t0][i0].nConnectedHulls;i++)
	{
		if (rgDetect[t0][i0].DarkConnectedHulls[i]==nHull1)
			// connected!
			return rgDetect[t0][i0].DarkConnectedCost[i];
	}
	return CCMAX+1.;


} // CCDist

double HullDist(int t0,int i0,int t1,int i1)
{
	double dx,dy,d;
	
	d=(SQR(rgDetect[t0][i0].X-rgDetect[t1][i1].X) + SQR(rgDetect[t0][i0].Y-rgDetect[t1][i1].Y));
				
	return sqrt(d);
} // HullDist

double CCHullDist(int t0,int i0,int t1,int i1,double vmax,double ccmax)
{
	double hd,sd;
	double nmax,nmin,cd;
	int nHull0,nHull1;
	//
	nHull0=GetGlobalIdx(t0, i0);
	nHull1=GetGlobalIdx(t1, i1);

	hd=HullDist(t0,i0,t1,i1);
	if (hd>vmax)
		return dbltype::infinity();

	nmax=std::max<double>(rgDetect[t0][i0].nPixels, rgDetect[t1][i1].nPixels);
	nmin=std::min<double>(rgDetect[t0][i0].nPixels, rgDetect[t1][i1].nPixels);

	cd=CCDist(t0,i0,t1,i1);
	if (cd>ccmax )
		return dbltype::infinity();

	if ((cd>ccmax ) && (hd>vmax/2.))
		return dbltype::infinity();
		
	sd = (nmax-nmin)/nmax;

	return (10*hd+100.*sd+1000.*cd);

} // CCHullDist

int GetDestinyNode(int nSourceGIdx,int nOffset,int tOffset)
{
	// Find the assigned in-edge
	int histIndex2 = -1;

	int histIdx = gAssignedConnectIn[nSourceGIdx];
	if ( histIdx >=0 )
	{
		CSourcePath* histpath = gConnectIn[nSourceGIdx][histIdx];
		if ( (histpath->frame.size() > nOffset)  && (histpath->frame[nOffset] == tOffset) )
			histIndex2 = histpath->index[nOffset];
	}

	return histIndex2;
} // GetDestinyNode

double GetCost(std::vector<int>& frame, std::vector<int>& index, int srcFrameIdx, int bCheck)
{
	const double intensityCostWeight = 1.0;
	double velo_max= VMAX,cc_max=CCMAX;
	double LocalCost = 0.0;
	double OcclusionCost=1.;
	double DestinyCost=1.;
	double TotalCost = 0.0;
	double localLinearCost = 0.0;
	double dlcd,dccd;
	double LocationCost = 0.0; 
	double dlocnX,dlocnY;
	int k;
	int startIdx;
	int ptLoc[3][2];
	int srcGIdx;
	
	int nHull0,nHull1;
	//
	nHull0=GetGlobalIdx(frame[srcFrameIdx], index[srcFrameIdx]);
	nHull1=GetGlobalIdx(frame[srcFrameIdx+1], index[srcFrameIdx+1]);

	if ( frame.size() < 2 )
	{
		return dbltype::infinity();
	}
	
	if (bCheck)
		startIdx=frame.size()-2;
	else
	{				
		int tStart;
			
		tStart=frame[srcFrameIdx]-gWindowSize+1;
		tStart=std::max<double>(0., tStart);
		startIdx=srcFrameIdx;
		while ((frame[startIdx]>tStart) && (startIdx>0))
			startIdx--;
		
	}

	for (  k=startIdx; k < frame.size()-1; ++k )
	{
		dlcd=HullDist(frame[k],index[k],frame[k+1],index[k+1]);
		if (dlcd > velo_max)										
			return dbltype::infinity();

		OcclusionCost+=frame[k+1]-frame[k]-1;
	}
	
	if (bCheck)
		return 1.;

	LocalCost=3*CCHullDist(frame[srcFrameIdx],index[srcFrameIdx],frame[srcFrameIdx+1],index[srcFrameIdx+1],velo_max,cc_max);
		
	if ( LocalCost == dbltype::infinity() )			
		return dbltype::infinity();

	if (srcFrameIdx>0)
		LocalCost+=CCHullDist(frame[srcFrameIdx-1],index[srcFrameIdx-1],frame[srcFrameIdx+1],index[srcFrameIdx+1], 2*velo_max, 2*cc_max);
	else
		LocalCost*=2;
	
	if ( LocalCost == dbltype::infinity() )			
		return dbltype::infinity();
	
	if ((srcFrameIdx<frame.size()-2))
		LocalCost+=CCHullDist(frame[srcFrameIdx],index[srcFrameIdx],frame[srcFrameIdx+2],index[srcFrameIdx+2], 2*velo_max, 2*cc_max);
	else
		LocalCost*=2;
	
	if ( LocalCost == dbltype::infinity() )
			return dbltype::infinity();

	int nDestiny2,nDestiny3;
	
	if (srcFrameIdx>0 && frame.size()>srcFrameIdx+2)	
	{

		srcGIdx = GetGlobalIdx(frame[srcFrameIdx], index[srcFrameIdx]);
		nDestiny2=GetDestinyNode(srcGIdx,2,frame[srcFrameIdx+1]);
		if (nDestiny2==index[srcFrameIdx+1]) 
			LocalCost*=0.5;
	}

	dlocnX=double(rgDetect[frame[srcFrameIdx]][index[srcFrameIdx]].X);
	dlocnY=double(rgDetect[frame[srcFrameIdx]][index[srcFrameIdx]].Y);
	for (  k=startIdx; k < srcFrameIdx; ++k )	
	{ 
		dlocnX+=double(rgDetect[frame[k]][index[k]].X);
		dlocnY+=double(rgDetect[frame[k]][index[k]].Y);
	}
	dlocnX/=(srcFrameIdx-startIdx+1);
	dlocnY/=(srcFrameIdx-startIdx+1);
	for (  k=srcFrameIdx; k < frame.size(); ++k )
	{
		LocationCost+=SQR(double(rgDetect[frame[k]][index[k]].X)-dlocnX)+SQR(double(rgDetect[frame[k]][index[k]].Y)-dlocnY);
	}
	LocationCost/=(frame.size()-srcFrameIdx);
	LocationCost=sqrt(LocationCost);

	TotalCost = LocalCost + LocationCost; // + localLinearCost;
	if (frame.size()<2*gWindowSize+1)
	{
		double LengthPenalty;
		LengthPenalty=(2*gWindowSize+1)-frame.size();
		TotalCost = TotalCost*2*LengthPenalty; 
	}

	if (OcclusionCost>1)
		OcclusionCost*=2;
	TotalCost*=OcclusionCost;


	return TotalCost;
}