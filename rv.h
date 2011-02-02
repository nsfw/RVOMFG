// Configuration Information --
// Note: data structure allocates space for all strands to have same longest length - this could be modified to
// only allocate space required for actual number of LEDS

#define MAX_STRAND_LEN 50	// Should be the ACTUAL LENGTH OF LONGEST STRAND - electrical max is 62
#define STRAND_COUNT 2		// Needs to be ACTUAL NUMBER OF DATA LINES IN USE

typedef uint8_t byte

struct rgb {
  byte r;
  byte g;
  byte b;
};

struct strand {
    byte len;		// length of this strand
    byte pin;		// digital out pin associated w/ this strand
    byte x[MAX_STRAND_LEN];		// source X and Y from Image
    byte y[MAX_STRAND_LEN];
    rgb color;          // current color of LED here
};

