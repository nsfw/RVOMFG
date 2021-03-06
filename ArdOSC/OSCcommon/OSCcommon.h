/*
 
 ArdOSC - OSC Library for Arduino.
 
 -------- Lisence -----------------------------------------------------------
 
 ArdOSC
 
 The MIT License
 
 Copyright (c) 2009 - 2010 recotana( http://recotana.com )　All right reserved
 
 */	



#ifndef OSCcommon_h
#define OSCcommon_h

//======== user define ==============

#define _USE_FLOAT_
#define _USE_STRING_
#define _USE_BLOB_

// Note: MaxReceiveData should be a function of the values setup in W5100.h

//======== application maximums =====

#define kMaxArgument	16
#define kMaxRecieveData	4096
#define kMaxOSCAdrCharactor	255
#define kMaxStringCharactor	255

//======== user define  end  ========

extern "C" {
#include <inttypes.h>
}

#ifdef _DEBUG_
#include "HardwareSerial.h"
#endif

#ifdef _DEBUG_
#define DBG_LOGLN(...)	Serial.println(__VA_ARGS__)
#define DBG_LOG(...)	Serial.print(__VA_ARGS__)

#else
#define DBG_LOGLN
#define DBG_LOG
#endif




#endif
