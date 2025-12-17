/**
 * FourDimensionalCreature.pde
 * Procedural generation of 4D biomorphic forms.
 */

// -------------------------------------------------------------------------
// CLASS: CephalopodShell
// -------------------------------------------------------------------------
class CephalopodShell extends Shape4D {
  
  // Tuned for "Solid Cone" illusion + Nautilus P2 look
  int tSteps = 240;        // High resolution for smooth, solid look
  int vSteps = 16;         // Tube cross-section
  int chamberInterval = 20; 
  
  // To make it look like a solid cone in side view, the tube radius must 
  // be large enough relative to the growth rate to fill the gaps between whorls.
  float spiralGrowth = 0.11;   
  float tubeRadiusBase = 0.75; // Thicker to fuse whorls together
  float coneLength = 3.5;      // Ratio of W-length to Radius
  float sizeMultiplier = 1.5;  // Reduced global scale (1.5x)
  
  CephalopodShell() {
    super();
    generateGeometry();
  }
  
  void generateGeometry() {
    // Range: Start deep negative to close the center hole
    float minT = -8.0 * PI; 
    float maxT = 0;
    
    for (int i = 0; i < tSteps; i++) {
      float t = map(i, 0, tSteps-1, minT, maxT);
      
      // Logarithmic Growth
      float R = exp(spiralGrowth * t) * sizeMultiplier;
      
      // Tube Radius
      float rTube = R * tubeRadiusBase;
      
      // --- CENTER CURVE (Spine) ---
      // XZ Plane Spiral (Wraps around Y)
      float cx = R * cos(t); 
      float cz = R * sin(t);
      float cy = 0; 
      
      // --- W-Axis ---
      // Linear growth with R creates the Conical Envelope in X-Z-W space.
      // This is what makes it look like a straight cone when rotated.
      float cw = R * coneLength; 
      
      // --- SEPTUM GENERATION ---
      boolean isSeptum = (i % chamberInterval == 0) && (i < tSteps - 10);
      int centerIdx = -1;
      
      if (isSeptum) {
        addVertex(cx, cy, cz, cw);
        centerIdx = localVertices.size() - 1;
      }
      
      // --- TUBE SURFACE ---
      int ringStartIdx = localVertices.size();
      
      for (int j = 0; j < vSteps; j++) {
        float v = map(j, 0, vSteps, 0, TWO_PI);
        
        // Construct Tube
        // We align the tube cross-section to the radial vector and Y-axis
        float radialComp = rTube * cos(v);
        float widthComp  = rTube * sin(v);
        
        float ox = radialComp * cos(t); 
        float oz = radialComp * sin(t);
        float oy = widthComp;           
        
        // Small W thickness to give the "Cuttlefish bone" (flat view) some volume
        float ow = (rTube * 0.15) * sin(v);
        
        addVertex(cx + ox, cy + oy, cz + oz, cw + ow);
      }
      
      // --- CONNECTIVITY ---
      for (int j = 0; j < vSteps; j++) {
        int currentIdx = ringStartIdx + j;
        int nextV = ringStartIdx + ((j + 1) % vSteps);
        addEdge(currentIdx, nextV);
        if (i > 0) {
          int prevRingStart = ringStartIdx - vSteps;
          if ((i-1) % chamberInterval == 0 && (i-1) < tSteps - 10) prevRingStart -= 1; 
          addEdge(currentIdx, prevRingStart + j);
        }
        if (isSeptum) addEdge(currentIdx, centerIdx);
      }
    }
  }
  
  // Override render to apply custom gradient
  void render() {
    ArrayList<PVector> projected3D = new ArrayList<PVector>();
    ArrayList<Float> progressList = new ArrayList<Float>(); // Store progress 0..1 for color
    
    for (int i = 0; i < localVertices.size(); i++) {
      P4Vector vLoc = localVertices.get(i);
      P4Vector vWorld = orientation.transform(vLoc);
      projected3D.add(project(vWorld));
      
      // Calculate progress based on vertex index approx
      // This maps the gradient along the spiral length
      float progress = map(i, 0, localVertices.size(), 0, 1);
      progressList.add(progress);
    }
    
    strokeWeight(2);
    noFill();
    
    // Coral Red Color
    color cWhite = color(255, 255, 255);
    color cCoral = color(255, 127, 80);
    
    beginShape(LINES);
    for (int[] edge : edges) {
      PVector p1 = projected3D.get(edge[0]);
      PVector p2 = projected3D.get(edge[1]);
      
      // Gradient based on growth progress (i) rather than depth
      float prog = progressList.get(edge[0]);
      
      // Interpolate: Inner (Old) = White, Outer (New) = Coral
      // Or inverse? Let's make Outer = Coral
      stroke(lerpColor(cWhite, cCoral, prog));

      vertex(p1.x, p1.y, p1.z);
      vertex(p2.x, p2.y, p2.z);
    }
    endShape();
    
    noStroke();
    for (int i = 0; i < projected3D.size(); i++) {
      PVector p = projected3D.get(i);
      float prog = progressList.get(i);
      fill(lerpColor(cWhite, cCoral, prog));
      
      pushMatrix();
      translate(p.x, p.y, p.z);
      sphere(6);
      popMatrix();
    }
  }
}
