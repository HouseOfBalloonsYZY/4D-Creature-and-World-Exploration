class FourDSpiral extends Shape4D {
  int steps = 3000; 
  float GR = (1.0 + sqrt(5.0)) / 2.0; 
  float E = 2.718281828; float P = PI;                       
  float w1 = GR; float w2 = E; float w3 = P;   
  
  float m1=1.0, m2=1.0, m3=1.0;
  
  float a = 0.15; float b = 0.08; float maxT = 60.0; 
  
  FourDSpiral() { super(); generateGeometry(); }
  
  void updateMultipliers(float nm1, float nm2, float nm3) {
    if (abs(m1 - nm1) > 0.001 || abs(m2 - nm2) > 0.001 || abs(m3 - nm3) > 0.001) {
      m1 = nm1; m2 = nm2; m3 = nm3;
      localVertices.clear(); edges.clear();
      generateGeometry();
    }
  }
  
  void generateGeometry() {
    for (int i = 0; i < steps; i++) {
      float t = map(i, 0, steps-1, 0, maxT);
      float r = a * exp(b * t);
      float theta = w1 * m1 * t; 
      float phi   = w2 * m2 * t; 
      float chi   = w3 * m3 * t;
      float x = r * cos(chi); float y = r * sin(chi) * cos(phi);
      float z = r * sin(chi) * sin(phi) * cos(theta);
      float w = r * sin(chi) * sin(phi) * sin(theta);
      addVertex(x, y, z, w);
    }
  }
  
  @Override
  void render() { renderWindow(0, steps); }

  void renderWindow(int start, int count) {
    ArrayList<PVector> proj = new ArrayList<PVector>();
    ArrayList<Float> dists = new ArrayList<Float>();
    float minD = Float.MAX_VALUE, maxD = Float.MIN_VALUE;
    
    for(int i=0; i<count; i++) {
      int idx = (start + i) % steps;
      P4Vector vWorld = orientation.transform(localVertices.get(idx));
      proj.add(project(vWorld));
      float d = sqrt(vWorld.x*vWorld.x + vWorld.y*vWorld.y + vWorld.z*vWorld.z + vWorld.w*vWorld.w);
      dists.add(d);
      if(d<minD) minD=d; if(d>maxD) maxD=d;
    }
    if (maxD == minD) maxD = minD + 1;
    
    strokeWeight(2); noFill();
    color cInner = color(255, 255, 255); color cOuter = color(255, 100, 0);   
    float alphaInner = 255; float alphaOuter = 76;
    
    beginShape(LINES);
    for(int i=0; i<count-1; i++) {
      float t = map(dists.get(i), minD, maxD, 0, 1);
      color c = lerpColor(cInner, cOuter, t);
      float a = lerp(alphaInner, alphaOuter, t);
      stroke(red(c), green(c), blue(c), a);
      
      PVector p1 = proj.get(i);
      PVector p2 = proj.get(i+1);
      int actualIdx1 = (start + i) % steps;
      if (actualIdx1 != steps - 1) {
        vertex(p1.x, p1.y, p1.z); vertex(p2.x, p2.y, p2.z);
      }
    }
    endShape();
  }
}