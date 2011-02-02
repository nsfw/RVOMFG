/*
Drive a matrix of Color Effects LEDs

Input is a RECTANGULAR matrix of pixel values (typically animated) and
a map of strand/light (typically fixed) to x,y. The map consists of
STRAND_COUNT length array of arrays of bulbs and associated x,y source
pixel.

Note: The output display is most likely NOT Rectangular and there is no
correlation between input row/column and "strand"/"light".

All LEDs are updated each frame, in strand/index order. 
*/

byte debugLevel = 3;

// #include "rv.h"
// Note: data structure allocates space for all strands to have same longest length - this could be modified to
// only allocate space required for actual number of LEDS

// #include "conf1led.h"
#include "conf4x2.h"

// FRAME BUFFER
rgb img[IMG_WIDTH][IMG_HEIGHT]={128,0,255};
rgb white = { 255, 255, 255 };
rgb red = {255, 0, 0};
rgb green = {0, 255, 0};
rgb blue = {0,0,255};

void setup() {
    Serial.begin(9600);
    Serial.println("Device Start");
    int i = 0;
    while (i < STRAND_COUNT) {
        pinMode(strands[i].pin, OUTPUT);
        digitalWrite(strands[i].pin, LOW);
        Serial.print("Configured strand ");
        Serial.print(i);
        Serial.print(" on output pin ");
        Serial.println(strands[i].pin);
        i++;
    }
    Serial.println("Output Pins Configured");
  
    delay(1000);

    Serial.print("Initializing Strands");
    initFrameBuffer(0);		// put *something* in the frame buffer
    // sendIMGPara();
    sendIMGSerial();		// note: First time since power up, will assign addresses.
    						// If image buffer doesn't match strand config, interesting things
    						// will happen!
    Serial.println(" -- done");
    debugLevel=0;
}

void loop(){
    static int i=0;
    // setGlobalIntensity((i%128)+100);
    // do something wth IMAGE HERE
    initFrameBuffer(i);

    // Serial.print(i);
    // sendIMGSerial();
    sendIMGPara();

    delay(500);
    i++;
};


///////////////////////////////////////////////////////////////////////////////
// Library
///////////////////////////////////////////////////////////////////////////////

void initFrameBuffer(int i){
    Serial.print("+");
    Serial.print(i);

    // just stick some pattern in it for now
    for(byte x=0; x<IMG_WIDTH; x++){
        for(byte y=0; y<IMG_HEIGHT; y++){
            i = i%3;
            img[x][y]= (i==0)?red:((i==1)?blue:green);
            i++;
        }
    }
}

///////////////////////////////////////////////////////////////////////////////
// low level io
///////////////////////////////////////////////////////////////////////////////

void sendIMGSerial() {
  // for all strands, one strand at a time
    for (byte i=0; i<STRAND_COUNT; i++){
        strand *s = &strands[i];
        for(byte index=0; index<s->len; index++){
            // for all leds on strand
            byte x = s->x[index];
            byte y = s->y[index];
            rgb *pix = &img[x][y];

            if (debugLevel > 0) { Serial.print("LED at "); Serial.print((int) x);
                Serial.print(", "); Serial.println((int) y); }
            
            sendSingleLED(index, s->pin, pix->r, pix->g, pix->b, 0xCC);		// fullish intensity
        }
    }
}

void sendSingleLED(byte address, int pin, byte r, byte g, byte b, byte i) {
  boolean streamBuffer[26];
  int streamPos = 0;
  int bitPos;
  int currentData;

  makeFrame(address, r, g, b, 0xCC, streamBuffer);

  if (debugLevel > 1) {
    Serial.print("Pin: ");
    Serial.print(pin);
    Serial.print("    Address: ");
    Serial.print((int) address);
    Serial.print("    Intensity: ");
    Serial.print((int) i);
    Serial.print("    Blue: ");
    Serial.print((int) b);
    Serial.print("    Green: ");
    Serial.print((int) g);
    Serial.print("    Red: ");
    Serial.println((int) r);
    dumpFrame(streamBuffer);
    Serial.println();
    Serial.println();
  }

  // send start bit 
  togglePin(pin);			// HIGH FOR 8us
  delayMicroseconds(8);
  streamPos = 0;
  while (streamPos < 26) {
      if (streamBuffer[streamPos]) {
          //send a 1
          togglePin(pin);	// LOW for 19us
          delayMicroseconds(19);
          togglePin(pin);	// HIGH for 8us
          delayMicroseconds(8);	
      } else {
          //send a 0
          togglePin(pin);	// LOW for 9us
          delayMicroseconds(9);
          togglePin(pin);	// HIGH for 18us
          delayMicroseconds(18);
    }
    streamPos++;
  }
  togglePin(pin);			// LOW
  delayMicroseconds(30);	// frame quiesce
}

void dumpFrame(byte *buffer){
    Serial.print("frame: ");
    for(byte i = 0; i < 26; i++) Serial.print((int) buffer[i]);
}

void makeFrame(byte index, byte r, byte g, byte b, byte i, byte *buffer){
// sfw: check that this is using the 4 MSBs of colors

  int bufferPos = 0;
  int bitPos;
  int data;

  while (bufferPos < 26) {
    switch (bufferPos) {
      case 0:
        bitPos = 6;
        data = index;
        break;
      case 6:
        bitPos = 8;
        data = i;	
        break;
      case 14:
        bitPos = 4;
        data = b;
        break;
      case 18:
        bitPos = 4;
        data = g;
        break;
      case 22:
        bitPos = 4;
        data = r;
        break;
      default:
        break;
    } 

    buffer[bufferPos] = ( (data & (1 << (bitPos - 1))) != 0) ? 1:0;
    bitPos--;
    bufferPos++;
  }
}

int row[STRAND_COUNT];	// index of LED to display for each strand

void sendIMGPara(){
    // walk the strand length 
    for(byte i=0; i < MAX_STRAND_LEN; i++ ){
        // compute what index each strand should send
        for( byte j=0; j < STRAND_COUNT; j++)
            row[j] = (i < strands[j].len )? i: -1;
        // send strand data in 
        sendPara();		
    }
}

// Serial Protocol:
//
// Idle bus state: Low
// Start Bit: High for 10µSeconds
// 0 Bit: Low for 10µSeconds, High for 20µSeconds
// 1 Bit: Low for 20µSeconds, High for 10µSeconds
// Minimum quiet-time between frames: 30µSeconds
//
// Phase 1 2 3 
// 0 =   L H H 
// 1 =   L L H

void sendPara(){
    byte bits[STRAND_COUNT][26];

    // compute bit streams for all strands
    for (byte s=0; s<STRAND_COUNT; s++){
        int index = row[s];
        if (index != -1){
            byte x = strands[s].x[index];
            byte y = strands[s].y[index];
            rgb *pix = &img[x][y];
            makeFrame(index, pix->r, pix->g, pix->b, 0xCC, bits[s]);
        }
    }

    // DBG: dump the bits for the first strand
    Serial.print("para strand0 :");
    dumpFrame(&bits[0][0]);
    Serial.println("");

    byte debugFlag = 0;
    byte skipStart = 0;
    // for each bit
    for(byte b=0; b<27; b++){
    	// for each phase
        for(byte phase=skipStart; phase<4; phase++){
            // for each strand
            for(byte s=0; s<STRAND_COUNT; s++){
                byte data;
                if(row[s]==-1) break;	// nop if no data for this strand
                if(b==26) phase=4;		// handle END OF FRAME
                else data = bits[s][b];
                switch (phase) {
                case 0: // START BIT - HIGH	
                    togglePin(strands[s].pin);
                    break;
                case 1: // PHASE I - LOW for BOTH 0 or 1
                    togglePin(strands[s].pin);
                    break;
                case 2: // PHASE 2 - HIGH for 0
                    if(!data) togglePin(strands[s].pin);
                    break;
                case 3: // PHASE 3 - HIGH for 1
                    if(data) togglePin(strands[s].pin);
                    break;
                case 4: // PHASE 4 - END OF FRAME
                    togglePin(strands[s].pin);
                    break;
                }
            }
            if(!skipStart) skipStart = 1;
            // 1/3 bit delay 
            delayMicroseconds(9);	// Need to time this - should make more parallel
        }
    }
    delayMicroseconds(21);	// frame quiesc 30us 
    if(debugFlag) Serial.println("");
}

void setGlobalIntensity(byte val){
    // set intensity value across all strands for all leds
    for(byte s=0; s<STRAND_COUNT; s++)
        sendSingleLED(63,			// broadcast intensity
                      strands[s].pin,
                      0, 0, 0,		// ignores rgb
                      val);		
}

void togglePin(uint8_t pin) {
    // sfw: not thrilled with this... 
    switch(pin) {
      case 22:
        PORTA = (PORTA ^ B00000001);
        break;
      case 23:
        PORTA = (PORTA ^ B00000010);
        break;
      case 24:
        PORTA = (PORTA ^ B00000100);
        break;
      case 25:
        PORTA = (PORTA ^ B00001000);
        break;
      case 26:
        PORTA = (PORTA ^ B00010000);
        break;
      case 27:
        PORTA = (PORTA ^ B00100000);
        break;
      case 28:
        PORTA = (PORTA ^ B01000000);
        break;
      case 29:
        PORTA = (PORTA ^ B10000000);
        break;
      default:
        break;
    }
};

///////////////////////////////////////////////////////////////////////////////
// debug utils
///////////////////////////////////////////////////////////////////////////////

#include <avr/pgmspace.h>
static void	dumpHex(void * startAddress, char* name, unsigned lines){
    int				ii;
    int				theValue;
    int				lineCount;
    char			textString[16];
    char			asciiDump[24];
    unsigned long	myAddressPointer;
    
	lineCount			=	0;
	myAddressPointer	=	(unsigned long) startAddress;
    sprintf(textString, "%s:\n", name);
    Serial.print(textString);
	while (lineCount < 1) {
		sprintf(textString, "%04X - ", myAddressPointer);
		Serial.print(textString);
		
		asciiDump[0]		=	0;
		for (ii=0; ii<16; ii++) {
			theValue	=	pgm_read_byte_near(myAddressPointer);

			sprintf(textString, "%02X ", theValue);
			Serial.print(textString);
			if ((theValue >= 0x20) && (theValue < 0x7f)) {
				asciiDump[ii % 16]	=	theValue;
            }
			else {
				asciiDump[ii % 16]	=	'.';
			}
			
			myAddressPointer++;
		}
		asciiDump[16]	=	0;
		Serial.println(asciiDump);
	
		lineCount++;
	}
}

