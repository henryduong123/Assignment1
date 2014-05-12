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

#include "mexMAT.h"

#include <math.h>

#undef max
#undef min

// Convenience defines
#define SQR(x) ((x)*(x))
#define DOT(x1,y1,x2,y2) ((x1)*(x2) + (y1)*(y2))
#define LENGTH(x,y) (sqrt((SQR(x))+(SQR(y))))
#define SIGN(x) (((x) >= 0.0) ? (1.0) : (-1.0) )

int getCellTime(int hullIdx)
{
	return ((int) mxGetScalar(mxGetField(gCellHulls, MATLAB_IDX(hullIdx), "time")));
}

double calcHullDist(int startCellIdx, int nextCellIdx)
{
	double* startCOMData = (double*) mxGetData(mxGetField(gCellHulls, MATLAB_IDX(startCellIdx), "centerOfMass"));
	double* endCOMData = (double*) mxGetData(mxGetField(gCellHulls, MATLAB_IDX(nextCellIdx), "centerOfMass"));

	return sqrt(SQR(startCOMData[0] - endCOMData[0]) + SQR(startCOMData[1] - endCOMData[1]));
}

double calcCCDist(int startCellIdx, int nextCellIdx)
{
	if ( getCellTime(startCellIdx) > getCellTime(nextCellIdx) )
	{
		int tmp = startCellIdx;
		startCellIdx = nextCellIdx;
		nextCellIdx = tmp;
	}

	mxArray* ccArray = mxGetCell(gCellConnDist, MATLAB_IDX(startCellIdx));

	int M = mxGetM(ccArray);
	double* ccData = (double*) mxGetData(ccArray);

	double ccDist = gCCMax + 1.0;

	for ( int i=0; i < M; ++i )
	{
		if ( ccData[i] != ((double) nextCellIdx) )
			continue;

		ccDist = ccData[M+i];
		break;
	}

	return ccDist;
}

double calcFullCellDist(int startCellIdx, int nextCellIdx, double vmax, double ccmax)
{
	double hdist = calcHullDist(startCellIdx, nextCellIdx);

	if ( hdist > vmax )
		return DoubleLims::infinity();

	int startCellSize = mxGetNumberOfElements(mxGetField(gCellHulls, MATLAB_IDX(startCellIdx), "indexPixels"));
	int nextCellSize = mxGetNumberOfElements(mxGetField(gCellHulls, MATLAB_IDX(nextCellIdx), "indexPixels"));

	int nmax = std::max<int>(startCellSize, nextCellSize);
	int nmin = std::min<int>(startCellSize, nextCellSize);

	double cdist = calcCCDist(startCellIdx, nextCellIdx);
	if ( (cdist > ccmax) && (hdist > (vmax/2.0)) )
		return DoubleLims::infinity();

	double sdist = ((double) (nmax - nmin)) / nmax;

	return (10.0*hdist + 100.0*sdist + 1000.0*cdist);
}

double getCost(std::vector<int>& path, int srcIdx, int bCheck)
{
	double vmax = gVMax;
	double ccmax = gCCMax;

	if ( path.size() - srcIdx <= 1 )
		return DoubleLims::infinity();

	int sourceHull = path[srcIdx];
	int nextHull = path[srcIdx+1];

	int dir = 1;

	int startIdx;
	if ( bCheck )
		startIdx = path.size() - 2;
	else
	{
		dir = (getCellTime(nextHull) - getCellTime(sourceHull) >= 0) ? 1 : -1;

		int tStart = std::max<int>(getCellTime(path[srcIdx]) - gWindowSize + 1, 1);
		int tPathStart = getCellTime(path[0]);
		if ( dir < 0 )
		{
			tStart = std::max<int>(getCellTime(path[srcIdx]) + gWindowSize - 1, 1);
			tPathStart = getCellTime(path[0]);
			startIdx = std::max<int>(tPathStart - tStart, 0);
		}
		else
			startIdx = std::max<int>(tStart - tPathStart, 0);
	}

	for ( int k=startIdx; k < path.size()-1; ++k )
	{
		double dlcd = calcHullDist(path[k], path[k+1]);

		if ( dlcd > vmax && k >= srcIdx )
			return DoubleLims::infinity();
	}

	// Just return non-infinite for a successful check.
	if ( bCheck )
		return 1.0;

	double localCost = 3*calcFullCellDist(path[srcIdx], path[srcIdx+1], vmax, ccmax);

	if ( localCost == DoubleLims::infinity() )
		return DoubleLims::infinity();

	// Calculate local surrounding connected-component distance if possible
	if ( srcIdx > 0 )
		localCost += calcFullCellDist(path[srcIdx-1], path[srcIdx+1], 2*vmax, 2*ccmax);
	else
		localCost *= 2.0;

	if ( localCost == DoubleLims::infinity() )
		return DoubleLims::infinity();

	// Calculate forward cc cost if path is long enough
	if ( srcIdx < path.size()-2 )
		localCost += calcFullCellDist(path[srcIdx], path[srcIdx+2], 2*vmax, 2*ccmax);
	else
		localCost *= 2.0;

	if ( localCost == DoubleLims::infinity() )
		return DoubleLims::infinity();

	//TODO: Destiny agreement

	double dCenterLoc[2] = {0.0, 0.0};

	// Calculate historical center of mass of cell
	for ( int k=startIdx; k <= srcIdx; ++k )
	{
		double* pLocData = (double*) mxGetData(mxGetField(gCellHulls, MATLAB_IDX(path[k]), "centerOfMass"));
		dCenterLoc[0] += pLocData[0];
		dCenterLoc[1] += pLocData[1];
	}
	dCenterLoc[0] /= (srcIdx - startIdx + 1);
	dCenterLoc[1] /= (srcIdx - startIdx + 1);

	// Calculate mean squared deviation of path from historical center
	double locationCost = 0.0;
	for ( int k=srcIdx; k < path.size(); ++k )
	{
		double* pLocData = (double*) mxGetData(mxGetField(gCellHulls, MATLAB_IDX(path[k]), "centerOfMass"));
		locationCost += SQR(pLocData[0] - dCenterLoc[0]) + SQR(pLocData[1] - dCenterLoc[1]);
	}
	locationCost = sqrt(locationCost/(path.size() - srcIdx));

	double totalCost = localCost + locationCost;
	if ( path.size() < 2*gWindowSize+1 )
	{
		double lengthPenalty = (2*gWindowSize+1) - path.size();
		totalCost *= (2*lengthPenalty);
	}

	//TODO: Occlusion cost

	if ( totalCost < gCostEpsilon )
		totalCost = gCostEpsilon;

	return totalCost;
}
