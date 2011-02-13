///////////////////////////////////////////////////////////////////////////////
// Configuration Information
///////////////////////////////////////////////////////////////////////////////
#define MAX_STRAND_LEN 4	// Should be the ACTUAL LENGTH OF LONGEST STRAND - electrical max is 62
#define STRAND_COUNT 2		// Needs to be ACTUAL NUMBER OF DATA LINES IN USE
#define IMG_WIDTH 4
#define IMG_HEIGHT 2
///////////////////////////////////////////////////////////////////////////////
#include "rv.h"

#define conf4x2 1
strand strands[]={
// len, pin, {x-coords}{y-coords}
    { 4, 22, {0,1,2,3}, {0,0,0,0}},		// i.e. on strand #0 / pin 22, there are 4 LEDs @0,0 1,0 2,0 3,0 ...
    { 4, 36, {0,1,2,3}, {1,1,1,1}}
};
