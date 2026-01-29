/**
 * OSCController.pde
 * Handles Open Sound Control (OSC) communication with Pure Data.
 * Sends orientation matrix, multipliers, and slider state.
 */

import oscP5.*;
import netP5.*;

class OSCController 
{
  
  OscP5 oscP5;
  NetAddress remoteLocation;
  
  // Update rate control (e.g., 30 fps)
  int lastUpdate = 0;
  int updateInterval = 33; 
  
  OSCController(PApplet parent, String ip, int port) 
  {
    // Initialize OSC
    // Note: 'parent' is passed to oscP5 constructor
    oscP5 = new OscP5(parent, 12000); // Listening port (arbitrary)
    remoteLocation = new NetAddress(ip, port); // Sending target
  }
  
  void update(Shape4D targetShape, RangeSlider slider) 
  {
    if (millis() - lastUpdate > updateInterval) {
      sendData(targetShape, slider);
      lastUpdate = millis();
    }
  }
  
  void sendData(Shape4D shape, RangeSlider slider) {
    // 1. Send Orientation Matrix (16 floats)
    OscMessage msgOri = new OscMessage("/orientation");
    if (shape != null && shape.orientation != null) {
      for(int i=0; i<4; i++) {
        for(int j=0; j<4; j++) {
          msgOri.add(shape.orientation.m[i][j]);
        }
      }
    } else {
      // Fallback Identity
      for(int i=0; i<16; i++) msgOri.add((i%5==0)?1.0:0.0); 
    }
    oscP5.send(msgOri, remoteLocation);
    
    // 2. Send Multipliers (if applicable)
    OscMessage msgMult = new OscMessage("/multipliers");
    float m1=1.0, m2=1.0, m3=1.0;
    
    if (shape instanceof FourDSpiral) {
      FourDSpiral s = (FourDSpiral)shape;
      m1 = s.m1; m2 = s.m2; m3 = s.m3;
    } else if (shape instanceof FourDSpiralShell) {
      FourDSpiralShell s = (FourDSpiralShell)shape;
      m1 = s.m1; m2 = s.m2; m3 = s.m3;
    } else if (shape instanceof FourDShellChamber) {
       FourDShellChamber s = (FourDShellChamber)shape;
       m1 = s.m1; m2 = s.m2; m3 = s.m3;
    }
    msgMult.add(m1); msgMult.add(m2); msgMult.add(m3);
    oscP5.send(msgMult, remoteLocation);
    
    // 3. Send Selective Slider Info
    OscMessage msgSel = new OscMessage("/selective");
    if (slider != null) { // Slider object exists in main sketch context
       // If logic to check if it's currently active is needed, pass a boolean.
       // Here we just send the slider's current state regardless of visibility,
       // or user can interpret '0' range as inactive if needed.
       msgSel.add(slider.visibleSteps); // Size
       msgSel.add(slider.startStep);    // Position
       msgSel.add(slider.totalSteps);   // Max (context)
    } else {
       msgSel.add(0); msgSel.add(0); msgSel.add(0);
    }
    oscP5.send(msgSel, remoteLocation);
  }
}