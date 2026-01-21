/**
 * FourDimensionalSpiralShell.pde
 * A 4D Shell constructed by extruding a growing hyper-circle along a 4D Logarithmic Spiral.
 */

class FourDSpiralShell extends Shape4D {
  
  // High resolution for long spiral
  int tSteps = 3000;      
  int vSteps = 24;       
  
  // Constants for Path
  float GR = (1.0 + sqrt(5.0)) / 2.0; 
  float E = 2.718281828;              
  float P = PI;                       
  
  float w1 = GR;  
  float w2 = E;   
  float w3 = P;   
  
  // Dynamic Multipliers
  float m1 = 1.0;
  float m2 = 1.0;
  float m3 = 1.0;
  
  // Growth
  float a = 0.05;    
  float b = 0.06; 
  float tubeGrow = 0.06; 
  float tubeScale = 0.6; 
  
  float maxT = 90.0; 
  
  // Animation State
  boolean isFullView = true;
  boolean isAnimating = false;
  float windowPos = 0;
  int windowSize = 500;
  float animSpeed = 5.0; 
  int direction = 1;
  
  FourDSpiralShell() {
    super();
    generateGeometry();
  }
  
  // Method to update multipliers and regenerate
  void updateMultipliers(float nm1, float nm2, float nm3) {
    if (abs(m1 - nm1) > 0.001 || abs(m2 - nm2) > 0.001 || abs(m3 - nm3) > 0.001) {
      m1 = nm1; m2 = nm2; m3 = nm3;
      // Clear old geometry
      localVertices.clear();
      edges.clear();
      generateGeometry();
    }
  }
  
  void generateGeometry() {
    for (int i = 0; i < tSteps; i++) {
      float t = map(i, 0, tSteps-1, 0, maxT);
      
      P4Vector center = getSpiralPoint(t);
      
      float delta = 0.01;
      P4Vector nextP = getSpiralPoint(t + delta);
      
      float tx = nextP.x - center.x;
      float ty = nextP.y - center.y;
      float tz = nextP.z - center.z;
      float tw = nextP.w - center.w;
      float tMag = sqrt(tx*tx + ty*ty + tz*tz + tw*tw);
      tx /= tMag; ty /= tMag; tz /= tMag; tw /= tMag;
      
      float ax = 1, ay = 0, az = 0, aw = 0;
      if (abs(tx) > 0.9) { ax = 0; ay = 1; }
      
      float dot1 = ax*tx + ay*ty + az*tz + aw*tw;
      float n1x = ax - dot1 * tx; float n1y = ay - dot1 * ty; float n1z = az - dot1 * tz; float n1w = aw - dot1 * tw;
      float n1Mag = sqrt(n1x*n1x + n1y*n1y + n1z*n1z + n1w*n1w);
      n1x /= n1Mag; n1y /= n1Mag; n1z /= n1Mag; n1w /= n1Mag;
      
      float bx = 0, by = 1, bz = 0, bw = 0;
      if (ay == 1) { by = 0; bz = 1; }
      
      float dotT = bx*tx + by*ty + bz*tz + bw*tw;
      float t2x = bx - dotT * tx; float t2y = by - dotT * ty; float t2z = bz - dotT * tz; float t2w = bw - dotT * tw;
      
      float dotN1 = t2x*n1x + t2y*n1y + t2z*n1z + t2w*n1w;
      float n2x = t2x - dotN1 * n1x; float n2y = t2y - dotN1 * n1y; float n2z = t2z - dotN1 * n1z; float n2w = t2w - dotN1 * n1w;
      float n2Mag = sqrt(n2x*n2x + n2y*n2y + n2z*n2z + n2w*n2w);
      n2x /= n2Mag; n2y /= n2Mag; n2z /= n2Mag; n2w /= n2Mag;
      
      float rTube = (a * exp(tubeGrow * t)) * tubeScale;
      
      for (int j = 0; j < vSteps; j++) {
        float v = map(j, 0, vSteps, 0, TWO_PI);
        float px = center.x + rTube * (cos(v) * n1x + sin(v) * n2x);
        float py = center.y + rTube * (cos(v) * n1y + sin(v) * n2y);
        float pz = center.z + rTube * (cos(v) * n1z + sin(v) * n2z);
        float pw = center.w + rTube * (cos(v) * n1w + sin(v) * n2w);
        addVertex(px, py, pz, pw);
      }
    }
  }
  
  P4Vector getSpiralPoint(float t) {
    float r = a * exp(b * t);
    // Apply multipliers here
    float theta = (w1 * m1) * t; 
    float phi   = (w2 * m2) * t; 
    float chi   = (w3 * m3) * t;
    
    float x = r * cos(chi);
    float y = r * sin(chi) * cos(phi);
    float z = r * sin(chi) * sin(phi) * cos(theta);
    float w = r * sin(chi) * sin(phi) * sin(theta);
    return new P4Vector(x, y, z, w);
  }
  
  void update() {
    if (!isFullView && isAnimating) {
      windowPos += direction * animSpeed;
      if (windowPos >= tSteps - windowSize) { windowPos = tSteps - windowSize; direction = -1; }
      else if (windowPos <= 0) { windowPos = 0; direction = 1; }
    }
  }
  
  void toggleMode() 
  {
    if (isFullView) 
    { 
      isFullView = false; 
      isAnimating = true; 
      windowPos = 0; 
    }
    else if (isAnimating) {
      isAnimating = false; 
    }
    else {
      isFullView = true; 
    }
  }
  
  String getButtonLabel() 
  {
    if (isFullView) return "Mode: Full View";
    if (isAnimating) return "Mode: Playing";
    return "Mode: Paused";
  }

  @Override
  void render() {
    renderWindow(0, tSteps); // Default to full view
  }

  void renderWindow(int startRing, int ringCount) {
    ArrayList<PVector> projWindow = new ArrayList<PVector>();
    ArrayList<Float> dists = new ArrayList<Float>();
    float minD = Float.MAX_VALUE, maxD = Float.MIN_VALUE;

    for (int k = 0; k <= ringCount; k++) { 
      int r = (startRing + k) % tSteps;
      for (int v = 0; v < vSteps; v++) {
        int idx = r * vSteps + v;
        if(idx >= localVertices.size()) break;
        P4Vector vLoc = localVertices.get(idx);
        P4Vector vWorld = orientation.transform(vLoc);
        projWindow.add(project(vWorld));
        float d = sqrt(vWorld.x*vWorld.x + vWorld.y*vWorld.y + vWorld.z*vWorld.z + vWorld.w*vWorld.w);
        dists.add(d);
        if (d < minD) minD = d; if (d > maxD) maxD = d;
      }
    }
    if (maxD == minD) maxD = minD + 1;

    strokeWeight(2); noFill();
    color cInner = color(255, 255, 255); color cOuter = color(255, 100, 0);   
    float alphaInner = 255; float alphaOuter = 76;
    
    beginShape(LINES);
    
    int numRings = ringCount; 
    
    for (int k = 0; k < numRings; k++) {
      for (int v = 0; v < vSteps; v++) {
        int curr = k * vSteps + v;
        int nextV = k * vSteps + ((v + 1) % vSteps);
        int nextT = (k + 1) * vSteps + v;
        
        if (curr >= projWindow.size()) continue;

        float d = dists.get(curr);
        float t = map(d, minD, maxD, 0, 1);
        color c = lerpColor(cInner, cOuter, t);
        float a = lerp(alphaInner, alphaOuter, t);
        stroke(red(c), green(c), blue(c), a);
        
        PVector p1 = projWindow.get(curr);
        if (nextV < projWindow.size()) {
          PVector p2 = projWindow.get(nextV);
          vertex(p1.x, p1.y, p1.z); vertex(p2.x, p2.y, p2.z);
        }
        
        int actualRingIndex = (startRing + k) % tSteps;
        boolean isPhysicalWrap = (actualRingIndex == tSteps - 1);
        
        if (!isPhysicalWrap && nextT < projWindow.size()) {
           PVector p3 = projWindow.get(nextT);
           vertex(p1.x, p1.y, p1.z); vertex(p3.x, p3.y, p3.z);
        }
      }
    }
    endShape();
    
    noStroke();
    for (int k = 0; k < ringCount; k+=2) { 
       for(int v=0; v<vSteps; v+=2) {
         int idx = k * vSteps + v;
         if (idx >= projWindow.size()) continue;
         PVector p = projWindow.get(idx);
         float t = map(dists.get(idx), minD, maxD, 0, 1);
         color c = lerpColor(cInner, cOuter, t);
         float a = lerp(alphaInner, alphaOuter, t);
         fill(red(c), green(c), blue(c), a);
         pushMatrix(); translate(p.x, p.y, p.z); sphere(3); popMatrix();
       }
    }
  }
}