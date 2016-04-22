////////////////////////////////////////////////////////////////////////////////
//Copyright 2014 Andrew Cohen, Eric Wait, and Mark Winter
//This file is part of LEVER 3-D - the tool for 5-D stem cell segmentation,
//tracking, and lineaging. See http://bioimage.coe.drexel.edu 'software' section
//for details. LEVER 3-D is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by the Free
//Software Foundation, either version 3 of the License, or (at your option) any
//later version.
//LEVER 3-D is distributed in the hope that it will be useful, but WITHOUT ANY
//WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
//A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
//You should have received a copy of the GNU General Public License along with
//LEVer in file "gnu gpl v3.txt".  If not, see  <http://www.gnu.org/licenses/>.
////////////////////////////////////////////////////////////////////////////////

#include "Hull.h"

#include <set>

std::vector<Hull> gHulls;
std::vector<std::set<int>> gHashedHulls;

void Hull::clear()
{
	frame = UNSET_VAR;
	centerOfMass.x = UNSET_VAR;
	centerOfMass.y = UNSET_VAR;
	centerOfMass.z = UNSET_VAR;
	track = UNSET_VAR;
}


Hull::Hull()
{
	clear();
}

Hull::Hull(unsigned int frame)
{
	clear();
	this->frame = frame;
}

Hull::~Hull()
{
	clear();
}


void Hull::setCenterOfMass(double* com)
{
	centerOfMass.x = com[0];
	centerOfMass.y = com[1];
	centerOfMass.z = com[2];
}


void Hull::setFrame(unsigned int frame)
{
	this->frame = frame;
}