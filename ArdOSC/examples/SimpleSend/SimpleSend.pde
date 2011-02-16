#include <Ethernet.h>

#include <ArdOSC.h>

byte myMac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte myIp[]  = { 192, 168, 0, 255 };

byte destIp[] =  { 192, 168, 0, 5 };
int  destPort = 10000;



char oscAdr[] = "/ard/test/123";
char oscAdr2[] = "/ard/test2/abc";

int      iCount  = 0;      //**** <-- int is 16bit(2byte)  need cast to long int!!
long int liCount = 0;      // long int is 32bi(4byte)
float    fCount  = 0.0;    // float is 32bit(4byte)
char     str[]   = "abcd"; // string is any byte 

OSCClient client;

void setup(){
  
  Serial.begin(19200);

  Ethernet.begin(myMac ,myIp);  
  
}

void loop(){
  
  sendProcess();
  
  OSCMessage mes;  //スコープを抜けられないのでリリースする必要がある
  
  mes.setAddress(destIp,destPort);
  mes.setOSCMessage(oscAdr2 ,"s" ,"test test");
  
  client.send(&mes);
  
  mes.flush();  //リリース
  
  delay(100);
}


void sendProcess(){
  
   
  long int tmp=(long int)iCount; // int -> long int
  
  OSCMessage message;  //スコープを抜けるとデストラクタによりリリースされます
  
  message.setAddress(destIp,destPort);
  message.setOSCMessage(oscAdr ,"iifs" ,&tmp ,&liCount ,&fCount ,str);
  
  client.send(&message);


  if(iCount++  > 1000)  iCount =0;
  if(liCount++ > 1000)  liCount=0;
  fCount += 0.1;
  if(fCount  > 100.0) fCount =0.0;
  
}
