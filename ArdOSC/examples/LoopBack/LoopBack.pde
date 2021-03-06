#include <Ethernet.h>

#include <ArdOSC.h>


byte myMac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte myIp[]  = { 192, 168, 0, 10 };
int  serverPort  = 10000;

int destPort=12000;
  
OSCServer server;
OSCClient client;

OSCMessage *rcvMes;

void setup(){ 
  
 Serial.begin(19200);
 
 Ethernet.begin(myMac ,myIp); 
 
 server.sockOpen(serverPort);
   
}
  
void loop(){

 if(server.available()){
   
  rcvMes=server.getMessage();
                               //送信元IPはrcvMes.ipAddressポインタに格納されている。
  rcvMes->setPortNumber(destPort);
  
  client.send(rcvMes);

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
       
     }
    
      
    }
     Serial.println("");
}
