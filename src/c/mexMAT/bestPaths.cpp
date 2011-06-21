//******************************************************
//
//    This file is part of LEVer.exe
//    (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
//
//******************************************************

#include "mexMAT.h"

std::vector<CSourcePath> gTrackHistory;

// Find all trackIDs from source hullIDs
void buildStartTrackList(std::vector<int>& trackIdx, int t, int numTracks)
{
	mxArray* frmHulls = mxGetCell(gHashHulls,MATLAB_IDX(t));
	int numFrmHulls = mxGetNumberOfElements(frmHulls);

	int foundTracks = 0;

	double* startHulls = (double*) mxGetData(mxGetCell(gTrackHulls, C_IDX(0)));
	for ( int i=0; i < numFrmHulls; ++i )
	{
		double frmHullIdx = mxGetScalar(mxGetField(frmHulls, C_IDX(i), "hullID"));
		for ( int j=0; j < numTracks; ++j )
		{
			if ( startHulls[j] == frmHullIdx )
			{
				// Get track ID from hull ID
				trackIdx[j] = (int) mxGetScalar(mxGetField(frmHulls, C_IDX(i), "trackID"));
				++foundTracks;
				break;
			}
		}

		if ( foundTracks == numTracks )
			break;
	}
}

void buildTrackHistory(int dir, int numTracks)
{
	int firstHull = (int)(((double*) mxGetData(mxGetCell(gTrackHulls, C_IDX(0))))[0]);
	int t = (int) mxGetScalar(mxGetField(gCellHulls, MATLAB_IDX(firstHull), "time"));
	std::vector<int> startTrackList(numTracks);
	buildStartTrackList(startTrackList, t, numTracks);

	gTrackHistory.resize(numTracks);
	for ( int i=0; i < numTracks; ++i )
	{
		double* hullsData = (double*) mxGetData(mxGetField(gCellTracks, MATLAB_IDX(startTrackList[i]), "hulls"));
		int trackStart = (int) mxGetScalar(mxGetField(gCellTracks, MATLAB_IDX(startTrackList[i]), "startTime"));
		int trackLen = (int) mxGetNumberOfElements(mxGetField(gCellTracks, MATLAB_IDX(startTrackList[i]), "hulls"));
		int trkt = t - trackStart;

		int histt = std::max<int>(0, trkt-gWindowSize-1);
		if ( dir < 0 )
			histt = std::min<int>(trackLen-1, trkt+gWindowSize+1);

		gTrackHistory[i].clear();
		gTrackHistory[i].reserve(2*gWindowSize+1);

		for ( int j=histt; j != trkt; j += dir )
		{
			if ( hullsData[j] == 0.0 )
			{
				gTrackHistory[i].clear();
				continue;
			}

			gTrackHistory[i].pushPoint((int) hullsData[j]);
		}

		gTrackHistory[i].setAsHistory();
	}
}

int addBestPath(CSourcePath& path, int bestNextHull)
{
	if ( (path.path.size() - path.sourceIdx) <= 1 )
		return bestNextHull;

	// Calculate full cost including history
	double newPathCost = getCost(path.path, path.sourceIdx, 0);
	if ( newPathCost == DoubleLims::infinity() )
		return bestNextHull;

	path.cost = newPathCost;

	int sourceHull = path.path[path.sourceIdx];
	int nextHull = path.path[path.sourceIdx+1];

	double* edgePtr = gConnectPtr->getPtr(sourceHull, nextHull);
	if ( edgePtr == NULL )
		mexErrMsgTxt("Attempt to access invalid subgraph entry.");

	if ( (*edgePtr) == 0.0 || newPathCost < (*edgePtr) )
		*edgePtr = newPathCost;

	if ( bestNextHull < 0 )
		bestNextHull = nextHull;

	double* bestPtr = gConnectPtr->getPtr(sourceHull, bestNextHull);
	if ( newPathCost < (*bestPtr) )
		bestNextHull = nextHull;

	return bestNextHull;
}

// Depth-first path search
int bestPathDFS(int t, int tEnd, CSourcePath path, int bestNextHull)
{
	bool bFinishedSearch = true;

	if ( t < tEnd )
	{
		int thIdx = t;
		mxArray* hulls = mxGetCell(gTrackHulls, C_IDX(thIdx));

		int numHulls = mxGetNumberOfElements(hulls);
		double* pHulls = (double*) mxGetData(hulls);

		for ( int i=0; i < numHulls; ++i )
		{
			int nextHull = (int) pHulls[i];

			path.pushPoint(nextHull);
			double chkCost = getCost(path.path, path.sourceIdx, 0);
			path.popPoint();

			if ( chkCost == DoubleLims::infinity() )
				continue;

			bFinishedSearch = false;

			//if ( CheckLeavesExtents(path.frame, path.index, 0) )
			//{
			//	bestGIdx = AddBestPath(path, bestGIdx);
			//}

			path.pushPoint(nextHull);

			bestNextHull = bestPathDFS(t+1, tEnd, path, bestNextHull);
			path.popPoint();
		}
	}

	if ( bFinishedSearch )
	{
		bestNextHull = addBestPath(path, bestNextHull);
	}

	return bestNextHull;
}

void buildBestPaths(int dir, int numTracks)
{
	buildTrackHistory(dir, numTracks);

	int tEnd = std::min<int>(gConstraintFrames, gWindowSize);

	double* frmData = (double*) mxGetData(mxGetCell(gTrackHulls, C_IDX(0)));
	for ( int srcIdx=0; srcIdx < numTracks; ++srcIdx )
	{
		CSourcePath path = gTrackHistory[srcIdx];
		path.pushPoint((int) frmData[srcIdx]);

		int bestNextHull = bestPathDFS(1, tEnd, path, -1);
	}
}