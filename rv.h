// Configuration Information --
// Note: data structure allocates space for all strands to have same longest length - this could be modified to
// only allocate space required for actual number of LEDS

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

