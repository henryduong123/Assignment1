// Threader does not handle destroying params correctly
// Keep params until after the run call and destroy yourself

#ifndef THREADER_H
#define THREADER_H

#include <Windows.h>
#include <queue>

class Threader
{
private:
	struct ThreadInfo
	{
		LPTHREAD_START_ROUTINE functionPtr;
		void* parameters;
	};
	DWORD maxThreads;
	double percentCPU;
	int runningThreads;
	std::queue<ThreadInfo> parameterQueue;
	void** runningParams;
	HANDLE* hTreadArray;
	DWORD* dwThreadIDArray;
	std::string errMsg;
public:
	Threader()
	{
		SYSTEM_INFO sysinfo;
		GetSystemInfo( &sysinfo );
		maxThreads = sysinfo.dwNumberOfProcessors;
		runningParams = new void*[maxThreads];
		runningThreads = 0;
		dwThreadIDArray = new DWORD[maxThreads];
		hTreadArray = new HANDLE[maxThreads];
	}

	Threader(const int maxThreads)
	{
		this->maxThreads = maxThreads;
		runningThreads = 0;
		runningParams = new void*[maxThreads];
		dwThreadIDArray = new DWORD[maxThreads];
		hTreadArray = new HANDLE[maxThreads];
	}

	Threader(const double percent)
	{
		SYSTEM_INFO sysinfo;
		GetSystemInfo( &sysinfo );
		maxThreads = (int)std::max<double>(1.0,floor(sysinfo.dwNumberOfProcessors * percent));
		runningParams = new void*[maxThreads];
		runningThreads = 0;
		dwThreadIDArray = new DWORD[maxThreads];
		hTreadArray = new HANDLE[maxThreads];
	}

	~Threader()
	{
		if (runningThreads!=0)
		{
			;//close all remaining threads
		}
		delete[] runningParams;
		delete[] hTreadArray;
		delete[] dwThreadIDArray;
	}

	template<class T>
	void add(LPTHREAD_START_ROUTINE function, T* param)
	{
		ThreadInfo info;
		info.functionPtr = function;
		info.parameters = param;

		parameterQueue.push(info);
	}

	DWORD WINAPI run()
	{
		DWORD status = fillThreads();
		if (status!=0)
			return status;

		//Wait for a thread to finish and then start the next one
		while (!parameterQueue.empty())
		{
			DWORD doneThread = WaitForMultipleObjects(
				runningThreads,
				hTreadArray,
				FALSE,
				INFINITE);

			doneThread = doneThread - WAIT_OBJECT_0;

			if (doneThread>=maxThreads)
			{
				char* message;
				FormatMessageA(
					FORMAT_MESSAGE_ALLOCATE_BUFFER|FORMAT_MESSAGE_FROM_SYSTEM,
					NULL,
					GetLastError(),
					0,
					(LPSTR)&message,
					10,
					NULL);
				errMsg = message;
				//TODO wait for any current threads and close them
				return 1;
			}

			CloseHandle(hTreadArray[doneThread]);

			ThreadInfo curInfo = parameterQueue.front();
			parameterQueue.pop();
			hTreadArray[doneThread] = CreateThread(
				NULL,
				0,
				curInfo.functionPtr,
				curInfo.parameters,
				FALSE,
				&dwThreadIDArray[doneThread]);

			if (hTreadArray[doneThread] == NULL)
			{
				char buffer[255];
				sprintf_s(buffer,"CreateThread error: %d\n", GetLastError());
				errMsg = buffer;
				// TODO wait for any current threads and close them
				return 1;
			}
		}

		WaitForMultipleObjects(
			runningThreads,
			hTreadArray,
			TRUE,
			INFINITE);

		for (int i=0; i<runningThreads; ++i)
			CloseHandle(hTreadArray[i]);
			
		return 0;
	}



private:
	DWORD WINAPI fillThreads()
	{
		//Start up to maxThreads threads
		for (unsigned int i=0; i<maxThreads && !parameterQueue.empty(); ++i)
		{
			ThreadInfo curInfo = parameterQueue.front();
			parameterQueue.pop();
			hTreadArray[i] = CreateThread(
				NULL,
				0,
				curInfo.functionPtr,
				curInfo.parameters,
				FALSE,
				&dwThreadIDArray[i]);
			if (hTreadArray[i] == NULL)
			{
				char buffer[255];
				sprintf_s(buffer,"CreateThread error: %d\n", GetLastError());
				errMsg = buffer;
				// TODO wait for any current threads and close them
				return 1;
			}
			++runningThreads;
			runningParams[i] = curInfo.parameters;
		}

		return 0;
	}
};

#endif