/*
 
 ArdOSC - OSC Library for Arduino.
 
 -------- Lisence -----------------------------------------------------------
 
 ArdOSC
 
 The MIT License
 
 Copyright (c) 2009 - 2010 recotana( http://recotana.com )　All right reserved
 
 */	


#ifndef OSCServer_h
#define OSCServer_h


#include "OSCcommon.h"

#include "OSCDecoder.h"
#include "OSCMessage.h"


class OSCServer{
	
private:
	
	uint8_t socketNo;
	
	uint8_t rcvData[kMaxRecieveData];
	
	OSCMessage message;
	OSCDecoder decoder;
	
	int16_t decodeProcess();

	
	void flushRcvData();
	
	
	
public:
	
	void sockOpen(uint16_t _recievePort);
	void sockClose();
	void availableFlush();
	
	bool available();
	
	
	OSCMessage::OSCMessage *getMessage();


};


#endif