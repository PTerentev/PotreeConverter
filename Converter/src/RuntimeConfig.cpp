#include "RuntimeConfig.h"
#include "Monitor.h"

namespace RuntimeConfig
{

	int MaxThreadCount = getCpuData().numProcessors;
	int64_t MaxBatchSize = 100'000;
	int64_t MaxPointsPerChunk = 500'000;
	int GridSize = 128;
	int IndexSize = 5000;

}
