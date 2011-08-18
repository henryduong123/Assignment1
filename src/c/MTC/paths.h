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
//***********************************************************************

#include <vector>
#include <list>
#include <map>

typedef std::numeric_limits<double> dbltype;

class CSourcePath
{
public:
	CSourcePath()
	{
		trackletID = -1;
		cost = dbltype::infinity();
	}

	void PushPoint(int t, int idx)
	{
		frame.push_back(t);
		index.push_back(idx);
	}

	void PopPoint()
	{
		if ( frame.size() <= 1 )
			return;

		frame.pop_back();
		index.pop_back();
	}

public:

	int trackletID;
	double cost;

	std::vector<int> frame;
	std::vector<int> index;

};

int GetGlobalIdx(int t, int idx);
int GetLocalIdx(int globalIdx);
void BuildBestPaths(std::map<int,int>& bestOutEdges, int t, int occlLookcback = 0);
