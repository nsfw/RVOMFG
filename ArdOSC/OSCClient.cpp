/*
 
 ArdOSC - OSC Library for Arduino.
  
 -------- Lisence -----------------------------------------------------------
 
 ArdOSC
 
 The MIT License
 
 Copyright (c) 2009 - 2010 recotana( http://recotana.com )　All right reserved
 
 */		

#include <stdlib.h>

#include "OSCCommon/OSCClient.h"
#include "OSCcommon/OSCEncoder.h"

#include <SPI.h>
#include <Client.h>
#include <Udp.h>
#include <utility/w5100.h>
#include <utility/socket.h>

OSCClient::OSCClient(){
//	sockOpen();
}

OSCClient::~OSCClient(){
//	sockClose();
}


void OSCClient::sockOpen(){
	socketNo = 0;
	socket(socketNo, SnMR::UDP, kDummyPortNumber, 0);
	DBG_LOGLN("open UDP socket");
}

void OSCClient::sockClose(){
	DBG_LOGLN("close UDP socket");
	close(socketNo);
}

uint16_t OSCClient::setMessage( OSCMessage *mes){
	
	flushSendData();
	message=mes;
		
	sendData=(uint8_t*)calloc( message->getAllPackSize() ,1 );
		
	OSCEncoder encoder;
	if( encoder.encode(message,sendData) > 0){
		DBG_LOGLN("client set message encode error");
		flushSendData();
		return 1;
	}
	return 0;	
}




uint16_t OSCClient::send(){

	sockOpen();
	sendto(	socketNo ,
		   sendData ,
		   message->allPackSize,
		   message->ipAddress ,
		   message->portNumber );
	sockClose();
	return 0;
}
uint16_t OSCClient::send(OSCMessage *mes){
	
	setMessage(mes);
	return send();
}



void OSCClient::flushSendData(){
	if(sendData!=NULL) free(sendData);
	sendData=NULL;
}
