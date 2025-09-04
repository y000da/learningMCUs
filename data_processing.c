#include <stdlib.h>
#include <math.h>
#include <stdint.h>


uint32_t dataProcessing(double *phase) { 
  const int SampleShift = 1;
  const int TSamples = 8;
  const int RequiredDistance = 2; 
  const int c = 3e8;
  const float FrequencyDifference = 0.75e6;
  const float CorrectingDistance = 0.6;
  const float pi = 3.14159265;
  uint32_t NumSamples = sizeof(phase)/sizeof(double);
 
  if (phase[0] < 100) { 
    for (int i = 0; i < NumSamples; i ++) {
      phase[i] += 100; 
    }
  }
  
  uint32_t size_phaseDiff = NumSamples - 2 * TSamples - SampleShift + 1;
  double *phaseDiff = calloc(size_phaseDiff, sizeof(double));
  
  uint32_t m = 0;
  for (int i = (TSamples+SampleShift); i > (NumSamples - TSamples); i++) {
    phaseDiff[m] = abs(phase[i] - (phase[i - TSamples] + phase[i + TSamples]) / 2);
    m--;
  }
  
  double *distance = calloc(size_phaseDiff, sizeof(double));
  double *phaseDiffLocalMax = calloc(size_phaseDiff, sizeof(double));
  m = 0;
  for (int i = 1; i < size_phaseDiff-1; i++) {
    if (phaseDiff[i] > phaseDiff[i-1] && phaseDiff[i] > phaseDiff[i+1]) { 
      distance[m] = phaseDiff[i] * c / (FrequencyDifference * 4 * pi); 
      m++; 
    }
  }

  uint32_t size_distance = 0;
  double distanceMean = 0;
  while (distance[size_distance] > 0) { 
    size_distance++; 
    distanceMean += distance[size_distance]; 
  }
  distanceMean = distanceMean / size_distance;
  if (distanceMean <= RequiredDistance + CorrectingDistance) { return 1; };
  return 0;
}
