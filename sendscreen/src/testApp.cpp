#include "testApp.h"

extern "C" {
#include "macGlutfix.h"
}

//--------------------------------------------------------------
void testApp::setup(){
	
	//CGContextRef cgctx = NULL;
	//ofSetVerticalSync(true);
	tex.allocate(300,300, GL_RGBA);
	
	//ofSetFrameRate(30);
}


//--------------------------------------------------------------
void testApp::update(){

	int w = 300;
	int h = 300;
	
	uint32 * data = pixelsBelowWindow(ofGetWindowPositionX(),ofGetWindowPositionY(),w,h);
    // convert to GL_RGBA format
    for (int i = 0; i < w*h; i++){
        // GL_RGBA = (uint32) AABBGGRR
        // NSImage = (uint32) BBGGRRAA
        data[i] = (data[i]>>8) | 0xff000000; 	// scoot down 8 bits - full alpha
    }

	if (data!= NULL)
        tex.loadData((unsigned char *) data, 300, 300, GL_RGBA);
}

//--------------------------------------------------------------
void testApp::draw(){
	tex.draw(0,0, ofGetWidth(), ofGetHeight());
}

//--------------------------------------------------------------
void testApp::keyPressed(int key){

	
}

//--------------------------------------------------------------
void testApp::keyReleased(int key){

}

//--------------------------------------------------------------
void testApp::mouseMoved(int x, int y ){

}

//--------------------------------------------------------------
void testApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void testApp::mousePressed(int x, int y, int button){

}

//--------------------------------------------------------------
void testApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void testApp::windowResized(int w, int h){

}

