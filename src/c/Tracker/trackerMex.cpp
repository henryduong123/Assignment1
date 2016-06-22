/***********************************************************************
*     Copyright 2011-2016 Andrew Cohen
*
*     This file is part of LEVer - the tool for stem cell lineaging. See
*     http://n2t.net/ark:/87918/d9rp4t for details
* 
*     LEVer is free software: you can redistribute it and/or modify
*     it under the terms of the GNU General Public License as published by
*     the Free Software Foundation, either version 3 of the License, or
*     (at your option) any later version.
* 
*     LEVer is distributed in the hope that it will be useful,
*     but WITHOUT ANY WARRANTY; without even the implied warranty of
*     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*     GNU General Public License for more details.
* 
*     You should have received a copy of the GNU General Public License
*     along with LEVer in file "gnu gpl v3.txt".  If not, see 
*     <http://www.gnu.org/licenses/>.
*
***********************************************************************/#include "mex.h"

#include "tracker.h"
#include "Hull.h"

void loadHulls( const mxArray * hulls, int numFrames ) 
{
	int numHulls = mxGetNumberOfElements(hulls);

	gHulls.clear();
	gHulls.resize(numHulls);
	gHashedHulls.clear();
	gHashedHulls.resize(numFrames);

	for(int hullIdx=0; hullIdx<numHulls; ++hullIdx)
	{
		Hull& hull = gHulls[hullIdx];
		mxArray* framePtr = mxGetField(hulls,hullIdx,"time");
		if (framePtr==NULL) mexErrMsgTxt("Missing Time!\n");
		hull.setFrame(MatToC((unsigned int)mxGetScalar(framePtr)));

		mxArray* comPtr = mxGetField(hulls,hullIdx,"centerOfMass");
		if (comPtr==NULL) mexErrMsgTxt("Missing Center of Mass!\n");
		hull.setCenterOfMass((double*)mxGetData(comPtr));

		mxArray* pixelPtr = mxGetField(hulls,hullIdx,"indexPixels");
		if (pixelPtr==NULL) mexErrMsgTxt("Missing pixels!\n");

		size_t numPixels = mxGetM(pixelPtr);
		hull.setNumPixels(numPixels);

		gHashedHulls[hull.getFrame()].insert(hullIdx);
	}
}

void returnHulls(mxArray* plhs[])
{

	plhs[0] = mxCreateNumericMatrix(1, gHulls.size(), mxDOUBLE_CLASS, mxREAL);
	double* trackList = (double*)mxGetData(plhs[0]);
	int numEdges = 0;

	for(int i=0; i<gHulls.size(); ++i)
	{
		trackList[i] = gHulls[i].getTrack();
		numEdges += gTrackerData.connectOut[i].size();
	}

	mxArray* sparseArray = mxCreateSparse(gHulls.size(), gHulls.size(),numEdges,mxREAL);
	mwIndex* mxjc = mxGetJc(sparseArray);
	mwIndex* mxir = mxGetIr(sparseArray);
	double* mxpr = mxGetPr(sparseArray);

	mxjc[0] = 0;

	std::map<int,CSourcePath*>* inEdges;
	for (int i=0; i<gHulls.size(); ++i)
	{
		inEdges = &gTrackerData.connectIn[i];
		mxjc[i+1] = mxjc[i]+inEdges->size();
		std::map<int,CSourcePath*>::iterator it = inEdges->begin();
		for (int j=0; j<inEdges->size(); ++j, ++it)
		{
			mxir[mxjc[i]+j] = it->first;
			mxpr[mxjc[i]+j] = it->second->cost;
		}
	}

	plhs[1] = sparseArray;
}

void loadDists(const mxArray* ccDists)
{
	std::map<int, double>* ccDistMap = new std::map<int, double>[gHulls.size()];

	size_t numHulls = mxGetN(ccDists);
	for (int i = 0; i < numHulls ; ++i)
	{
		mxArray* nextHulls = mxGetCell(ccDists, i);
		size_t m = mxGetM(nextHulls);
		
		double* distPairs = (double*)mxGetData(nextHulls);

		for (int j = 0; j < m ; j++)
		{
			int nextHull = (int)(distPairs[j*2]);
			double dist = distPairs[j*2+1];

			ccDistMap[i].insert(std::pair<int, double>(nextHull,dist));
		}
	}

	gTrackerData.ccDistMap = ccDistMap;
}

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if (nrhs!=5) mexErrMsgTxt("Usage: hulls, CCdists, numFrames, velocity, ccMaxDist\n");
	if (nlhs!=2) mexErrMsgTxt("Incorrect number of output arguments!\n");

	int numFrames = mxGetScalar(prhs[2]);
	const mxArray* hulls = prhs[0];
	if (hulls==NULL) mexErrMsgTxt("No hulls passed as the second argument!\n");

	gVMax = mxGetScalar(prhs[3]);
	gCCMax = mxGetScalar(prhs[4]);

	const mxArray* ccDists = prhs[1];
	
	loadHulls(hulls,numFrames);
	loadDists(ccDists);
	trackHulls(numFrames);
	returnHulls(plhs);

	destroyTrackStructures();
}