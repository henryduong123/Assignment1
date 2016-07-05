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
***********************************************************************/

// Double limits convenience definition
typedef std::numeric_limits<double> DoubleLims;

class CSourcePath
{
public:
	CSourcePath()
	{
		sourceIdx = -1;
		cost = DoubleLims::infinity();
	}

	void pushPoint(int newIdx)
	{
		path.push_back(newIdx);
	}

	void popPoint()
	{
		if ( path.size() <= 1 )
			return;

		path.pop_back();
	}

	void setAsHistory()
	{
		sourceIdx = path.size();
	}

	void reserve(int size)
	{
		path.reserve(size);
	}

	void clear()
	{
		sourceIdx = -1;
		cost = DoubleLims::infinity();
		path.clear();
	}

public:

	int sourceIdx;
	double cost;

	std::vector<int> path;
};

void buildBestPaths(int dir, int numTracks);