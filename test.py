# test OSC control of RV
# tcore = CCore.CCore(pubsub="osc-udp://198.178.187.122:9999")

import CCore
tcore = CCore.CCore(pubsub="osc-udp://192.168.69.69:9999")

black = [0.0, 0.0, 0.0]
white = [1.0, 1.0, 1.0]
red = [1.0, 0.0, 0.0]
green = [0.0, 1.0, 0.0]
blue = [0.0, 0.0, 1.0]
mag = [1.0, 0.0, 0.7]

if(False):
    tcore.send("/bright",[0.5])
    tcore.send("/bright",[1.5])	# should clamp to 1.0
    tcore.send("/reset",[1])	# ignores value
    tcore.send("/hscroll",[0.02])
    tcore.send("/fill",[0.0, 0.0, 0.7])
    tcore.send("/hscroll",[-0.05])
    tcore.send("/reset",[1.0])
    tcore.send("/vscroll",[0.01])
    tcore.send("/bright",[0.7])
    tcore.send("/huescroll",[0.01])
    tcore.send("/setyx",[1,0,1.0, 0.0,0.0])	

def reset():
    tcore.send("/reset",[1.0])

def foo():
    tcore.send("/huescroll",[0.08])
    tcore.send("/fill",[1.0, 0.0, 0.7])


def flash(c1,c2):
    tcore.send("/fill",c1)
    tcore.send("/fill",c2)

def set(x,y,c):
    tcore.send("/setyx",[y,x,c[0],c[1],c[2]])

def debug(level):
    tcore.send("/debug",[level])

import time

def walk(xmax,ymax):
    for y in range(0,ymax):
        for x in range(0, xmax):
            print "x,y=",x,y
            set(x,y,red)
            time.sleep(0.5)
            set(x,y,white)

def allOn():
    tcore.send("/panel",[0,1]);
    tcore.send("/panel",[1,1]);

def driverOff():
    tcore.send("/panel",[1,0]);

def t1():
    reset()
    tcore.send("/huescroll",[0.05])
    tcore.send("/vscroll",[0.05])
