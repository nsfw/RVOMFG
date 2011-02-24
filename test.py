# test OSC control of RV
# tcore = CCore.CCore(pubsub="osc-udp://198.178.187.122:9999")

import CCore
tcore = CCore.CCore(pubsub="osc-udp://192.168.69.69:9999")

def black = [0.0, 0.0, 0.0]
def white = [1.0, 1.0, 1.0]
def red = [1.0, 0.0, 0.0]
def green = [0.0, 1.0, 0.0]
def blue = [0.0, 0.0, 1.0]
def mag = [1.0, 0.0, 0.7]

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
// new
    tcode.send("/setyx",1,0,mag)

def foo():
    tcore.send("/huescroll",[0.0])
    tcore.send("/fill",[1.0, 0.0, 0.7])
    tcore.send("/fill",[0.0, 0.0, 0.7])

def flash(c1,c2):
    tcore.send("/fill",c1)
    tcore.send("/fill",c2)


