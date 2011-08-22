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

	
int gnumPts;

int ReadSegmentationData(char* filename, int* numTotalPts, SDetection*** rgDetect, int** detectLengths, int** detectLengthSum)
{
	int numFrames;
	int numPts;

	int* lengthPtr;
	int* lengthSumPtr;
	SDetection* dataPtr;
	SDetection** arrayIdxPtr;
	int nDCH;
	double dDCH;
	FILE* fp;

	fp = fopen(filename, "r");
	if ( !fp )
		return -1;

	fscanf(fp, "%d %d\n\n", &numFrames, &numPts);

	dataPtr = new SDetection[numPts];
	arrayIdxPtr = new SDetection*[numFrames];
	lengthPtr = new int[numFrames];
	lengthSumPtr = new int[numFrames];

	int frameOffset = 0;
	for ( int t=0; t < numFrames; ++t )
	{
		int frameDetections;
		fscanf(fp, "%d\n", &frameDetections);

		lengthPtr[t] = frameDetections;
		if ( t > 0 )
			lengthSumPtr[t] = lengthSumPtr[t-1] + lengthPtr[t-1];
		else
			lengthSumPtr[t] = 0;

		arrayIdxPtr[t] = dataPtr + frameOffset;

		for ( int ptItr = 0; ptItr < frameDetections; ++ptItr )
		{
			SDetection* curPt = &arrayIdxPtr[t][ptItr];
			fscanf(fp, "%d %d %d %d:", &(curPt->X), &(curPt->Y),&(curPt->nPixels),&(curPt->nConnectedHulls));

			for ( int pixItr = 0; pixItr < curPt->nConnectedHulls; ++pixItr )
			{
				fscanf(fp, " %d,%lf", &(nDCH),&(dDCH));
				nDCH--; //Make 0 offset
				curPt->DarkConnectedHulls.push_back(nDCH);
				curPt->DarkConnectedCost.push_back(dDCH);
			}

			fscanf(fp,"\n");
		}

		frameOffset += frameDetections;
	}

	fclose(fp);

	(*numTotalPts) = numPts;
	(*rgDetect) = arrayIdxPtr;
	(*detectLengths) = lengthPtr;
	(*detectLengthSum) = lengthSumPtr;

	return numFrames;
}


void DeleteDetections()
{
	delete[] rgDetect[0];
	delete[] rgDetect;

	delete[] rgDetectLengths;
	delete[] rgDetectLengthSum;
}

int ReadDetectionData(int argc, char* argv[])
{

	int checkResult;

	checkResult = ReadSegmentationData(argv[1], &gnumPts, &rgDetect, &rgDetectLengths, &rgDetectLengthSum);
	if ( checkResult < 0 )
		return -1;

	gNumFrames = checkResult;

	gMaxDetections = 0;
	for ( int t=0; t < gNumFrames; ++t )
		gMaxDetections = std::max<int>(gMaxDetections, rgDetectLengths[t]);



	gConnectOut = new std::map<int,CSourcePath*>[gnumPts];
	gConnectIn = new std::map<int,CSourcePath*>[gnumPts];
	gAssignedConnectIn = new int[gnumPts];
	gAssignedConnectOut = new int[gnumPts];
	gAssignedTrackID = new int[gnumPts];
	for ( int i=0; i < gnumPts; ++i )
	{
		gAssignedConnectIn[i] = -1;
		gAssignedConnectOut[i] = -1;
		gAssignedTrackID[i] = -1;
	}

	return 3;
}
