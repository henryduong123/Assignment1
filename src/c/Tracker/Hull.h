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
***********************************************************************/#ifndef HULL_H
#define HULL_H

#include "Utility.h"
#include <vector>
#include <set>

typedef Vec<double> PointType;

class Hull
{
public:
	Hull();
	Hull(unsigned int frame);
	~Hull();

	//getters
	unsigned int getFrame(){return frame;}
	Vec<double> getCenterOfMass(){return centerOfMass;}
	size_t getNumberofVoxels(){return numPixels;}
	unsigned int getTrack(){return track;}

	void getColor(double* colorOut);

	//setters
	void setCenterOfMass(double* com);
	void setFrame(unsigned int frame);
	void setTrack(double* label){this->track=*label;}
	void setTrack(int label){this->track=label;}
	void setNumPixels(size_t numPixels) { this->numPixels = numPixels; }

	void clearTrack(){track=UNSET_VAR;}
	void logicallyDelete(unsigned int hull);

private:
	unsigned int frame;
	Vec<double> centerOfMass;
	unsigned int track;
	size_t numPixels;

	void clear();
	void clearBoundingBox();
};

extern std::vector<Hull> gHulls;
extern std::vector<std::set<int>> gHashedHulls;

#endif