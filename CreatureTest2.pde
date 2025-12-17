/**
 * FourDimensionalCreatureTest2.pde
 * Defines a composite 4D object made of 3 disjoint 3D shapes.
 * MODIFIED: Components are now centered at 0 on their hidden axis.
 */

class CreatureComposite extends Shape4D {
  
  float S = 10.0; // Still used for scaling relative size
  
  CreatureComposite() {
    super();
    generateNautilus();
    generateCameroceras();
    generateSepiaBone();
  }
  
  // 1. NAUTILUS SHELL 
  // Defined in XYZ Space. 
  // Hidden Dimension: W = 0
  void generateNautilus() {
    int tSteps = 120;
    int vSteps = 12;
    float maxT = 0;
    float minT = -5.0 * PI;
    float spiralGrowth = 0.17;
    float tubeRatio = 0.55;
    float scale = 0.8 * S; 
    
    int startIdx = localVertices.size();
    
    for (int i = 0; i < tSteps; i++) {
      float t = map(i, 0, tSteps-1, minT, maxT);
      float R = exp(spiralGrowth * t) * scale;
      float rTube = R * tubeRatio;
      
      float cx = R * cos(t);
      float cz = R * sin(t);
      
      for (int j = 0; j <= vSteps; j++) {
        float v = map(j, 0, vSteps, 0, TWO_PI);
        float radial = rTube * cos(v);
        float width  = rTube * sin(v);
        
        float x = cx + radial * cos(t);
        float z = cz + radial * sin(t);
        float y = width; 
        
        // MODIFICATION: W is now 0
        float w = 0; 
        
        addVertex(x, y, z, w);
      }
    }
    addGridEdges(startIdx, tSteps, vSteps + 1);
  }
  
  // 2. CAMEROCERAS CONE 
  // Defined in XZW Space.
  // Hidden Dimension: Y = 0
  void generateCameroceras() {
    int lenSteps = 20;
    int radSteps = 16;
    float maxRadius = 3.0;
    int startIdx = localVertices.size();
    
    for (int i = 0; i < lenSteps; i++) {
      float w = map(i, 0, lenSteps-1, S, -S);
      float r = map(w, S, -S, 0, maxRadius);
      
      for (int j = 0; j <= radSteps; j++) {
        float theta = map(j, 0, radSteps, 0, TWO_PI);
        float x = r * cos(theta);
        float z = r * sin(theta);
        
        // MODIFICATION: Y is now 0
        float y = 0; 
        
        addVertex(x, y, z, w);
      }
    }
    addGridEdges(startIdx, lenSteps, radSteps + 1);
  }
  
  // 3. CUTTLEFISH BONE
  // Defined in YZW Space.
  // Hidden Dimension: X = 0
  void generateSepiaBone() {
    int uSteps = 20; 
    int vSteps = 16; 
    float length = S;   
    float width = 4.0;  
    float thick = 1.5;  
    int startIdx = localVertices.size();
    
    for (int i = 0; i <= uSteps; i++) {
      float u = map(i, 0, uSteps, 0, PI);
      for (int j = 0; j <= vSteps; j++) {
        float v = map(j, 0, vSteps, 0, TWO_PI);
        float w = length * cos(u);
        float r = sin(u);
        float y = width * r * cos(v);
        float z = thick * r * sin(v);
        
        // MODIFICATION: X is now 0
        float x = 0; 
        
        addVertex(x, y, z, w);
      }
    }
    addGridEdges(startIdx, uSteps + 1, vSteps + 1);
  }
  
  void addGridEdges(int startOffset, int rows, int cols) {
    for (int i = 0; i < rows - 1; i++) {
      for (int j = 0; j < cols - 1; j++) {
        int curr = startOffset + i * cols + j;
        int nextRow = curr + cols;
        int nextCol = curr + 1;
        addEdge(curr, nextCol);
        addEdge(curr, nextRow);
      }
    }
  }
}