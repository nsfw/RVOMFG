/*
Drive a matrix of Color Effects LEDs

Input is a RECTANGULAR matrix of pixel values (typically animated) and
a map of strands/lights (typically fixed) to x,y. The map consists of
STRAND_COUNT length array of arrays of bulbs and associated x,y source
pixel.

Note: The output display is most likely NOT Rectangular and there is no
correlation between input row/column and "strand"/"light".

All LEDs are updated each frame, in strand/index order. 

Scott -- alcoholiday at gmail
*/

/* Perfomance Issues and Improvements -

   Much of the time is taken in the CPU BOUND composeAndSendFrame function,
   which is called once per LED on the longest strand. It can
   definately use some optimization.

   sendIMGPara()
    foreach LED per strand:	// x36 times
     foreach STRAND:		// x11 times
      composeAndSendFrame()
         makeFrame()		    // encodes data for an LED into a byte buffer
         defferredSendFrame()	// sets bits for serial stream
       sendFrame       
*/
 

// Ethernet Support
#include <SPI.h>
#include <Client.h>
#include <Ethernet.h>
#include <Server.h>
#include <Udp.h>

// rgb <-> hsv
#include "RGBConverter.h"
RGBConverter converter;

// debug 
#define DBG	// conditional DBG code compiled in - small speed penalty
#define DEBUG_TIMING	// may cause significant serial traffic

// remotely settable -- e.g.  osc("/debug",100)
byte debugLevel = 0;	// debugLevel > 100 will print each pixel as sent via /screen

///////////////////////////////////////////////////////////////////////////////
// include appropriate MAPPING configuration
///////////////////////////////////////////////////////////////////////////////
// #include "conf1led.h"	// 1 LED useful for debugging
// Remember - we're talking ROWS and COLUMNS
// #include "conf9x10.h"		// initial two strings on RV
// #include "test9x10.h"		// concentric circles
// #include "conf4x2.h"		// 4x2 matrix
// #include "confRV0.h"		// RV v0

#define FLIP_DRIVER_SIDE	// make text go left to right
#include "confRV1.h"		// RV v1 - allows for flipping driver side X-coords

// initialization behavior
#define rgbrgbinit 

// Low level Serial Rate 
int tribit=8;		// # of us (nominal 10) per 1/3rd of a serial bit 
int quiettime=27;	// # of us (nominal 30) quiesce time between frames

// Ethernet - IP ADDRESS
#ifdef DIRECT_CONNECT
byte myMac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte myIp[]  = { 198, 178, 187, 122 };
#endif
#define RVIP
#ifdef RVIP
byte myMac[] = { 0xBE, 0xEF, 0xBE, 0xEF, 0xBE, 0xEF };
byte myIp[]  = { 192, 168, 69, 69 };
#endif
int  serverPort  = 9999;

// OSC
#include <ArdOSC.h>
OSCServer osc;
OSCMessage *oscmsg;

// FRAME BUFFER
rgb img[IMG_HEIGHT][IMG_WIDTH]={128,0,255};		// source image from controller
rgb out[IMG_HEIGHT][IMG_WIDTH]={128,0,255};		// output image (post scroll)
// MAX of 0xff seems to glitch things
#define MAX_INTENSITY 0x0f2
rgb white = { 255, 255, 255 };
rgb black = { 0,0,0 };
rgb red = {255, 0, 0};
rgb green = {0, 255, 0};
rgb blue = {0,0,255};

// Setable via OSC
float hScrollRate=0.0;
float vScrollRate=0.0;
float hueScrollRate=0.0;
float hsPos=0;
float vsPos=0;
float huePos=0;

int solidMode = 0;
rgb currentColor={255, 0, 0};
int displayCurrentColor=0;

// forward reference
// void pf(char *fmt, ... );
// PF CONSIDERED HARMFUL! Seems to be bringing in other libs... :?

void setup() {
    Serial.begin(57600);
    Serial.println("Device Start -- ");
    // pf("IP: %d.%d.%d.%d:%d\n", myIp[0], myIp[1], myIp[2], myIp[3], serverPort);

    int i = 0;
    while (i < STRAND_COUNT) {
        strandEnabled[i]=1;
        pinMode(strands[i].pin, OUTPUT);
        digitalWrite(strands[i].pin, LOW);
        Serial.print("Configured strand ");
        Serial.print(i, DEC);
        Serial.print(" on output pin ");
        Serial.print(strands[i].pin, DEC);
        Serial.print("\n");
        i++;
    }
    Serial.println("Output Pins Configured");

    Ethernet.begin(myMac ,myIp); 
    osc.sockOpen(serverPort);

    resetDisplay(0);			// put *something* in the frame buffer

    Serial.print("Initializing Strands");

    // note: First time since power up, will assign addresses.
    // If image buffer doesn't match strand config, interesting things
    // will happen!
    sendIMGSerial();

    Serial.println(" -- done");
    debugLevel=0;

    hueScrollRate=0.00;		// and make it do something while wait for something to do
    vScrollRate=0.8;
}

byte noOSC=1;

void loop(){
    static int i=0;
    static int dirty=0;
    while(osc.available()){	// process all prior to displaying
        dirty=1;
        if(noOSC){
            resetDisplay(0);	// get back to a known state if someone is talking to us
            noOSC=0;
        }
        oscmsg=osc.getMessage();
        oscDispatch();
    }    
    if(dirty || hueScrollRate || vScrollRate || hScrollRate || displayCurrentColor ) 
        sendIMGPara();
}

///////////////////////////////////////////////////////////////////////////////
// OSC "handlers"
///////////////////////////////////////////////////////////////////////////////

void panelEnable(int p, int enable){
    // consider losing this, we never use it - turns off one side
    // or the other of the RV.

    int start=0, end=5;
    if(p==1){start=6; end=11;}

    for (int i=start; i<=end; i++){
        strandEnabled[i]=enable;
        // pf("setting strand %d to %d\n", i, enable);
    }
}


void oscDispatch(){
    static int resetcount=0;

    char *p = oscmsg->getOSCAddress();

    if(*p != '/'){
        Serial.println("MALFORMED OSC");
        return;
    }

    if(debugLevel){
        Serial.print("osc: ");
        Serial.println(p);
    }

    if(!strncasecmp(p,"/1",2)) p+=2;	// skip page number on TouchOSC

    p++;	    // skip leading slash

    if(!strncasecmp(p,"screen",6)){
        copyImage();
    } else if(!strncasecmp(p,"bright",5)){
        brightness(oscmsg->getFloat(0)); 
    } else if(!strncasecmp(p,"hscroll",7)){
    } else if(!strncasecmp(p,"vscroll",7)){
        vScrollRate=oscmsg->getFloat(0); 
    } else if(!strncasecmp(p,"huescroll",8)){
        hueScrollRate=oscmsg->getFloat(0); 
    } else if(!strncasecmp(p,"hvscroll",8)){
        hScrollRate=oscmsg->getFloat(1); 
        vScrollRate=oscmsg->getFloat(0); 
    } else if(!strncasecmp(p,"fill",4)){
        // fill framebuffer w/ an rgb(float) color
        rgb c;
        if(oscmsg->getArgsNum()==4){
            c.r=oscmsg->getFloat(0)*255;
            c.g=oscmsg->getFloat(1)*255;
            c.b=oscmsg->getFloat(2)*255;
            fill(c);
        } else {
            Serial.println("err: /fill expects 3 floats");
        }
    } else if(!strncasecmp(p,"reset",5)){
        resetDisplay(resetcount++);		// back to a known state
    } else if(!strncasecmp(p,"noScroll",5)){
        noScroll();						// just kill scroll and reset screen position
    } else if(!strncasecmp(p,"setyx",5)){
        // Just set a single pixel!
        int y, x;
        rgb c;
        if(oscmsg->getArgsNum()==6){
            y = oscmsg->getInteger32(0);
            x = oscmsg->getInteger32(1);
            c.r=oscmsg->getFloat(2)*255;
            c.g=oscmsg->getFloat(3)*255;
            c.b=oscmsg->getFloat(4)*255;
            // c.a=0xff;	//  make this optionally settable
            if(x<IMG_WIDTH && y<IMG_HEIGHT){
                img[y][x] = c;
            }
        } else {
            Serial.println("err: /setyx expects i,i,f,f,f");
        }
    } else if(!strncasecmp(p,"rgb",3)){
        // process "/effect/rgb/1..3 [0.0 .. 1.0] messages
        int i = p[4]-'1';		// 1..3
        byte *c = (byte*) &currentColor;
        c[i]=(int) 255*oscmsg->getFloat(0);
        if(solidMode){			// set whole screen to this color
            fill(currentColor);
        } else 
            displayCurrentColor=10;		// show current color for this many cycles
    } else if(!strncasecmp(p,"clear",5)){
        fill(black);
    } else if(!strncasecmp(p,"solid",5)){
        solidMode = oscmsg->getFloat(0);
        Serial.println("Solid Mode");
        Serial.println(solidMode);
    } else if(!strncasecmp(p,"grid",4)){
        // format: grid1/4/1, grid2/5/12
        // grid1/9/1
        int pan = (p[4]=='2');
        int row = 9-(p[6]-'0');	// sends 1-9 (upside down)
        int col = p[8]-'0';
        if(p[9]) col = 10 + p[9]-'0';
        col = col - 1 + pan*15;
        // Serial.println(p);
        // Serial.println(row);
        // Serial.println(col);
        img[row][col] = currentColor;
    } else if(!strncasecmp(p,"panel",5)){
        // enable or disable a panel
        // /panel panel#, mode
        Serial.println("handling panel");
        
        int pan = oscmsg->getInteger32(0);
        int mode = oscmsg->getInteger32(1);
        if(!mode) fill(black);
        panelEnable(pan,mode);
    } else if(!strncasecmp(p,"datarate",8)){
        // debug method - set serial data rate! tribit quiettime
        tribit    = oscmsg->getInteger32(0);
        quiettime = oscmsg->getInteger32(1);
        // pf("tribit = %d quiettime = %d", tribit, quiettime);
    } else if(!strncasecmp(p,"debug",5)){
        debugLevel=oscmsg->getInteger32(0);	// set debug level
    } else {
        Serial.print("Unrecognized Msg: ");
        Serial.println(p);
    }
}

void copyImage(){
	//
    // copy image data from OSC to framebuffer
    // 
    int h = oscmsg->getInteger32(0);
    int w = oscmsg->getInteger32(1);

    // Inbound Image must at least as big as our measly frame buffer in size
    if(w<IMG_WIDTH || h<IMG_HEIGHT){
        Serial.println("Inbound Image must at least as big as our measly frame buffer in size");
        return;
    }

    byte *data = (byte*) oscmsg->getBlob(2)->data;
#ifdef DBG
    if(debugLevel==101){
        // pf("Blob Length: %d\n",oscmsg->getBlob(2)->len);
        dumpHex(data, "ScreenData:", 4);
    }
#endif

    for(byte x=0; x<IMG_WIDTH; x++){
        for(byte y=0; y<IMG_HEIGHT; y++){
            rgb *d = &img[y][x];
            byte *s = data + ((x+(y*w))<<2);	// src pixels in uint32
            d->r = *s++;
            d->g = *s++;
            d->b = *s++;
            // skip alpha
#ifdef DBG
            // if(debugLevel>100) pf("[%d][%d]=%d,%d,%d ",y,x,d->r,d->g,d->b);
#endif
        }
#ifdef DBG
        if(debugLevel>100) Serial.println("/n");
#endif
    }
}


///////////////////////////////////////////////////////////////////////////////
// Initial Frame Buffer functions
///////////////////////////////////////////////////////////////////////////////

#ifdef rgbrgbinit
void initFrameBuffer(int i){
    // just stick some pattern in it for now
    for(byte x=0; x<IMG_WIDTH; x++){
        for(byte y=0; y<IMG_HEIGHT; y++){
            static int z=0;
            z=y%8;
            img[y][x]= (z==0||z==1)?red:((z==2||z==3)?green:(z==4||z==5)?blue:black);
//             img[y][x]= (z==0)?red:((z==1)?green:blue);
//            z=(++z)%3;
        }
    }
}
#endif

#ifdef conf9x10
void initFrameBuffer(int i){
    i=i%3000;
    if(i<1000){
        // just stick some pattern in it for now
        for(byte x=0; x<IMG_WIDTH; x++){
            for(byte y=0; y<IMG_HEIGHT; y++){
                i = ((test9x10[y][x]+i)-1)%3;
                img[y][x]= (i==0)?red:((i==1)?green:blue);
            }
        }
    } else {
        // rows and columns
        for(byte x=0; x<IMG_WIDTH; x++){
            for(byte y=0; y<IMG_HEIGHT; y++){
                int z = (i<2000)? x%3:y%3;
                img[y][x]= (z==0)?red:((z==1)?green:blue);
            }
        }
    }
}
#endif

void noScroll(){
    // stop scroll and reset screen position
    hScrollRate=vScrollRate=hueScrollRate=0.0;	// rates
    hsPos=vsPos=huePos=0;	// and positions
}

void resetDisplay(int i){
    noScroll();
    initFrameBuffer(i);
}

///////////////////////////////////////////////////////////////////////////////
// Library
///////////////////////////////////////////////////////////////////////////////

void fill(struct rgb c){
    // fill the frame buffer with a color
    for(byte x=0; x<IMG_WIDTH; x++){
        for(byte y=0; y<IMG_HEIGHT; y++){
            img[y][x]=c;
        }
    }
}

byte imgBright=MAX_INTENSITY;
float bright=1.0;

void brightness(float b){
    bright=b;
    bright = max(0.0, bright);
    bright = min(1.0, bright);
    imgBright = (float)MAX_INTENSITY*bright;
}


// think we can switch to the parallell version now...

void sendIMGSerial() {
    // for all strands, one strand at a time
    // Also useful for initial addressing
    // NOTE: uses img[][] directly instead of out[][]
    for (byte i=0; i<STRAND_COUNT; i++){
        strand *s = &strands[i];
        for(byte index=0; index<s->len; index++){
            // for all leds on strand
            byte x = s->x[index];
            byte y = s->y[index];
            rgb *pix = &img[y][x];

            sendSingleLED(index, s->pin, pix->r, pix->g, pix->b, imgBright);
        }
    }
}

void sendSingleLED(byte address, int pin, byte r, byte g, byte b, byte i) {
    byte buffer[26];
    makeFrame(address, r, g, b, i, buffer);
    deferredSendFrame(pin, buffer);
    sendFrame();
}

void makeFrame(byte index, byte r, byte g, byte b, byte i, byte *buffer){
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

void prepOutBuffer(){
    // copy img[][] -> out[][] w/ possible transforms
    // consider adding a "hue scroll" that cycles colors

    hsPos+=hScrollRate;
    vsPos+=vScrollRate;
    huePos+=hueScrollRate;

    if(displayCurrentColor) --displayCurrentColor;

    for(byte x=0; x<IMG_WIDTH; x++){
        for(byte y=0; y<IMG_HEIGHT; y++){
            int ny = y+vsPos;
            int nx = x+hsPos;
            rgb *s = &img[abs(ny%IMG_HEIGHT)][abs(nx%IMG_WIDTH)];
            if(displayCurrentColor){
                // override output w/ current color
                out[y][x] = currentColor;
            } else if(hueScrollRate!=0.0) {
                float hsv[3];
                converter.rgbToHsv(s->r, s->g, s->b, hsv);
                converter.hsvToRgb(fabs(fmod(hsv[0]+huePos,1.0)), hsv[1], hsv[2], (byte*) &out[y][x]);
            } else {
                out[y][x] = *s;
            }
        }
    }

}


void displayTimeSince(unsigned long then, char * desc){
#ifdef DEBUG_TIMING
     unsigned long diff = millis() - then;
     Serial.print(desc);
     Serial.print(": ");
     Serial.print(diff);
     Serial.print("ms\n");
#endif
     }

void sendIMGPara(){
    unsigned long sendIMGParaEntry = millis();

    // copy the source frame buffer to the output frame buffer
    // may do things like scroll image and such...
    prepOutBuffer();	// ~18ms
    displayTimeSince(sendIMGParaEntry, "prepOutBuffer");

    // walk the strand length ~230ms
    for(byte i=0; i < MAX_STRAND_LEN; i++ ){
        // compute what index each strand should send
        for( byte j=0; j < STRAND_COUNT; j++)
            row[j] = (i < strands[j].len )? i: -1;
        composeAndSendFrame();
    }
    displayTimeSince(sendIMGParaEntry, "sendIMGPara");
}

void setGlobalIntensity(byte val){
    byte buffer[26];
    makeFrame(0xff, 0x80,0x80,0x00, val, buffer);
    // collect bit streams for ALL strands
    for (byte s=0; s<STRAND_COUNT; s++)
        deferredSendFrame(strands[s].pin, buffer);
    sendFrame();
}


///////////////////////////////////////////////////////////////////////////////
// Low Level I/O
///////////////////////////////////////////////////////////////////////////////
//
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

///////////////////////////////////////////////////////////////////////////////
// Deferred I/O storage
// 
// Add more portXstuff here as you need more bits
///////////////////////////////////////////////////////////////////////////////
#define FRAMESIZE (2+(26*3))

// pins 22-29 PORTA
byte portAframe[FRAMESIZE];	// start and stop frome + 26 bits 
byte portAmask=0;			// remember what pins are being set

// pins 30-37 PORTC
byte portCframe[FRAMESIZE];	
byte portCmask=0;			

// note: pinmask, portXmask and buffers for each port can be precomputed
// and this function not used at send time
// For KELP turn this into a look up table

byte * getBufferAndMask(byte pin, byte &pinmask){
    if(22 <= pin && pin <= 30){	// PORTA
        pinmask = (1<<(pin-22));
        portAmask |= pinmask;	// remember we're using this output pin
        return portAframe;
    } else if(30 <= pin && pin <= 38){
        pinmask = (0x80>>(pin-30));	// bit 0 = pin 37
        portCmask |= pinmask;	// remember we're using this output pin
        return portCframe;
    }
}

void composeAndSendFrame(){
    // Compose bit pattern to send for a particular LED across all active strands
    // and then send it in one bollus

    // TIMING ANALYSIS: This is once per MAX LED per Strand (~36 times
    // for an image on RV)
    // This is where we're spending most of our time, and have been in the <4fps
    // range... should be in the ~10fps range now.
    
    byte buffer[26];

    // Accumulate bit streams for ALL strands in portAframe[], portCframe[], etc...
    unsigned long composeLoop = millis();
    for (byte s=0; s<STRAND_COUNT; s++){
        int index = row[s];
        if ((index != -1) && (strandEnabled[s]!=0)){
            byte x = strands[s].x[index];
            byte y = strands[s].y[index];
            rgb *pix = &out[y][x];
            // unsigned long makeFrameTime = millis();
            makeFrame(index, pix->r, pix->g, pix->b, imgBright, buffer);
            // displayTimeSince(makeFrameTime,"makeFrame");
            // unsigned long defferedSendFrameTime = millis();
            deferredSendFrame(strands[s].pin, buffer);
            // displayTimeSince(defferedSendFrameTime, "defferedSendFrame");
        }
    }
    // displayTimeSince(composeLoop,"composeLoop");
    // unsigned long sendFrameTime = millis();

    // sends accumulated bitstreams out at max serial rate
    sendFrame();

    // displayTimeSince(sendFrameTime, "sendFrame");
}

#define sliceSet(s) *s |= pinmask;
#define sliceClr(s) *s &= ~pinmask;

void deferredSendFrame(byte pin, byte *bitbuffer){
    // toggle associated bit in associated port buffer array based on data in
    // bitbuffer, representing the 26bit pattern to send on this pin

    byte pinmask;

    // points at appropriate buffer for this pin and sets pinmask
    byte *slicePtr = getBufferAndMask(pin, pinmask);

    sliceSet(slicePtr++);	// start bit
    for(byte i=0; i<26; i++){
        if(bitbuffer[i]){	// send a 1 : L L H
            sliceClr(slicePtr++);
            sliceClr(slicePtr++);
            sliceSet(slicePtr++);
        } else {			// send a 0: L H H
            sliceClr(slicePtr++);
            sliceSet(slicePtr++);
            sliceSet(slicePtr++);
        }
    }
    sliceClr(slicePtr++);	// back to LOW inter frame
}

void sendFrame(){
    // Say it in one precise parallel blast for all strands
    for(byte i = 0; i<FRAMESIZE; i++){
        PORTA = (PORTA & ~portAmask) | (portAframe[i] & portAmask);	// selectively set bits
        PORTC = (PORTC & ~portCmask) | (portCframe[i] & portCmask);	// selectively set bits
        delayMicroseconds(tribit);
    }
    delayMicroseconds(quiettime);	// 30us quiesce
}

///////////////////////////////////////////////////////////////////////////////
// debug utils
///////////////////////////////////////////////////////////////////////////////
// #include <stdarg.h>
// void pf(char *fmt, ... ){
//         char tmp[256]; // resulting string limited to 256 chars
//         va_list args;
//         va_start (args, fmt );
//         vsnprintf(tmp, 256, fmt, args);
//         va_end (args);
//         Serial.print(tmp);
// }

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
	while (lineCount < lines) {
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

void dumpFrame(byte *buffer){
    Serial.print("frame: ");
    for(byte i = 0; i < 26; i++) Serial.print((int) buffer[i]);
}


