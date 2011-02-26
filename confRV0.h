///////////////////////////////////////////////////////////////////////////////
// Configuration Information
///////////////////////////////////////////////////////////////////////////////
#define MAX_STRAND_LEN 36	// Should be the ACTUAL LENGTH OF LONGEST STRAND - electrical max is 62
#define STRAND_COUNT 4		// Needs to be ACTUAL NUMBER OF DATA LINES IN USE
#define IMG_WIDTH 13
#define IMG_HEIGHT 9
///////////////////////////////////////////////////////////////////////////////
#include "rv.h"

// Three strands on the back half of RV - upper back corner is 0,0

#define confRV 1
strand strands[]={
// len, pin, {x-coords}{y-coords}, initial color
    { 36, 22, 			// 45 leds as 5 columns of 9 LEDs
      {
          3,3,3,3,3,3,3,3,3,	// strand starts to the FRONT and goes BACKWARDS
          2,2,2,2,2,2,2,2,2,
          1,1,1,1,1,1,1,1,1,
          0,0,0,0,0,0,0,0,0
      },
      {
          0,1,2,3,4,5,6,7,8,
          8,7,6,5,4,3,2,1,0,
          0,1,2,3,4,5,6,7,8,
          8,7,6,5,4,3,2,1,0
      }},
    { 36, 23, 
      {
          7,7,7,7,7,7,7,7,7,
          6,6,6,6,6,6,6,6,6,
          5,5,5,5,5,5,5,5,5,
          4,4,4,4,4,4,4,4,4
      },
      {
          0,1,2,3,4,5,6,7,8,
          8,7,6,5,4,3,2,1,0,
          0,1,2,3,4,5,6,7,8,
          8,7,6,5,4,3,2,1,0
      }},
    { 36, 24, 
      {
          12,12,						// two cheesy
          11,11,11,11,11,11,11,11,		// 8 high
          10,10,10,10,10,10,10,10,		// "" 
          9, 9, 9, 9, 9, 9, 9, 9, 9,	// 9 high
          8, 8, 8, 8, 8, 8, 8, 8, 8
      },
      {
          1,0,
          0,1,2,3,4,5,6,7,				// 8 high
          7,6,5,4,3,2,1,0,
          0,1,2,3,4,5,6,7,8,
          8,7,6,5,4,3,2,1,0
      }},

// TBD....
    { 36, 25, 		// rows of 8 w/ first one lame
      {
          16,16,
          15,15,15,15,15,15,15,15,	// 8
          14,14,14,14,14,14,14,14,	// 8
          13,13,13,13,13,13,13,13,13,	// 9
          12,12,12,12,12,12,12,12,12	// 9
      },
      {
          1,0,
          0,1,2,3,4,5,6,7,
          7,6,5,4,3,2,1,0,
          0,1,2,3,4,5,6,7,8,
          8,7,6,5,4,3,2,1,0
      }},
};