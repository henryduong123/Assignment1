#include <windows.h>
#include <fstream>

#include "Helpers.h"

std::string pathCreate(std::string path)
{
	size_t directoryEnd=path.find_first_of("/\\");
	std::string dir = "";

	while (directoryEnd<path.length()+1)
	{
		dir = path.substr(0,directoryEnd);
		if (dir.find_last_of(".")!=std::string::npos  && directoryEnd>=path.length())
			break;

		if (!CreateDirectoryA(dir.c_str(),NULL))
		{
			if (ERROR_PATH_NOT_FOUND==GetLastError())
				return false;
		}

		if (path.length()<=directoryEnd)
			break;

		std::string sub = path.substr(directoryEnd+1,std::string::npos);

		size_t temp = sub.find_first_of("/\\");
		if (temp==std::string::npos && path.length()>directoryEnd)
			directoryEnd = path.length();
		else
			directoryEnd += temp+1;
	}
	dir = path.substr(0,path.find_last_of("/\\"));
	return dir;
}

bool fileExists(const char* filename){
	std::ifstream ifile(filename);
	bool rtn = ifile.good();
	ifile.close();
	return rtn;
}

bool isTiffFile(std::string filePath)
{
	if(!fileExists(filePath.c_str())) return false;

	size_t pos = filePath.find_last_of(".");

	if (pos==std::string::npos) return false;

	std::string	ext = filePath.substr(pos+1,std::string::npos);
	if (_strcmpi(ext.c_str(),"tif")!=0 && _strcmpi(ext.c_str(),"tiff")!=0) return false;

	return true;
}

void unlinkIfExists(const char *filename) {
	if (fileExists(filename))
		if (_unlink(filename) != 0)
			perror(filename);
}
