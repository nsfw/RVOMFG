///////////////////////////////////////////////////////////////////////////////
// Configuration Information
///////////////////////////////////////////////////////////////////////////////
#define MAX_STRAND_LEN 1	// Should be the ACTUAL LENGTH OF LONGEST STRAND - electrical max is 62
#define STRAND_COUNT 1		// Needs to be ACTUAL NUMBER OF DATA LINES IN USE
#define IMG_WIDTH 1
#define IMG_HEIGHT 1
///////////////////////////////////////////////////////////////////////////////

struct rgb {
  byte r;
  byte g;
  byte b;
};

typedef struct a_strand {
    byte len;		// length of this strand
    byte pin;		// digital out pin associated w/ this strand
    byte x[MAX_STRAND_LEN];		// source X and Y from Image
    byte y[MAX_STRAND_LEN];
} strand;


strand strands[]={
// len, pin, {x-coords}{y-coords}, initial color
    { 1, 22, {0},{0} }
};

/* strand strands[]={ */
/* // len, pin, {x-coords}{y-coords}, initial color */
/*     { 4, 22, {0,1,2,3}, {0,0,0,0}}, */
/*     { 4, 24, {0,1,2,3}, {1,1,1,1}} */
/* }; */
