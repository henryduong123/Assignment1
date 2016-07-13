/***********************************************************************
*     Copyright 2011-2016 Drexel University
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
***********************************************************************/
#ifndef _TRACKER_H_
#define _TRACKER_H_

#include <list>
#include <vector>

#include "cost.h"
#include "paths.h"

//For quick edge lookup from point (like inID/outID)
extern int* gAssignedConnectOut;
extern int* gAssignedConnectIn;

//Global variables
extern int gWindowSize;

extern double gVMax;
extern double gCCMax;

typedef std::list<CSourcePath*> tPathList;
extern std::vector<tPathList> gAssignedTracklets;

//main tracker function:
void trackHulls(unsigned int numFrames);

void destroyTrackStructures();

class TrackerData
{
public:
	TrackerData();
	~TrackerData();

	//savers
	void clear();

	double getDistance(int hull1, int hull2, double ccMax);
	void setCCdistMap(std::map<int,double>* cCDistMap);

	//member variables
	std::map<int,CSourcePath*>* connectOut;
	std::map<int,CSourcePath*>* connectIn;
	std::map<int,double>* ccDistMap;
};

extern TrackerData gTrackerData;

#endif //_TRACKER_H_