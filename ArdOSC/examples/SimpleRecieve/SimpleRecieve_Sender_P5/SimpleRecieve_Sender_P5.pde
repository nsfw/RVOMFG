/**
 * oscP5oscArgument by andreas schlegel
 * example shows how to parse incoming osc messages "by hand".
 * it is recommended to take a look at oscP5plug for an alternative way to parse messages.
 * oscP5 website at http://www.sojamo.de/oscP5
 */

import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

int a;
float b;

void setup() {
    background(0);

  oscP5 = new OscP5(this,12000);
  
  
  myRemoteLocation = new NetAddress("192.168.0.10",10000);
  
 
 a=0;
 b=0.0;
  
}

void draw() {
   
   sender();
  
  delay(100);
  
}

void sender(){
  a+=1;
  b+=0.1;
  if(a>100000) a=0;
  if(b>100000.0) b=0.0;
  
  OscMessage myMessage = new OscMessage("/test");
  
  myMessage.add(a); 
  myMessage.add(b); 
  myMessage.add("some text");

  oscP5.send(myMessage, myRemoteLocation);
}



void oscEvent(OscMessage theOscMessage) {

      int firstValue = theOscMessage.get(0).intValue();  // get the first osc argument
      float secondValue = theOscMessage.get(1).floatValue(); // get the second osc argument
      String thirdValue = theOscMessage.get(2).stringValue(); // get the third osc argument

      print("OSCadr:"+theOscMessage.addrPattern());
      print(" typetag:"+theOscMessage.typetag());
      println(" values: "+firstValue+", "+secondValue+", "+thirdValue);
 
 
}
