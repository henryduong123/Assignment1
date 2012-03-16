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

//Global variables
int gNumFrames;
int gMaxDetections;
int* rgDetectLengths;
int* rgDetectLengthSum;
SDetection** rgDetect;
std::map<int,CSourcePath*>* gConnectOut;
std::map<int,CSourcePath*>* gConnectIn;
int* gAssignedConnectOut;
int* gAssignedConnectIn;
int* gAssignedTrackID;

std::vector<tPathList> gAssignedTracklets;

int gWindowSize = 4;


void WriteTracklets(int argc, char* argv[], int argIdx)
{

std::map<int,CSourcePath*>::iterator cIter;
	CSourcePath* inPath;
	double dinCost;

	if ( argIdx >= argc )
		return;
	FILE* fPathFile = fopen(argv[argIdx], "w");

	if ( !fPathFile )
		return;

	for ( int i=0; i < gAssignedTracklets.size(); ++i )
	{
		tPathList::iterator trackIter;
		tPathList::iterator lastPathIter = (--gAssignedTracklets[i].end());
		for ( trackIter=gAssignedTracklets[i].begin(); trackIter != gAssignedTracklets[i].end(); ++trackIter )
		{
			fprintf(fPathFile, "%d,%d,%d,%d,%d\n", i+1,(*trackIter)->frame[0] + 1,(*trackIter)->frame[1] + 1,(*trackIter)->index[0] + 1,(*trackIter)->index[1] + 1);
		}
	}
				
	fprintf(fPathFile, "-1,-1,-1,-1,-1\n");
	for ( int i=0; i < gnumPts; ++i )
	{
		cIter = gConnectIn[i].begin();
		for ( int j=0; j < gConnectIn[i].size(); ++j )
		{
			inPath=cIter->second;
			dinCost=inPath->cost;
			if (dinCost!=dinCost) // test for -1.#IND!
				continue;
			fprintf(fPathFile, "%d,%d,%lf\n",i+1,cIter->first+1,dinCost);
			cIter++;

		}
	}

	fclose(fPathFile);
}

void ClearEdges(std::vector<CSourcePath*>* inEdges, CSourcePath** outEdges)
{
	for ( int i=0; i < gMaxDetections; ++i )
	{
		outEdges[i] = NULL;
		inEdges[i].clear();
	}
}

double FindMinCostIn(int ID)
{
	double cmin=dbltype::infinity();
	CSourcePath* inPath;
	std::map<int,CSourcePath*>::iterator cIter;
	
	cIter = gConnectIn[ID].begin();
	for ( int j=0; j < gConnectIn[ID].size(); ++j )
	{
		inPath=cIter->second;
		if (inPath->cost<cmin) 
			cmin=inPath->cost;
		
		cIter++;

	}

	return cmin;
}

int FindMinInEdgeIdx(int nextGIdx)
{
	double cmin = dbltype::infinity();
	int bestIdx = -1;

	std::map<int,CSourcePath*>::iterator cIter = gConnectIn[nextGIdx].begin();
	while ( cIter != gConnectIn[nextGIdx].end() )
	{
		CSourcePath* inPath = cIter->second;
		if ( inPath->cost < cmin )
		{
			cmin = inPath->cost;
			bestIdx = cIter->first;
		}

		++cIter;
	}

	return bestIdx;
}

int FindMinCostIdx(std::vector<CSourcePath*>& edges)
{
	int minidx = -1;
	double mincost = dbltype::infinity();
	for ( int i=0; i < edges.size(); ++i )
	{
		if ( edges[i]->cost < mincost )
		{
			minidx = i;
			mincost = edges[i]->cost;
		}
	}

	return minidx;
}

int main(int argc, char* argv[])
{
	system("echo %TIME% > ttt.txt");
	int outputargidx = ReadDetectionData(argc, argv);

	if ( outputargidx < 0 )
		return 0;

	std::map<int,int> bestOutEdges;

	for ( int t=0; t < gNumFrames-1; ++t )
	{
		bestOutEdges.clear();
		BuildBestPaths(bestOutEdges, t);

		//Occlusions
		for ( int iLookback=1; iLookback < 2; ++iLookback )
		{
			BuildBestPaths(bestOutEdges, t, iLookback);
		}

		printf("t = %d, %d detections\n", t, rgDetectLengths[t]);

		for ( int destPtIdx=0; destPtIdx < rgDetectLengths[t+1]; ++destPtIdx)
		{
			int nextGIdx = GetGlobalIdx(t+1, destPtIdx);
			int bestTrackletIdx = FindMinInEdgeIdx(nextGIdx);
			if ( bestTrackletIdx < 0 )
				continue;

			if ( (bestOutEdges.count(bestTrackletIdx) == 0) || bestOutEdges[bestTrackletIdx] != nextGIdx )
				continue;

			int newTrackletID = gConnectOut[bestTrackletIdx][nextGIdx]->trackletID;

			if ( newTrackletID < 0 )
			{
				//Add new tracklet to list etc. and set id
				newTrackletID = gAssignedTracklets.size();
				gConnectOut[bestTrackletIdx][nextGIdx]->trackletID = newTrackletID;

				tPathList newList;
				gAssignedTracklets.push_back(newList);

				gAssignedTrackID[bestTrackletIdx] = newTrackletID;
			}

			//Add path to tracklet list
			gAssignedTracklets[newTrackletID].push_back(gConnectOut[bestTrackletIdx][nextGIdx]);

			//Keep track of assignment for fast lookup
			gAssignedConnectIn[nextGIdx] = bestTrackletIdx;
			gAssignedConnectOut[bestTrackletIdx] = nextGIdx;
			gAssignedTrackID[nextGIdx] = newTrackletID;
		}
	}

	WriteTracklets(argc, argv, 2);

	system("echo %TIME% >> ttt.txt");

}