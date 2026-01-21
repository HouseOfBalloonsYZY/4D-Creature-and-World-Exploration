/**
 * FourDimensionalManifold.pde
 * Definitions for 4D Manifolds (Scaled to -10 to 10)
 */

class KleinBottle extends Shape4D {
  int uSteps = 40; int vSteps = 20; float R = 6.0; float P = 2.0; 
  KleinBottle() { super(); generateGeometry(); }
  void generateGeometry() {
    for (int i = 0; i < uSteps; i++) {
      float u = map(i, 0, uSteps, 0, TWO_PI);
      for (int j = 0; j < vSteps; j++) {
        float v = map(j, 0, vSteps, 0, TWO_PI);
        float x = (R + P * cos(v)) * cos(u);
        float y = (R + P * cos(v)) * sin(u);
        float z = P * sin(v) * cos(u/2);
        float w = P * sin(v) * sin(u/2);
        addVertex(x, y, z, w);
      }
    }
    for (int i = 0; i < uSteps; i++) {
      for (int j = 0; j < vSteps; j++) {
        int currentIdx = i * vSteps + j;
        int nextV = (j + 1) % vSteps;
        addEdge(currentIdx, i * vSteps + nextV);
        if (i < uSteps - 1) addEdge(currentIdx, (i + 1) * vSteps + j);
        else addEdge(currentIdx, (vSteps - 1 - j + vSteps) % vSteps);
      }
    }
  }
}

class CliffordTorus extends Shape4D {
  int uSteps = 30; int vSteps = 30;
  CliffordTorus() { super(); generateGeometry(); }
  void generateGeometry() {
    float scale = 8.0; 
    for(int i=0; i<uSteps; i++) {
      float u = map(i, 0, uSteps, 0, TWO_PI);
      for(int j=0; j<vSteps; j++) {
        float v = map(j, 0, vSteps, 0, TWO_PI);
        addVertex(scale*cos(u), scale*sin(u), scale*cos(v), scale*sin(v));
      }
    }
    for(int i=0; i<uSteps; i++) {
      for(int j=0; j<vSteps; j++) {
        int curr = i * vSteps + j;
        addEdge(curr, ((i + 1) % uSteps) * vSteps + j);
        addEdge(curr, i * vSteps + ((j + 1) % vSteps));
      }
    }
  }
}

class RealProjectivePlane extends Shape4D {
  int uSteps = 30; int vSteps = 30;
  RealProjectivePlane() { super(); generateGeometry(); }
  void generateGeometry() {
    float scale = 10.0; 
    for(int i=0; i<=uSteps; i++) {
      float u = map(i, 0, uSteps, 0, PI);
      for(int j=0; j<vSteps; j++) { 
        float v = map(j, 0, vSteps, 0, PI);
        float x = scale * sin(u) * cos(v);
        float y = scale * sin(u) * sin(v);
        float z = scale * cos(u) * cos(2*v);
        float w = scale * cos(u) * sin(2*v);
        addVertex(x, y, z, w);
      }
    }
    for(int i=0; i<uSteps; i++) {
      for(int j=0; j<vSteps; j++) {
        int curr = i * vSteps + j;
        addEdge(curr, i * vSteps + ((j + 1) % vSteps));
        addEdge(curr, (i + 1) * vSteps + j);
      }
    }
  }
}

class HypersphereGrid extends Shape4D {
  int steps = 12; 
  HypersphereGrid() { super(); generateGeometry(); }
  void generateGeometry() {
    float scale = 10.0; 
    for(int i=0; i<steps; i++) {
      float xi = map(i, 0, steps-1, 0, HALF_PI);
      for(int j=0; j<steps; j++) {
        float eta = map(j, 0, steps, 0, TWO_PI);
        for(int k=0; k<steps; k++) {
          float phi = map(k, 0, steps, 0, TWO_PI);
          float x = scale * cos(xi) * cos(eta);
          float y = scale * cos(xi) * sin(eta);
          float z = scale * sin(xi) * cos(phi);
          float w = scale * sin(xi) * sin(phi);
          addVertex(x, y, z, w);
        }
      }
    }
    for(int i=0; i<steps; i++) {
      for(int j=0; j<steps; j++) {
        for(int k=0; k<steps; k++) {
          int curr = (i * steps * steps) + (j * steps) + k;
          addEdge(curr, (i * steps * steps) + (j * steps) + ((k + 1) % steps));
          addEdge(curr, (i * steps * steps) + ((j + 1) % steps) * steps + k);
          if(i < steps - 1) addEdge(curr, ((i + 1) * steps * steps) + (j * steps) + k);
        }
      }
    }
  }
}

class Spherinder extends Shape4D {
  int latSteps = 16; int lonSteps = 16; int wSteps = 8;    
  Spherinder() { super(); generateGeometry(); }
  void generateGeometry() {
    float r = 7.0; 
    float len = 10.0; 
    for (int w = 0; w < wSteps; w++) {
      float wVal = map(w, 0, wSteps-1, -len, len);
      for (int i = 0; i <= latSteps; i++) {
        float lat = map(i, 0, latSteps, -HALF_PI, HALF_PI);
        for (int j = 0; j < lonSteps; j++) {
          float lon = map(j, 0, lonSteps, 0, TWO_PI);
          addVertex(r * cos(lat) * cos(lon), r * cos(lat) * sin(lon), r * sin(lat), wVal);
        }
      }
    }
    int sphereVerts = (latSteps + 1) * lonSteps;
    for (int w = 0; w < wSteps; w++) {
      int wOffset = w * sphereVerts;
      for (int i = 0; i < latSteps; i++) {
        for (int j = 0; j < lonSteps; j++) {
          int curr = wOffset + i * lonSteps + j;
          int nextLon = wOffset + i * lonSteps + ((j + 1) % lonSteps);
          int nextLat = wOffset + (i + 1) * lonSteps + j;
          addEdge(curr, nextLon); 
          addEdge(curr, nextLat); 
          if (w < wSteps - 1) addEdge(curr, curr + sphereVerts);
        }
      }
    }
  }
}