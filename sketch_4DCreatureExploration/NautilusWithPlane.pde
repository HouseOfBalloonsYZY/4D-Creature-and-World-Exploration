/**
 * FourDimensionalCreatureSolid.pde
 * Renders the Cephalopod using solid triangle strips for a skin/shell look.
 */

class SolidCephalopodShell extends Shape4D {
  
  // Same tuned parameters as the wireframe version
  int tSteps = 240;        
  int vSteps = 16;         
  
  float spiralGrowth = 0.11;   
  float tubeRadiusBase = 0.75; 
  float coneLength = 3.5;      
  float sizeMultiplier = 1.5;  
  
  SolidCephalopodShell() {
    super();
    generateGeometry();
  }
  
  void generateGeometry() {
    float minT = -8.0 * PI; 
    float maxT = 0;
    
    for (int i = 0; i < tSteps; i++) {
      float t = map(i, 0, tSteps-1, minT, maxT);
      float R = exp(spiralGrowth * t) * sizeMultiplier;
      float rTube = R * tubeRadiusBase;
      
      float cx = R * cos(t); 
      float cz = R * sin(t);
      float cy = 0; 
      float cw = R * coneLength; 
      
      for (int j = 0; j < vSteps; j++) {
        float v = map(j, 0, vSteps, 0, TWO_PI);
        
        float radialComp = rTube * cos(v);
        float widthComp  = rTube * sin(v);
        
        float ox = radialComp * cos(t); 
        float oz = radialComp * sin(t);
        float oy = widthComp;           
        float ow = (rTube * 0.15) * sin(v);
        
        addVertex(cx + ox, cy + oy, cz + oz, cw + ow);
      }
    }
    // Note: We don't strictly need to generate 'edges' list for solid render,
    // as we rely on the grid structure (tSteps, vSteps) in the render method.
  }
  
  // Override render to draw SOLID SURFACES
  void render() {
    // 1. Calculate Rotated & Projected Points
    ArrayList<PVector> projected3D = new ArrayList<PVector>();
    ArrayList<Float> progressList = new ArrayList<Float>(); 
    
    for (int i = 0; i < localVertices.size(); i++) {
      P4Vector vLoc = localVertices.get(i);
      P4Vector vWorld = orientation.transform(vLoc);
      projected3D.add(project(vWorld));
      float progress = map(i, 0, localVertices.size(), 0, 1);
      progressList.add(progress);
    }
    
    // 2. Setup Lighting for Solids
    lights(); 
    // Add a directional light for better depth perception
    directionalLight(200, 200, 200, 0.5, 1, -0.5);
    ambientLight(60, 60, 60);
    
    noStroke(); // Turn off wireframe lines
    
    // Coral Red Colors
    color cWhite = color(255, 255, 255);
    color cCoral = color(255, 127, 80);
    
    // 3. Draw Triangle Strips
    // We iterate through the rings (tSteps) and connect each ring to the next
    for (int i = 0; i < tSteps - 1; i++) {
      
      beginShape(TRIANGLE_STRIP);
      
      for (int j = 0; j <= vSteps; j++) {
        // Wrap around the tube (modulo)
        int u = j % vSteps;
        
        int idx1 = i * vSteps + u;       // Current ring
        int idx2 = (i + 1) * vSteps + u; // Next ring
        
        PVector p1 = projected3D.get(idx1);
        PVector p2 = projected3D.get(idx2);
        
        // Color Gradient
        float prog = progressList.get(idx1);
        fill(lerpColor(cWhite, cCoral, prog));
        
        // Add vertices to strip
        vertex(p1.x, p1.y, p1.z);
        vertex(p2.x, p2.y, p2.z);
      }
      
      endShape();
    }
  }
}
