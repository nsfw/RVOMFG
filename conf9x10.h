///////////////////////////////////////////////////////////////////////////////
// Configuration Information
///////////////////////////////////////////////////////////////////////////////
#define MAX_STRAND_LEN 45	// Should be the ACTUAL LENGTH OF LONGEST STRAND - electrical max is 62
#define STRAND_COUNT 2		// Needs to be ACTUAL NUMBER OF DATA LINES IN USE
#define IMG_WIDTH 10
#define IMG_HEIGHT 9
///////////////////////////////////////////////////////////////////////////////
#include "rv.h"

// Two strands on the back half of RV
// 9 ROWS 10 COLS
#define conf9x10 1
strand strands[]={
// len, pin, {x-coords}{y-coords}, initial color
    { 45, 22, 			// 45 leds as 5 columns of 9 LEDs
      {4,4,4,4,4,4,4,4,4,
       3,3,3,3,3,3,3,3,3,
       2,2,2,2,2,2,2,2,2,
       1,1,1,1,1,1,1,1,1,
       0,0,0,0,0,0,0,0,0},
      {0,1,2,3,4,5,6,7,8,
       8,7,6,5,4,3,2,1,0,
       0,1,2,3,4,5,6,7,8,
       8,7,6,5,4,3,2,1,0,
       0,1,2,3,4,5,6,7,8} },
    { 4, 36,
      {5,5,5,5,5,5,5,5,5,
       6,6,6,6,6,6,6,6,6,
       7,7,7,7,7,7,7,7,7,
       8,8,8,8,8,8,8,8,8,
       9,9,9,9,9,9,9,9,9},
      {0,1,2,3,4,5,6,7,8,
       8,7,6,5,4,3,2,1,0,
       0,1,2,3,4,5,6,7,8,
       8,7,6,5,4,3,2,1,0,
       0,1,2,3,4,5,6,7,8} }
};

