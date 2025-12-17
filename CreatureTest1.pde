/**
 * FourDimensionalCreatureAlgorithm.pde
 * Implements the "True" 4D Creature using Component Synthesis.
 */

class TrueFourDCreature extends Shape4D {
  
  int tSteps = 180; 
  int vSteps = 16;
  int layers = 3; 
  
  float BOUNDARY_LIMIT = 20.0;
  
  TrueFourDCreature() {
    super();
    generateGeometry();
  }
  
  void generateGeometry() {
    for (int layer = 0; layer < layers; layer++) {
      float layerScale = map(layer, 0, layers-1, 0.5, 1.0); 
      generateLayer(layerScale, layer == layers-1);
    }
  }
  
  void generateLayer(float scale, boolean isOuter) {
    float minT = -6.0 * PI;
    float maxT = 0;
    
    float spiralGrowth = 0.12; 
    float tubeRatio = 0.6;     
    float coneSlope = 3.0;     
    float globalScale = 10.0;   
    
    int startIdx = localVertices.size();
    
    for (int i = 0; i < tSteps; i++) {
      float t = map(i, 0, tSteps-1, minT, maxT);
      
      float R = exp(spiralGrowth * t) * globalScale * scale;
      float rTube = R * tubeRatio;
      
      float spineX = R * cos(t);
      float spineZ = R * sin(t);
      float spineY = 0;
      float spineW = R * coneSlope; 
      
      for (int j = 0; j < vSteps; j++) {
        float v = map(j, 0, vSteps, 0, TWO_PI);
        float radialComp = rTube * cos(v);
        float widthComp  = rTube * sin(v); 
        
        float dx = radialComp * cos(t);
        float dz = radialComp * sin(t);
        float dy = widthComp;
        float dw = (rTube * 0.2) * sin(v);
        
        float fx = spineX + dx;
        float fy = spineY + dy;
        float fz = spineZ + dz;
        float fw = spineW + dw;
        
        fw -= 15.0 * scale; 
        
        addVertex(fx, fy, fz, fw);
      }
    }
    
    // Connectivity
    for (int i = 0; i < tSteps; i++) {
      for (int j = 0; j < vSteps; j++) {
        int current = startIdx + i * vSteps + j;
        int nextV   = startIdx + i * vSteps + ((j + 1) % vSteps);
        addEdge(current, nextV);
        if (i < tSteps - 1) {
          int nextT = startIdx + (i + 1) * vSteps + j;
          addEdge(current, nextT);
        }
      }
    }
  }
}