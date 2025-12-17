/**
 * FourDimensionalGeometry.pde
 * Definitions for specific 4D shapes (Scaled to -10 to 10)
 */

class Tesseract extends Shape4D {
  Tesseract() { super(); generateGeometry(); }
  void generateGeometry() {
    float s = 10.0; // Scaled to 10
    for (int i = 0; i < 16; i++) {
      float x = ((i & 1) == 0) ? -s : s;
      float y = ((i & 2) == 0) ? -s : s;
      float z = ((i & 4) == 0) ? -s : s;
      float w = ((i & 8) == 0) ? -s : s;
      addVertex(x, y, z, w);
    }
    for (int i = 0; i < 16; i++) {
      for (int j = i + 1; j < 16; j++) {
        int diff = i ^ j;
        if (diff == 1 || diff == 2 || diff == 4 || diff == 8) addEdge(i, j);
      }
    }
  }
}

class Pentachoron extends Shape4D {
  Pentachoron() { super(); generateGeometry(); }
  void generateGeometry() {
    float s = 6.0; // 4h*6 = 24/2.2 = 10.7 approx
    float h = 1.0 / sqrt(5);
    addVertex( s,  s,  s, -h*s);
    addVertex( s, -s, -s, -h*s);
    addVertex(-s,  s, -s, -h*s);
    addVertex(-s, -s,  s, -h*s);
    addVertex( 0,  0,  0,  4*h*s);
    int numVerts = localVertices.size();
    for (int i = 0; i < numVerts; i++) for (int j = i + 1; j < numVerts; j++) addEdge(i, j);
  }
}

class Hexadecachoron extends Shape4D {
  Hexadecachoron() { super(); generateGeometry(); }
  void generateGeometry() {
    float s = 10.0; 
    addVertex( s, 0, 0, 0); addVertex(-s, 0, 0, 0);
    addVertex( 0, s, 0, 0); addVertex( 0,-s, 0, 0);
    addVertex( 0, 0, s, 0); addVertex( 0, 0,-s, 0);
    addVertex( 0, 0, 0, s); addVertex( 0, 0, 0,-s);
    
    float thetaXW = -QUARTER_PI; 
    float thetaYW = -0.6154797; 
    float thetaZW = -PI/6;
    for (P4Vector v : localVertices) {
      float x = v.x, w = v.w;
      v.x = x * cos(thetaXW) - w * sin(thetaXW);
      v.w = x * sin(thetaXW) + w * cos(thetaXW);
    }
    for (P4Vector v : localVertices) {
      float y = v.y, w = v.w;
      v.y = y * cos(thetaYW) - w * sin(thetaYW);
      v.w = y * sin(thetaYW) + w * cos(thetaYW);
    }
    for (P4Vector v : localVertices) {
      float z = v.z, w = v.w;
      v.z = z * cos(thetaZW) - w * sin(thetaZW);
      v.w = z * sin(thetaZW) + w * cos(thetaZW);
    }
    
    int numVerts = localVertices.size();
    for (int i = 0; i < numVerts; i++) {
      for (int j = i + 1; j < numVerts; j++) {
        boolean isOpposite = (i % 2 == 0 && j == i + 1);
        if (!isOpposite) addEdge(i, j);
      }
    }
  }
}

class Icositetrachoron extends Shape4D {
  Icositetrachoron() { super(); generateGeometry(); }
  void generateGeometry() {
    float s = 10.0; 
    float[] vals = {s, s, 0, 0}; 
    ArrayList<float[]> signedSets = new ArrayList<float[]>();
    for(int i=0; i<16; i++) {
      float[] v = new float[4];
      for(int k=0; k<4; k++) v[k] = ((i >> k) & 1) == 0 ? vals[k] : -vals[k];
      signedSets.add(v);
    }
    int[][] perms = {
      {0,1,2,3}, {0,1,3,2}, {0,2,1,3}, {0,2,3,1}, {0,3,1,2}, {0,3,2,1},
      {1,0,2,3}, {1,0,3,2}, {1,2,0,3}, {1,2,3,0}, {1,3,0,2}, {1,3,2,0},
      {2,0,1,3}, {2,0,3,1}, {2,1,0,3}, {2,1,3,0}, {2,3,0,1}, {2,3,1,0},
      {3,0,1,2}, {3,0,2,1}, {3,1,0,2}, {3,1,2,0}, {3,2,0,1}, {3,2,1,0}
    };
    for (float[] signedV : signedSets) {
      for (int i = 0; i < perms.length; i++) {
        int[] p = perms[i];
        addUniqueVertex(signedV[p[0]], signedV[p[1]], signedV[p[2]], signedV[p[3]]);
      }
    }
    float targetDistSq = 2.0 * s * s; 
    float epsilon = 5.0;
    int numVerts = localVertices.size();
    for (int i = 0; i < numVerts; i++) {
      for (int j = i + 1; j < numVerts; j++) {
        float d = distSq(localVertices.get(i), localVertices.get(j));
        if (abs(d - targetDistSq) < epsilon) addEdge(i, j);
      }
    }
  }
  float distSq(P4Vector v1, P4Vector v2) { return sq(v1.x - v2.x) + sq(v1.y - v2.y) + sq(v1.z - v2.z) + sq(v1.w - v2.w); }
  void addUniqueVertex(float x, float y, float z, float w) {
    for (P4Vector v : localVertices) {
      if (abs(v.x - x) < 0.1 && abs(v.y - y) < 0.1 && abs(v.z - z) < 0.1 && abs(v.w - w) < 0.1) return;
    }
    addVertex(x, y, z, w);
  }
}

class Hecatonicosachoron extends Shape4D {
  Hecatonicosachoron() { super(); generateGeometry(); }
  void generateGeometry() {
    float s = 4.0; // Scaled to reach ~10-12
    float phi = (1.0 + sqrt(5.0)) / 2.0; 
    float invPhi = 1.0 / phi;            
    float phi2 = phi * phi;              
    float invPhi2 = 1.0 / phi2;          
    
    addPermutations(new float[]{2*s, 2*s, 0, 0}, false); 
    addPermutations(new float[]{sqrt(5)*s, 1*s, 1*s, 1*s}, false);
    addPermutations(new float[]{phi*s, phi*s, phi*s, invPhi2*s}, false);
    addPermutations(new float[]{invPhi*s, invPhi*s, invPhi*s, phi2*s}, false);
    addPermutations(new float[]{phi2*s, 1*s, invPhi2*s, 0}, true);
    addPermutations(new float[]{sqrt(5)*s, phi*s, invPhi*s, 0}, true);
    
    int count = localVertices.size();
    float[] nearestDists = new float[count];
    for (int i = 0; i < count; i++) {
      float minDist = Float.MAX_VALUE;
      P4Vector v1 = localVertices.get(i);
      for (int j = 0; j < count; j++) {
        if (i == j) continue;
        float d = distSq(v1, localVertices.get(j));
        if (d > 0.1 && d < minDist) minDist = d;
      }
      nearestDists[i] = minDist;
    }
    java.util.Arrays.sort(nearestDists);
    float targetEdgeSq = nearestDists[count / 2];
    float epsilon = 2.0; 
    for (int i = 0; i < count; i++) {
      for (int j = i + 1; j < count; j++) {
        float d = distSq(localVertices.get(i), localVertices.get(j));
        if (abs(d - targetEdgeSq) < epsilon) addEdge(i, j);
      }
    }
  }
  float distSq(P4Vector v1, P4Vector v2) { return sq(v1.x - v2.x) + sq(v1.y - v2.y) + sq(v1.z - v2.z) + sq(v1.w - v2.w); }
  void addPermutations(float[] vals, boolean evenOnly) {
    ArrayList<float[]> signedSets = new ArrayList<float[]>();
    for(int i=0; i<16; i++) {
      float[] s = new float[4];
      for(int k=0; k<4; k++) {
        if(vals[k] == 0) s[k] = 0; 
        else s[k] = ((i >> k) & 1) == 0 ? vals[k] : -vals[k];
      }
      signedSets.add(s);
    }
    int[][] perms = {
      {0,1,2,3}, {0,1,3,2}, {0,2,1,3}, {0,2,3,1}, {0,3,1,2}, {0,3,2,1},
      {1,0,2,3}, {1,0,3,2}, {1,2,0,3}, {1,2,3,0}, {1,3,0,2}, {1,3,2,0},
      {2,0,1,3}, {2,0,3,1}, {2,1,0,3}, {2,1,3,0}, {2,3,0,1}, {2,3,1,0},
      {3,0,1,2}, {3,0,2,1}, {3,1,0,2}, {3,1,2,0}, {3,2,0,1}, {3,2,1,0}
    };
    for (float[] signedV : signedSets) {
      for (int i = 0; i < perms.length; i++) {
        int[] p = perms[i];
        if (evenOnly && !isEvenPermutation(p)) continue;
        addUniqueVertex(signedV[p[0]], signedV[p[1]], signedV[p[2]], signedV[p[3]]);
      }
    }
  }
  boolean isEvenPermutation(int[] p) {
    int inversions = 0;
    for (int i = 0; i < p.length; i++) for (int j = i + 1; j < p.length; j++) if (p[i] > p[j]) inversions++;
    return (inversions % 2 == 0);
  }
  void addUniqueVertex(float x, float y, float z, float w) {
    for (P4Vector v : localVertices) {
      if (abs(v.x - x) < 0.1 && abs(v.y - y) < 0.1 && abs(v.z - z) < 0.1 && abs(v.w - w) < 0.1) return;
    }
    addVertex(x, y, z, w);
  }
}

class Hexacosichoron extends Shape4D {
  Hexacosichoron() { super(); generateGeometry(); }
  void generateGeometry() {
    float s = 5.0; // Scaled
    float phi = (1.0 + sqrt(5.0)) / 2.0;
    float invPhi = 1.0 / phi;
    addPermutations(new float[]{1*s, 1*s, 1*s, 1*s}, false);
    addPermutations(new float[]{2*s, 0, 0, 0}, false);
    addPermutations(new float[]{phi*s, 1*s, invPhi*s, 0}, true);
    
    int count = localVertices.size();
    float[] nearestDists = new float[count];
    for (int i = 0; i < count; i++) {
      float minDist = Float.MAX_VALUE;
      P4Vector v1 = localVertices.get(i);
      for (int j = 0; j < count; j++) {
        if (i == j) continue;
        float d = distSq(v1, localVertices.get(j));
        if (d > 0.1 && d < minDist) minDist = d;
      }
      nearestDists[i] = minDist;
    }
    java.util.Arrays.sort(nearestDists);
    float targetEdgeSq = nearestDists[count / 2];
    float epsilon = 5.0; 
    for (int i = 0; i < count; i++) {
      for (int j = i + 1; j < count; j++) {
        float d = distSq(localVertices.get(i), localVertices.get(j));
        if (abs(d - targetEdgeSq) < epsilon) addEdge(i, j);
      }
    }
  }
  float distSq(P4Vector v1, P4Vector v2) { return sq(v1.x - v2.x) + sq(v1.y - v2.y) + sq(v1.z - v2.z) + sq(v1.w - v2.w); }
  void addPermutations(float[] vals, boolean evenOnly) {
    ArrayList<float[]> signedSets = new ArrayList<float[]>();
    for(int i=0; i<16; i++) {
      float[] s = new float[4];
      for(int k=0; k<4; k++) {
        if(vals[k] == 0) s[k] = 0; 
        else s[k] = ((i >> k) & 1) == 0 ? vals[k] : -vals[k];
      }
      signedSets.add(s);
    }
    int[][] perms = {
      {0,1,2,3}, {0,1,3,2}, {0,2,1,3}, {0,2,3,1}, {0,3,1,2}, {0,3,2,1},
      {1,0,2,3}, {1,0,3,2}, {1,2,0,3}, {1,2,3,0}, {1,3,0,2}, {1,3,2,0},
      {2,0,1,3}, {2,0,3,1}, {2,1,0,3}, {2,1,3,0}, {2,3,0,1}, {2,3,1,0},
      {3,0,1,2}, {3,0,2,1}, {3,1,0,2}, {3,1,2,0}, {3,2,0,1}, {3,2,1,0}
    };
    for (float[] signedV : signedSets) {
      for (int i = 0; i < perms.length; i++) {
        int[] p = perms[i];
        if (evenOnly && !isEvenPermutation(p)) continue;
        addUniqueVertex(signedV[p[0]], signedV[p[1]], signedV[p[2]], signedV[p[3]]);
      }
    }
  }
  boolean isEvenPermutation(int[] p) {
    int inversions = 0;
    for (int i = 0; i < p.length; i++) for (int j = i + 1; j < p.length; j++) if (p[i] > p[j]) inversions++;
    return (inversions % 2 == 0);
  }
  void addUniqueVertex(float x, float y, float z, float w) {
    for (P4Vector v : localVertices) {
      if (abs(v.x - x) < 0.1 && abs(v.y - y) < 0.1 && abs(v.z - z) < 0.1 && abs(v.w - w) < 0.1) return;
    }
    addVertex(x, y, z, w);
  }
}