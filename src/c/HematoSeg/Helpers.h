#ifndef HELPERS_H
#define HELPERS_H

#include <string>

std::string pathCreate(std::string path);
bool fileExists(const char* filename);
bool isTiffFile(std::string filePath);

#endif