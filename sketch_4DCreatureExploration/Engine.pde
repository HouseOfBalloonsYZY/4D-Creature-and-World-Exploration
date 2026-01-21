/**
 * FourDimensionalRotation.pde
 * Core Engine: Vectors, Matrices, Shapes, Coordinates, and UI.
 */

float CAMERA_4D_DISTANCE = 50; 
float SCALE_FACTOR = 1000;     

// ... [P4Vector, Matrix4, Shape4D, LocalCoordinateSystem, Button, Dropdown, Slider, VerticalSlider, RangeSlider classes remain unchanged] ...
// I will include the full file content to ensure context is preserved, but focusing on the new class.

class P4Vector {
  float x, y, z, w;
  P4Vector(float x, float y, float z, float w) { this.x = x; this.y = y; this.z = z; this.w = w; }
  P4Vector copy() { return new P4Vector(x, y, z, w); }
}

class Matrix4 {
  float[][] m = new float[4][4];
  Matrix4() { identity(); }
  void identity() {
    for(int i=0; i<4; i++) for(int j=0; j<4; j++) m[i][j] = (i==j)?1:0;
  }
  Matrix4 mult(Matrix4 B) {
    Matrix4 res = new Matrix4();
    for(int i=0; i<4; i++) for(int j=0; j<4; j++) {
      float sum = 0;
      for(int k=0; k<4; k++) sum += this.m[i][k] * B.m[k][j];
      res.m[i][j] = sum;
    }
    return res;
  }
  P4Vector transform(P4Vector v) {
    return new P4Vector(
      m[0][0]*v.x + m[0][1]*v.y + m[0][2]*v.z + m[0][3]*v.w,
      m[1][0]*v.x + m[1][1]*v.y + m[1][2]*v.z + m[1][3]*v.w,
      m[2][0]*v.x + m[2][1]*v.y + m[2][2]*v.z + m[2][3]*v.w,
      m[3][0]*v.x + m[3][1]*v.y + m[3][2]*v.z + m[3][3]*v.w
    );
  }
}

class Shape4D {
  ArrayList<P4Vector> localVertices; 
  ArrayList<int[]> edges; 
  Matrix4 orientation; 

  Shape4D() {
    localVertices = new ArrayList<P4Vector>();
    edges = new ArrayList<int[]>();
    orientation = new Matrix4();
  }

  void addVertex(float x, float y, float z, float w) {
    localVertices.add(new P4Vector(x, y, z, w));
  }

  void addEdge(int i, int j) {
    edges.add(new int[]{i, j});
  }

  PVector project(P4Vector v) {
    float distance = CAMERA_4D_DISTANCE;
    float wDiff = distance - v.w;
    if (abs(wDiff) < 0.001) wDiff = 0.001;
    float scale = 1 / wDiff; 
    return new PVector(v.x * scale * SCALE_FACTOR, v.y * scale * SCALE_FACTOR, v.z * scale * SCALE_FACTOR);
  }
  
  void rotateByDelta(int planeIdx, float theta) {
    Matrix4 rot = new Matrix4(); 
    float c = cos(theta); float s = sin(theta);
    int i = -1, j = -1;
    switch(planeIdx) {
      case 0: i=0; j=1; break; // XY
      case 1: i=0; j=2; break; // XZ
      case 2: i=1; j=2; break; // YZ
      case 3: i=0; j=3; break; // XW
      case 4: i=1; j=3; break; // YW
      case 5: i=2; j=3; break; // ZW
    }
    rot.m[i][i] = c;  rot.m[i][j] = -s;
    rot.m[j][i] = s;  rot.m[j][j] = c;
    this.orientation = this.orientation.mult(rot);
  }

  void render() {
    ArrayList<PVector> projected3D = new ArrayList<PVector>();
    ArrayList<Float> hyperDists = new ArrayList<Float>();
    float minD = Float.MAX_VALUE;
    float maxD = Float.MIN_VALUE;
    
    for (P4Vector vLoc : localVertices) {
      P4Vector vWorld = orientation.transform(vLoc);
      projected3D.add(project(vWorld));
      float d = sqrt(vWorld.x*vWorld.x + vWorld.y*vWorld.y + vWorld.z*vWorld.z + vWorld.w*vWorld.w);
      hyperDists.add(d);
      if (d < minD) minD = d;
      if (d > maxD) maxD = d;
    }
    if (maxD == minD) maxD = minD + 1.0;
    
    strokeWeight(2);
    noFill();
    
    color cInner = color(255, 255, 255); 
    color cOuter = color(255, 100, 0);   
    float alphaInner = 255;
    float alphaOuter = 80; 
    
    beginShape(LINES);
    for (int[] edge : edges) {
      PVector p1 = projected3D.get(edge[0]);
      PVector p2 = projected3D.get(edge[1]);
      float d = hyperDists.get(edge[0]);
      float t = map(d, minD, maxD, 0, 1); 
      t = constrain(t, 0, 1);
      
      color c = lerpColor(cInner, cOuter, t);
      float a = lerp(alphaInner, alphaOuter, t);
      stroke(red(c), green(c), blue(c), a);
      
      vertex(p1.x, p1.y, p1.z);
      vertex(p2.x, p2.y, p2.z);
    }
    endShape();
    
    noStroke();
    for (int i = 0; i < projected3D.size(); i++) {
      PVector p = projected3D.get(i);
      float d = hyperDists.get(i);
      float t = map(d, minD, maxD, 0, 1);
      t = constrain(t, 0, 1);
      color c = lerpColor(cInner, cOuter, t);
      float a = lerp(alphaInner, alphaOuter, t);
      fill(red(c), green(c), blue(c), a);
      
      pushMatrix();
      translate(p.x, p.y, p.z);
      sphere(4); 
      popMatrix();
    }
  }
}

class LocalCoordinateSystem extends Shape4D {
  LocalCoordinateSystem() {
    super();
    addVertex(1, 0, 0, 0); addVertex(0, 1, 0, 0);
    addVertex(0, 0, 1, 0); addVertex(0, 0, 0, 1);
  }
  void render3DAxes() {
    float axisLength = 20.0; 
    String[] names = {"X", "Y", "Z", "W"};
    int[] colors = { color(255, 50, 50), color(50, 255, 50), color(50, 100, 255), color(255, 50, 255) };
    strokeWeight(2); textSize(24);
    P4Vector centerWorld = orientation.transform(new P4Vector(0,0,0,0));
    for (int i = 0; i < 4; i++) {
      P4Vector vBase = new P4Vector(0,0,0,0);
      if(i==0) vBase.x=1; if(i==1) vBase.y=1; if(i==2) vBase.z=1; if(i==3) vBase.w=1;
      P4Vector vDir = orientation.transform(vBase);
      P4Vector vPos = new P4Vector(centerWorld.x + vDir.x*axisLength, centerWorld.y + vDir.y*axisLength, centerWorld.z + vDir.z*axisLength, centerWorld.w + vDir.w*axisLength);
      P4Vector vNeg = new P4Vector(centerWorld.x - vDir.x*axisLength, centerWorld.y - vDir.y*axisLength, centerWorld.z - vDir.z*axisLength, centerWorld.w - vDir.w*axisLength);
      PVector pPos = project(vPos); PVector pNeg = project(vNeg);
      stroke(colors[i]); fill(colors[i]);
      line(pNeg.x, pNeg.y, pNeg.z, pPos.x, pPos.y, pPos.z);
      pushMatrix(); translate(pPos.x, pPos.y, pPos.z); text(names[i], 10, 10); sphere(3); popMatrix();
    }
  }
  void renderAllSystems(int screenW, int screenH) {
    int sysX = screenW - 250; int topY = 150; int spacing = (screenH - 200) / 5; 
    renderHUD(sysX, topY, new boolean[]{true, true, true, true}, "XYZW");
    renderHUD(sysX, topY + spacing, new boolean[]{true, true, true, false}, "XYZ");
    renderHUD(sysX, topY + spacing*2, new boolean[]{true, true, false, true}, "XYW");
    renderHUD(sysX, topY + spacing*3, new boolean[]{true, false, true, true}, "XZW"); 
    renderHUD(sysX, topY + spacing*4, new boolean[]{false, true, true, true}, "YZW");
  }
  void renderHUD(float x, float y, boolean[] mask, String title) {
    pushMatrix(); translate(x, y);
    String[] names = {"X", "Y", "Z", "W"};
    int[] colors = { color(255, 50, 50), color(50, 255, 50), color(50, 100, 255), color(255, 50, 255) };
    strokeWeight(2);
    for (int i = 0; i < 4; i++) {
      if (!mask[i]) continue;
      P4Vector vWorld = orientation.transform(localVertices.get(i));
      PVector p = project(vWorld);
      float rawMag = dist(0, 0, p.x, p.y);
      float sx = p.x * (60.0 / (rawMag + 1.0));
      float sy = p.y * (60.0 / (rawMag + 1.0));
      stroke(colors[i]); fill(colors[i]);
      line(0, 0, sx, sy);
      pushMatrix(); translate(sx, sy); rotate(atan2(sy, sx)); line(0, 0, -5, -3); line(0, 0, -5, 3); popMatrix();
    }
    fill(200); textAlign(CENTER); textSize(12); text(title, 0, 100); 
    float stackX = 80; float startStackY = -30; 
    for (int i = 0; i < 4; i++) {
      if (!mask[i]) continue; 
      P4Vector vWorld = orientation.transform(localVertices.get(i));
      PVector p = project(vWorld);
      float mag2D = dist(0, 0, p.x, p.y);
      boolean isParallel = (mag2D > 10.0) && (abs(p.z) < 50); 
      boolean pointingOut = p.z > 0; 
      textAlign(LEFT, CENTER); fill(colors[i]); text(names[i], stackX, startStackY);
      if (isParallel) { textAlign(CENTER, CENTER); text("//", stackX + 30, startStackY); } 
      else { drawDepthSymbol(stackX + 30, startStackY, pointingOut, colors[i]); }
      startStackY += 20;
    }
    popMatrix();
  }
  void drawDepthSymbol(float x, float y, boolean out, int col) {
    noFill(); stroke(col); strokeWeight(1); ellipse(x, y, 12, 12);
    if (out) { fill(col); noStroke(); ellipse(x, y, 4, 4); } else { stroke(col); line(x - 3, y - 3, x + 3, y + 3); line(x + 3, y - 3, x - 3, y + 3); }
  }
}

class Button {
  float x, y, w, h; String label;
  Button(float x, float y, float w, float h, String label) { this.x = x; this.y = y; this.w = w; this.h = h; this.label = label; }
  boolean isClicked() { return mouseX >= x && mouseX <= x+w && mouseY >= y && mouseY <= y+h; }
  void update() {}
  void display() { stroke(255); if (isClicked() && mousePressed) fill(100); else fill(50); rect(x, y, w, h, 5); fill(255); textAlign(CENTER, CENTER); text(label, x + w/2, y + h/2); }
}
class Dropdown {
  float x, y, w, h; String label; String[] options; boolean isOpen = false;
  Dropdown(float x, float y, float w, float h, String label, String[] options) { this.x = x; this.y = y; this.w = w; this.h = h; this.label = label; this.options = options; }
  int handleClick() {
    if (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h) { isOpen = !isOpen; return -1; }
    if (isOpen) {
      float itemH = h;
      for (int i = 0; i < options.length; i++) {
        float itemY = y + h + (i * itemH);
        if (mouseX >= x && mouseX <= x + w && mouseY >= itemY && mouseY <= itemY + itemH) return i;
      }
    }
    return -1;
  }
  void display() {
    stroke(255); fill(50); rect(x, y, w, h); fill(255); textAlign(LEFT, CENTER); text(label, x + 10, y + h/2);
    fill(255); if (isOpen) triangle(x+w-20, y+h-10, x+w-10, y+h-10, x+w-15, y+10); else triangle(x+w-20, y+10, x+w-10, y+10, x+w-15, y+h-10);
    if (isOpen) {
      for (int i = 0; i < options.length; i++) {
        float itemY = y + h + (i * h);
        if (mouseX >= x && mouseX <= x + w && mouseY >= itemY && mouseY <= itemY + h) fill(100); else fill(30);
        stroke(100); rect(x, itemY, w, h); fill(255); if (options[i].startsWith("--")) fill(255, 200, 0); text(options[i], x + 10, itemY + h/2);
      }
    }
  }
}
class Slider {
  float x, y, w, h; float min, max, val; String label; boolean dragging = false; boolean isEditing = false; String inputString = "";
  boolean showDegrees = true; 
  
  Slider(float x, float y, float w, float h, float min, float max, String label) { this.x = x; this.y = y; this.w = w; this.h = h; this.min = min; this.max = max; this.label = label; this.val = 0; }
  boolean checkFocus() {
    if (mouseX >= x + w && mouseX <= x + w + 60 && mouseY >= y && mouseY <= y + h) { isEditing = true; inputString = ""; dragging = false; return true; }
    isEditing = false; return false;
  }
  void handleKey(char k, int code) {
    if (!isEditing) return;
    if (code == ENTER || code == RETURN) { try { float angleDeg = float(inputString); if (Float.isNaN(angleDeg)) val = 0; else { if (showDegrees) { if (angleDeg > 360) angleDeg = 360; if (angleDeg < -360) angleDeg = -360; val = radians(angleDeg); } else { val = constrain(angleDeg, min, max); } } } catch (Exception e) { val = 0; } isEditing = false; } else if (code == BACKSPACE) { if (inputString.length() > 0) inputString = inputString.substring(0, inputString.length()-1); } else if ((k >= '0' && k <= '9') || k == '.' || k == '-') { inputString += k; }
  }
  void update() { if (mousePressed && !isEditing) { if (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h) dragging = true; } else dragging = false; if (dragging) { val = map(mouseX, x, x+w, min, max); val = constrain(val, min, max); } }
  void display() { fill(255); textSize(14); textAlign(LEFT, BOTTOM); text(label, x, y - 5); stroke(255); strokeWeight(1); fill(40); rect(x, y, w, h); float pos = map(val, min, max, x, x+w); noStroke(); fill(0, 255, 255); rect(x + 1, y + 1, pos - x - 1, h - 2); fill(255); textSize(14); textAlign(LEFT, CENTER); if (isEditing) { fill(0, 0, 100); rect(x + w + 10, y, 60, h); fill(255); text(inputString + "|", x + w + 15, y + h/2); } else { String displayVal = showDegrees ? nf(degrees(val), 0, 1) + "°" : nf(val, 0, 2); text(displayVal, x + w + 15, y + h/2); } }
}
class VerticalSlider {
  float x, y, w, h; float min, max, val; String label; boolean dragging = false;
  VerticalSlider(float x, float y, float w, float h, float min, float max, String label) { this.x = x; this.y = y; this.w = w; this.h = h; this.min = min; this.max = max; this.label = label; this.val = (min + max) / 2; }
  void update() { if (mousePressed) { if (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h) dragging = true; } else dragging = false; if (dragging) { val = map(mouseY, y + h, y, min, max); val = constrain(val, min, max); } }
  void display() { fill(255); textSize(12); textAlign(CENTER, BOTTOM); text(label, x + w/2, y - 5); stroke(255); strokeWeight(1); fill(40); rect(x, y, w, h); float pos = map(val, min, max, y + h, y); noStroke(); fill(0, 255, 100); rect(x + 1, pos, w - 2, (y + h) - pos - 1); fill(255); textAlign(CENTER, TOP); text(nf(val, 0, 2), x + w/2, y + h + 5); }
}
class RangeSlider {
  float x, y, w, h; int totalSteps; int visibleSteps = 250; int startStep = 0; boolean dragging = false; boolean isEditing = false; String inputString = "";
  RangeSlider(float x, float y, float w, float h, int totalSteps) { this.x = x; this.y = y; this.w = w; this.h = h; this.totalSteps = totalSteps; }
  boolean checkFocus() { if (mouseX >= x + w && mouseX <= x + w + 60 && mouseY >= y && mouseY <= y + h) { isEditing = true; inputString = ""; dragging = false; return true; } isEditing = false; return false; }
  void handleKey(char k, int code) { if (!isEditing) return; if (code == ENTER || code == RETURN) { try { int val = int(inputString); if (val < 50) val = 50; if (val > 1000) val = 1000; visibleSteps = val; } catch (Exception e) { visibleSteps = 250; } isEditing = false; } else if (code == BACKSPACE) { if (inputString.length() > 0) inputString = inputString.substring(0, inputString.length()-1); } else if (k >= '0' && k <= '9') { inputString += k; } }
  void update() { if (mousePressed && !isEditing) { if (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h) dragging = true; } else dragging = false; if (dragging) { float normX = constrain(mouseX, x, x + w); float t = (normX - x) / w; startStep = (int)(t * totalSteps); } }
  void display() { fill(255); textSize(14); textAlign(LEFT, BOTTOM); text("View Range (" + visibleSteps + " steps)", x, y - 5); stroke(255); strokeWeight(1); fill(40); rect(x, y, w, h); float barWidthRatio = (float)visibleSteps / (float)totalSteps; float displayBarW = w * barWidthRatio; float startRatio = (float)startStep / (float)totalSteps; float startX = x + startRatio * w; noStroke(); fill(0, 255, 255); if (startX + displayBarW <= x + w) { rect(startX, y + 2, displayBarW, h - 4); } else { float firstPartW = (x + w) - startX; float secondPartW = displayBarW - firstPartW; rect(startX, y + 2, firstPartW, h - 4); rect(x, y + 2, secondPartW, h - 4); } fill(255); textAlign(LEFT, CENTER); if (isEditing) { fill(0, 0, 100); rect(x + w + 10, y, 60, h); fill(255); text(inputString + "|", x + w + 15, y + h/2); } else text(visibleSteps, x + w + 15, y + h/2); }
}

// --- NEW CLASS: MultiplierSlider ---
class MultiplierSlider {
  float x, y, w, h;
  float val; // The multiplier value (0.1 to 10.0)
  String label;
  boolean dragging = false;
  boolean isEditing = false;
  String inputString = "";
  
  MultiplierSlider(float x, float y, float w, float h, String label) {
    this.x = x; this.y = y; this.w = w; this.h = h;
    this.label = label;
    this.val = 1.0;
  }
  
  boolean checkFocus() {
    if (mouseX >= x + w && mouseX <= x + w + 60 && mouseY >= y && mouseY <= y + h) {
      isEditing = true; inputString = ""; dragging = false; return true;
    }
    isEditing = false; return false;
  }
  
  void handleKey(char k, int code) {
    if (!isEditing) return;
    if (code == ENTER || code == RETURN) {
      try {
        float v = float(inputString);
        if (Float.isNaN(v)) val = 1.0;
        else val = constrain(v, 0.1, 10.0);
      } catch (Exception e) { val = 1.0; }
      isEditing = false;
    } else if (code == BACKSPACE) {
      if (inputString.length() > 0) inputString = inputString.substring(0, inputString.length()-1);
    } else if ((k >= '0' && k <= '9') || k == '.' || k == '-') {
      inputString += k;
    }
  }
  
  void update() {
    if (mousePressed && !isEditing) {
      if (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h) dragging = true;
    } else dragging = false;
    
    if (dragging) {
      float normX = constrain(mouseX, x, x + w);
      float t = (normX - x) / w; // 0.0 to 1.0
      
      // Split Logic:
      // t < 0.5: Map 0.0-0.5 to Value 0.1-1.0 (Linear interpolation of the value itself)
      // Wait, user asked for linear speed.
      // Left side: "sliding half way left will mean multiply by 1/5, full left 1/10"
      // Center (t=0.5) is 1.0. Left (t=0.0) is 0.1.
      // Right side: "sliding half way right is 5.5, full right is 10".
      
      if (t < 0.5) {
        // Map t(0.0 -> 0.5) to val(0.1 -> 1.0)
        float localT = map(t, 0.0, 0.5, 0.0, 1.0);
        val = lerp(0.1, 1.0, localT);
      } else {
        // Map t(0.5 -> 1.0) to val(1.0 -> 10.0)
        float localT = map(t, 0.5, 1.0, 0.0, 1.0);
        val = lerp(1.0, 10.0, localT);
      }
    }
  }
  
  void display() {
    fill(255); textSize(14); textAlign(LEFT, BOTTOM); text(label, x, y - 5);
    stroke(255); strokeWeight(1); fill(40); rect(x, y, w, h);
    
    // Reverse mapping for display
    float t;
    if (val <= 1.0) {
      t = map(val, 0.1, 1.0, 0.0, 0.5);
    } else {
      t = map(val, 1.0, 10.0, 0.5, 1.0);
    }
    
    float pos = x + t * w;
    noStroke(); fill(255, 200, 50); // Orange-ish for multipliers
    rect(x, y + 1, pos - x, h - 2); // Bar fills from left? Or should it handle centered?
    // Let's make it standard left-to-right fill.
    
    // Draw Center Mark
    stroke(100); line(x + w/2, y, x + w/2, y + h);
    
    fill(255); textSize(14); textAlign(LEFT, CENTER);
    if (isEditing) {
      fill(0, 0, 100); rect(x + w + 10, y, 60, h); 
      fill(255); text(inputString + "|", x + w + 15, y + h/2);
    } else {
      text("x" + nf(val, 0, 2), x + w + 15, y + h/2);
    }
  }
}