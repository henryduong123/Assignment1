//******************************************************
//
//    This file is part of LEVer.exe
//    (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
//
//******************************************************

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
int gdestGIdx;
int main(int argc, char* argv[])
{
	system("echo %TIME% > ttt.txt");
	int outputargidx = ReadDetectionData(argc, argv);

	if ( outputargidx < 0 )
		return 0;

	CSourcePath** outEdges = new CSourcePath*[gMaxDetections];
	std::vector<CSourcePath*>* inEdges = new std::vector<CSourcePath*>[gMaxDetections];
	
for ( int t=0; t < gNumFrames-1; ++t )
			

//			for ( int t=215; t < gNumFrames-1; ++t )

	{
		ClearEdges(inEdges, outEdges);
		BuildBestPaths(inEdges, outEdges, t);

		//Occlusions
		for ( int iLookback=1; iLookback < 2; ++iLookback )
		{
			BuildBestPaths(inEdges, outEdges, t, iLookback);
		}

		printf("t = %d, %d detections\n", t, rgDetectLengths[t]);

		for ( int destPtIdx=0; destPtIdx < rgDetectLengths[t+1]; ++destPtIdx)
		{
			if ( inEdges[destPtIdx].size() == 0 )
				continue;

			int bestTrackletIdx = FindMinCostIdx(inEdges[destPtIdx]);
			if ( bestTrackletIdx < 0 )
				continue;

			//int ID=GetGlobalIdx(inEdges[destPtIdx][bestTrackletIdx]->frame[1], inEdges[destPtIdx][bestTrackletIdx]->index[1]);
			//if (FindMinCostIn(ID)!=inEdges[destPtIdx][bestTrackletIdx]->cost)
			//	continue;

			int newTrackletID = inEdges[destPtIdx][bestTrackletIdx]->trackletID;

			if ( newTrackletID < 0 )
			{
				//Add new tracklet to list etc. and set id
				newTrackletID = gAssignedTracklets.size();
				inEdges[destPtIdx][bestTrackletIdx]->trackletID = newTrackletID;

				tPathList newList;
				gAssignedTracklets.push_back(newList);
							
				int srcGIdx = GetGlobalIdx(inEdges[destPtIdx][bestTrackletIdx]->frame[0], inEdges[destPtIdx][bestTrackletIdx]->index[0]);
				gAssignedTrackID[srcGIdx] = newTrackletID;
			}

			//Add path to tracklet list
			gAssignedTracklets[newTrackletID].push_back(inEdges[destPtIdx][bestTrackletIdx]);

			//Keep track of assignment for fast lookup
			int srcGIdx = GetGlobalIdx(inEdges[destPtIdx][bestTrackletIdx]->frame[0], inEdges[destPtIdx][bestTrackletIdx]->index[0]);
			int destGIdx = GetGlobalIdx(t+1, destPtIdx);
			gAssignedConnectIn[destGIdx] = srcGIdx;
			gAssignedConnectOut[srcGIdx] = destGIdx;
			gAssignedTrackID[destGIdx] = bestTrackletIdx;
		}
				
		for ( int destPtIdx=0; destPtIdx < rgDetectLengths[t+1]; ++destPtIdx)
		{
			if ( inEdges[destPtIdx].size() != 0 )
				continue;
			
			gdestGIdx = GetGlobalIdx(t+1, destPtIdx);
			//CSourcePath * BestSrc = gConnectIn[gdestGIdx];
		}

	}

	WriteTracklets(argc, argv, 2);

	delete[] outEdges;
	delete[] inEdges;
	system("echo %TIME% >> ttt.txt");

}