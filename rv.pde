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

#include <stdarg.h>
void p(char *fmt, ... ){
        char tmp[128]; // resulting string limited to 128 chars
        va_list args;
        va_start (args, fmt );
        vsnprintf(tmp, 128, fmt, args);
        va_end (args);
        Serial.print(tmp);
}

byte debugLevel = 3;

// #include "rv.h"
// Note: data structure allocates space for all strands to have same longest length - this could be modified to
// only allocate space required for actual number of LEDS

// #include "conf1led.h"
#include "conf4x2.h"

// FRAME BUFFER
rgb img[IMG_WIDTH][IMG_HEIGHT]={128,0,255};
#define DEFAULT_INTENSITY 0xee
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

    initFrameBuffer(0);		// put *something* in the frame buffer

    Serial.print("Initializing Strands");
    sendIMGSerial();		// note: First time since power up, will assign addresses.
    						// If image buffer doesn't match strand config, interesting things
    						// will happen!
    Serial.println(" -- done");
    debugLevel=0;
}

void loop(){
    static int i=0;
    static byte bright=DEFAULT_INTENSITY;
    int dir=-1;

    if(i>64){
        if(i==65){
            bright=DEFAULT_INTENSITY;
            dir=-1;
        }
        setGlobalIntensity((byte) bright+dir);
        if(bright==10) dir=1;
        if(bright==220) dir=-1;
        delay(1);
        if(i>4000) i=0;
    } else {
        // do something wth IMAGE HERE
        initFrameBuffer(i);
        sendIMGPara();
        delay(200);
    }
    i++;
};


///////////////////////////////////////////////////////////////////////////////
// Library
///////////////////////////////////////////////////////////////////////////////

void initFrameBuffer(int i){
    // just stick some pattern in it for now
    for(byte x=0; x<IMG_WIDTH; x++){
        for(byte y=0; y<IMG_HEIGHT; y++){
            i = i%3;
            img[x][y]= (i==0)?red:((i==1)?blue:green);
            i++;
        }
    }
}

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
            
            sendSingleLED(index, s->pin, pix->r, pix->g, pix->b, DEFAULT_INTENSITY);		// fullish intensity
        }
    }
}

void sendSingleLED(byte address, int pin, byte r, byte g, byte b, byte i) {
  boolean streamBuffer[26];
  int streamPos = 0;
  int bitPos;
  int currentData;

  makeFrame(address, r, g, b, i, streamBuffer);

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
        data = b>>4;
        break;
      case 18:
        bitPos = 4;
        data = g>>4;
        break;
      case 22:
        bitPos = 4;
        data = r>>4;
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
        composeFrame();
    }
}

void setGlobalIntensity(byte val){
    byte buffer[26];
    makeFrame(0xff, 0x80,0x80,0x00, val, buffer);
    // collect bit streams for ALL strands
    for (byte s=0; s<STRAND_COUNT; s++)
        deferredSendFrame(strands[s].pin, buffer);
    sendFrame();
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


void setPin(byte pin){
    if(pin<30) PORTA |= (1<<(pin-22));
    else PORTC |= (1<<(pin-22));
}
void clrPin(byte pin){
    if(pin<30) PORTA &= ~(1<<(pin-22));
    else PORTC &= ~(1<<(pin-22));
}
void togglePin(byte pin){
    if(pin<30) PORTA ^= (1<<(pin-22));
    else PORTC ^= (1<<(pin-22));
}

// Deferred I/O
// Note: doing just portA for now

#define FRAMESIZE (2+(26*3))
// pins 22-29
byte portAframe[FRAMESIZE];	// start and stop frome + 26 bits 
byte portAmask=0;			// remember what pins are being set
// pins 30-37 
byte portCframe[FRAMESIZE];	
byte portCmask=0;			

char port=0;	// 'a', 'c', etc.
byte pinmask;	// pin as bit mask (e.g. 22 = 0x01, 23 = 0x02...)

char computePortAndMask(byte pin){
    if(22 <= pin && pin <= 30){
        port = 'a';
        pinmask = (1<<(pin-22));
        portAmask |= pinmask;	// remember we're using this output pin
    } else if(30 <= pin && pin <= 38){
        port = 'c';
        pinmask = (0x80>>(pin-30));	// bit 0 = pin 37
        portCmask |= pinmask;	// remember we're using this output pin
    }
}

void frameSet(byte slice, byte pin){
    computePortAndMask(pin);
    switch(port){
    case 'a':
        portAframe[slice] |= pinmask; break;
    case 'c':
        portCframe[slice] |= pinmask; break;
    }
}

void frameClr(byte slice, byte pin){
    computePortAndMask(pin);
    switch(port){
    case 'a':
        portAframe[slice] &= ~pinmask; break;
    case 'c':
        portCframe[slice] &= ~pinmask; break;
    }
}

// void frameSet(byte slice, byte pin){
//     byte bit = pin - 22;	// bit 0..7 is pin 22..29
//     portAframe[slice] |= (1<<bit);
//     portAmask |= (1<<bit);
// }

// void frameClr(byte slice, byte pin){
//     byte bit = pin - 22;	// bit 0..7 is pin 22..29
//     portAframe[slice] &= ~(1<<bit);
//     portAmask |= (1<<bit);
// }

void dumpPin(byte pin){
    byte bit = pin - 22;
    p("\nPin %d (%d): ", pin, bit);
    for(byte i=0; i<FRAMESIZE; i++)
        Serial.print(portAframe[i]&(1<<bit)?"1":"0");
    Serial.println("");
}

void composeFrame(){
    // take your time and figure out what you want to say!
    byte buffer[26];
    // collect bit streams for ALL strands
    for (byte s=0; s<STRAND_COUNT; s++){
        int index = row[s];
        if (index != -1){
            byte x = strands[s].x[index];
            byte y = strands[s].y[index];
            rgb *pix = &img[x][y];
            makeFrame(index, pix->r, pix->g, pix->b, DEFAULT_INTENSITY, buffer);
            deferredSendFrame(strands[s].pin, buffer);
        }
    }
    sendFrame();
}

void deferredSendFrame(byte pin, byte *buffer){
    byte slice = 0;
    // buffer is 26bit frame
    frameSet(slice++,pin);	// start bit
    for(byte i=0; i<26; i++){
        if(buffer[i]){	// send a 1 : L L H
            frameClr(slice++, pin);
            frameClr(slice++, pin);
            frameSet(slice++, pin);
        } else {		// send a 0: L H H
            frameClr(slice++, pin);
            frameSet(slice++, pin);
            frameSet(slice++, pin);
        }
    }
    frameClr(slice++,pin);	// back to LOW inter frame
}

void sendFrame(){
    // Say it in one precise parallel blast
    for(byte i = 0; i<FRAMESIZE; i++){
        PORTA = (PORTA & ~portAmask) | (portAframe[i] & portAmask);	// selectively set bits
        PORTC = (PORTC & ~portCmask) | (portCframe[i] & portCmask);	// selectively set bits
        delayMicroseconds(10);
    }
    delayMicroseconds(20);	// 30us quiesce
}

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

