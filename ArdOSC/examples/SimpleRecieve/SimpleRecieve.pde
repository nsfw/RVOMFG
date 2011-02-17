#include <SPI.h>
#include <Client.h>
#include <Ethernet.h>
#include <Server.h>
#include <Udp.h>

#include <ArdOSC.h>

// --CONFIG-- MODIFIY THIS FOR YOUR SETUP
byte myMac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFF, 0xFE };
byte myIp[]  = { 198, 178, 187, 122 };
int  serverPort  = 9999;
// --CONFIG--
  
OSCServer server;

OSCMessage *rcvMes;

void setup(){ 
    Serial.begin(9600);
    delay(500);
    Serial.println("Hello! ");
    DBG_LOGLN("DEBUG MODE");
    Ethernet.begin(myMac ,myIp); 
    server.sockOpen(serverPort);
}
  
void loop(){
 if(server.available()){
  rcvMes=server.getMessage();
  logMessage();
 }    
}
  
  
void logMessage(){
    uint16_t i;
    byte *ip=rcvMes->getIpAddress();
    
    long int intValue;
    float floatValue;
    char *stringValue;
    
    Serial.print(ip[0],DEC);
    Serial.print(".");
    Serial.print(ip[1],DEC);
    Serial.print(".");
    Serial.print(ip[2],DEC);
    Serial.print(".");
    Serial.print(ip[3],DEC);
    Serial.print(":");
    
    Serial.print(rcvMes->getPortNumber());
    Serial.print(" ");
    Serial.print(rcvMes->getOSCAddress());
    Serial.print(" ");
    Serial.print(rcvMes->getTypeTags());
    Serial.print("--");
    
    for(i=0 ; i<rcvMes->getArgsNum(); i++){
      
     switch( rcvMes->getTypeTag(i) ){
      
        case 'i':       
          intValue = rcvMes->getInteger32(i);
          
          Serial.print(intValue);
          Serial.print(" ");
         break; 
         
         
        case 'f':        
          floatValue = rcvMes->getFloat(i);
        
          Serial.print(floatValue);
          Serial.print(" ");
         break; 
        
        
         case 's':         
          stringValue = rcvMes->getString(i);
         
          Serial.print(stringValue);
          Serial.print(" ");
         break; 

         case 'b':
          Serial.print("BLOB[");
          OSCBlob *b = rcvMes->getBlob(i);
          Serial.print(b->len);
          Serial.print("] ");
          break;          
       
     }
    
      
    }
     Serial.println("");
}
