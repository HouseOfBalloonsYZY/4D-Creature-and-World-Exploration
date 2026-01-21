/**
 * FourDimensionalShellChamber.pde
 * A 4D Shell with internal "Soft Cell" anatomy.
 * Features a continuous outer skin and internal chamber walls (septa).
 */

class FourDShellChamber extends Shape4D {
  
  // Resolution
  int tSteps = 100;     // Steps along the spiral path
  int uSteps = 12;      // Longitude of tube cross-section
  int vSteps = 24;      // Latitude of tube cross-section
  int chamberInterval = 15; // Distance (in tSteps) between septa
  
  // 4D Path Constants
  float GR = (1.0 + sqrt(5.0)) / 2.0; 
  float E = 2.718281828;              
  float P = PI;                       
  
  float w1 = GR;  
  float w2 = E;   
  float w3 = P;   
  
  // Multipliers (Dynamic)
  float m1 = 1.0, m2 = 1.0, m3 = 1.0;
  
  // Growth
  float a = 0.05;    
  float b = 0.06;    
  float tubeGrow = 0.06; 
  float tubeScale = 0.6; 
  float maxT = 90.0; 
  
  // Internal storage for skin vertices to help connectivity
  ArrayList<P4Vector> skinVertices;
  
  FourDShellChamber() {
    super();
    skinVertices = new ArrayList<P4Vector>();
    generateGeometry();
  }
  
  void updateMultipliers(float nm1, float nm2, float nm3) {
    if (abs(m1 - nm1) > 0.001 || abs(m2 - nm2) > 0.001 || abs(m3 - nm3) > 0.001) {
      m1 = nm1; m2 = nm2; m3 = nm3;
      localVertices.clear(); edges.clear(); skinVertices.clear();
      generateGeometry();
    }
  }
  
  void generateGeometry() {
    // 1. Generate the Spine (Path) and Basis Frames
    ArrayList<P4Vector> spine = new ArrayList<P4Vector>();
    ArrayList<P4Vector[]> frames = new ArrayList<P4Vector[]>();
    
    for (int i = 0; i < tSteps; i++) {
      float t = map(i, 0, tSteps-1, 0, maxT);
      P4Vector pos = getSpiralPoint(t);
      spine.add(pos);
      
      // Calculate Frame (Tangent + Normal Basis)
      float delta = 0.01;
      P4Vector nextPos = getSpiralPoint(t + delta);
      P4Vector T = sub(nextPos, pos);
      normalize(T);
      frames.add(getNormalBasis(T));
    }
    
    // 2. Generate Continuous Skin
    // We iterate through the spine and create rings
    int skinStartIdx = localVertices.size();
    
    for (int i = 0; i < tSteps; i++) {
      float tVal = map(i, 0, tSteps-1, 0, maxT);
      float R = (a * exp(tubeGrow * tVal)) * tubeScale;
      
      P4Vector center = spine.get(i);
      P4Vector[] basis = frames.get(i);
      P4Vector N1 = basis[0];
      P4Vector N2 = basis[1];
      P4Vector N3 = basis[2]; // Unused for 2D surface skin, used for volume
      
      // Generate Ring Surface (Sphere cross-section in 4D is... a sphere surface?)
      // Actually, a tube in 4D is a surface x line. 
      // The cross section of a 3-manifold tube in 4D is a 2-sphere.
      // So we iterate u and v to cover the sphere surface.
      
      for (int u = 0; u < uSteps; u++) {
        float theta = map(u, 0, uSteps, 0, TWO_PI);
        for (int v = 0; v <= vSteps; v++) {
          float phi = map(v, 0, vSteps, 0, PI);
          
          // Spherical coordinates on the normal 3-space
          // x_loc, y_loc, z_loc along N1, N2, N3
          float sx = sin(phi) * cos(theta);
          float sy = sin(phi) * sin(theta);
          float sz = cos(phi);
          
          // P = Center + R * (sx*N1 + sy*N2 + sz*N3)
          P4Vector p = new P4Vector(
            center.x + R * (sx*N1.x + sy*N2.x + sz*N3.x),
            center.y + R * (sx*N1.y + sy*N2.y + sz*N3.y),
            center.z + R * (sx*N1.z + sy*N2.z + sz*N3.z),
            center.w + R * (sx*N1.w + sy*N2.w + sz*N3.w)
          );
          
          addVertex(p.x, p.y, p.z, p.w);
        }
      }
    }
    
    // Connect Skin Mesh
    int vertsPerRing = uSteps * (vSteps + 1);
    
    for (int i = 0; i < tSteps; i++) {
      for (int u = 0; u < uSteps; u++) {
        for (int v = 0; v <= vSteps; v++) {
          int currRel = (u * (vSteps+1)) + v;
          int currAbs = skinStartIdx + (i * vertsPerRing) + currRel;
          
          // 1. Connect Latitudinal (Along V)
          if (v < vSteps) {
            addEdge(currAbs, currAbs + 1);
          }
          
          // 2. Connect Longitudinal (Along U - Ring loop)
          int nextURel = (((u + 1) % uSteps) * (vSteps+1)) + v;
          int nextUAbs = skinStartIdx + (i * vertsPerRing) + nextURel;
          addEdge(currAbs, nextUAbs);
          
          // 3. Connect Path (Along T - Tube length)
          if (i < tSteps - 1) {
            int nextTAbs = currAbs + vertsPerRing;
            addEdge(currAbs, nextTAbs);
          }
        }
      }
    }
    
    // 3. Generate Internal Septa (Walls)
    // We add a separate grid of points INSIDE the tube at intervals
    for (int i = chamberInterval; i < tSteps - 5; i += chamberInterval) {
      generateSeptum(i, spine.get(i), frames.get(i));
    }
  }
  
  void generateSeptum(int tIndex, P4Vector center, P4Vector[] basis) {
    float tVal = map(tIndex, 0, tSteps-1, 0, maxT);
    float R = (a * exp(tubeGrow * tVal)) * tubeScale;
    
    P4Vector N1 = basis[0]; 
    P4Vector N2 = basis[1]; 
    P4Vector N3 = basis[2];
    
    // Generate a solid volume (layers of spheres) or a spiderweb grid?
    // Let's do a few concentric rings inside to represent the wall
    int radialLayers = 3;
    int septumStartIdx = localVertices.size();
    
    for (int r = 1; r <= radialLayers; r++) {
      float rFrac = (float)r / (float)(radialLayers + 1); // < 1.0 to stay inside
      float rCurr = R * rFrac;
      
      // Generate Ring at this radius
      for (int u = 0; u < uSteps; u++) {
        float theta = map(u, 0, uSteps, 0, TWO_PI);
        for (int v = 0; v <= vSteps; v++) {
          float phi = map(v, 0, vSteps, 0, PI);
          
          float sx = sin(phi) * cos(theta);
          float sy = sin(phi) * sin(theta);
          float sz = cos(phi);
          
          // Slight bulge logic? (Optional, kept simple for now)
          P4Vector p = new P4Vector(
            center.x + rCurr * (sx*N1.x + sy*N2.x + sz*N3.x),
            center.y + rCurr * (sx*N1.y + sy*N2.y + sz*N3.y),
            center.z + rCurr * (sx*N1.z + sy*N2.z + sz*N3.z),
            center.w + rCurr * (sx*N1.w + sy*N2.w + sz*N3.w)
          );
          addVertex(p.x, p.y, p.z, p.w);
        }
      }
    }
    
    // Connect Septum
    int vertsPerRing = uSteps * (vSteps+1);
    
    for (int r = 0; r < radialLayers; r++) {
      int layerOffset = r * vertsPerRing;
      for (int u = 0; u < uSteps; u++) {
        for (int v = 0; v <= vSteps; v++) {
           int curr = septumStartIdx + layerOffset + (u * (vSteps+1)) + v;
           
           // Ring connections (Grid)
           if (v < vSteps) addEdge(curr, curr+1);
           int nextU = septumStartIdx + layerOffset + (((u+1)%uSteps)*(vSteps+1)) + v;
           addEdge(curr, nextU);
           
           // Radial connections (Outward)
           if (r < radialLayers - 1) {
             addEdge(curr, curr + vertsPerRing);
           }
        }
      }
    }
  }
  
  // --- HELPERS (Same as Spiral) ---
  P4Vector getSpiralPoint(float t) {
    float r = a * exp(b * t);
    float theta = w1 * m1 * t; 
    float phi   = w2 * m2 * t; 
    float chi   = w3 * m3 * t;
    float x = r * cos(chi);
    float y = r * sin(chi) * cos(phi);
    float z = r * sin(chi) * sin(phi) * cos(theta);
    float w = r * sin(chi) * sin(phi) * sin(theta);
    return new P4Vector(x, y, z, w);
  }
  
  P4Vector sub(P4Vector a, P4Vector b) { return new P4Vector(a.x-b.x, a.y-b.y, a.z-b.z, a.w-b.w); }
  void normalize(P4Vector v) { float m = sqrt(v.x*v.x + v.y*v.y + v.z*v.z + v.w*v.w); if (m > 0) { v.x/=m; v.y/=m; v.z/=m; v.w/=m; } }
  
  P4Vector[] getNormalBasis(P4Vector T) {
    P4Vector[] basis = new P4Vector[3];
    P4Vector v1 = new P4Vector(1, 0, 0, 0);
    if (abs(T.x) > 0.9) v1 = new P4Vector(0, 1, 0, 0);
    float dot1 = v1.x*T.x + v1.y*T.y + v1.z*T.z + v1.w*T.w;
    basis[0] = new P4Vector(v1.x - dot1*T.x, v1.y - dot1*T.y, v1.z - dot1*T.z, v1.w - dot1*T.w);
    normalize(basis[0]);
    P4Vector v2 = new P4Vector(0, 1, 0, 0);
    if (abs(T.y) > 0.9) v2 = new P4Vector(0, 0, 1, 0);
    float dotT2 = v2.x*T.x + v2.y*T.y + v2.z*T.z + v2.w*T.w;
    P4Vector temp2 = new P4Vector(v2.x - dotT2*T.x, v2.y - dotT2*T.y, v2.z - dotT2*T.z, v2.w - dotT2*T.w);
    float dotN1_2 = temp2.x*basis[0].x + temp2.y*basis[0].y + temp2.z*basis[0].z + temp2.w*basis[0].w;
    basis[1] = new P4Vector(temp2.x - dotN1_2*basis[0].x, temp2.y - dotN1_2*basis[0].y, temp2.z - dotN1_2*basis[0].z, temp2.w - dotN1_2*basis[0].w);
    normalize(basis[1]);
    P4Vector v3 = new P4Vector(0, 0, 1, 0);
    if (abs(T.z) > 0.9) v3 = new P4Vector(0, 0, 0, 1);
    float dotT3 = v3.x*T.x + v3.y*T.y + v3.z*T.z + v3.w*T.w;
    P4Vector temp3 = new P4Vector(v3.x - dotT3*T.x, v3.y - dotT3*T.y, v3.z - dotT3*T.z, v3.w - dotT3*T.w);
    float dotN1_3 = temp3.x*basis[0].x + temp3.y*basis[0].y + temp3.z*basis[0].z + temp3.w*basis[0].w;
    temp3 = new P4Vector(temp3.x - dotN1_3*basis[0].x, temp3.y - dotN1_3*basis[0].y, temp3.z - dotN1_3*basis[0].z, temp3.w - dotN1_3*basis[0].w);
    float dotN2_3 = temp3.x*basis[1].x + temp3.y*basis[1].y + temp3.z*basis[1].z + temp3.w*basis[1].w;
    basis[2] = new P4Vector(temp3.x - dotN2_3*basis[1].x, temp3.y - dotN2_3*basis[1].y, temp3.z - dotN2_3*basis[1].z, temp3.w - dotN2_3*basis[1].w);
    normalize(basis[2]);
    return basis;
  }
  
  // Custom Render for Windowed View
  void renderWindow(int start, int count) {
    // Since we generate skin + septa, standard windowing by "steps" is complex
    // because vertices are not linear.
    // However, the main skin vertices ARE generated linearly first.
    // Total Skin Verts = tSteps * (uSteps * (vSteps+1))
    
    // We will render a window of the SKIN.
    // Septa rendering in window mode is tricky, let's just render skin for animation.
    
    ArrayList<PVector> proj = new ArrayList<PVector>();
    ArrayList<Float> dists = new ArrayList<Float>();
    float minD = Float.MAX_VALUE, maxD = Float.MIN_VALUE;
    
    int vertsPerRing = uSteps * (vSteps + 1);
    int totalSkinVerts = tSteps * vertsPerRing;
    
    // Collect skin vertices for window
    for(int k=0; k<=count; k++) {
      int r = (start + k) % tSteps;
      int startV = r * vertsPerRing;
      for(int i=0; i<vertsPerRing; i++) {
         int idx = startV + i;
         if (idx >= localVertices.size()) break;
         P4Vector vWorld = orientation.transform(localVertices.get(idx));
         proj.add(project(vWorld));
         float d = sqrt(vWorld.x*vWorld.x + vWorld.y*vWorld.y + vWorld.z*vWorld.z + vWorld.w*vWorld.w);
         dists.add(d);
         if(d<minD) minD=d; if(d>maxD) maxD=d;
      }
    }
    if (maxD == minD) maxD = minD + 1;
    
    strokeWeight(1); noFill();
    color cInner = color(255, 255, 255); color cOuter = color(255, 100, 0);   
    float alphaInner = 255; float alphaOuter = 76;
    
    beginShape(LINES);
    for(int k=0; k<count; k++) {
      // Re-implement grid connectivity for the window buffer
      int ringOffset = k * vertsPerRing;
      
      for (int u = 0; u < uSteps; u++) {
        for (int v = 0; v <= vSteps; v++) {
           int currRel = (u * (vSteps+1)) + v;
           int currIdx = ringOffset + currRel;
           
           if (currIdx >= proj.size()) continue;

           // Color
           float t = map(dists.get(currIdx), minD, maxD, 0, 1);
           color c = lerpColor(cInner, cOuter, t);
           float a = lerp(alphaInner, alphaOuter, t);
           stroke(red(c), green(c), blue(c), a);
           
           PVector p1 = proj.get(currIdx);
           
           // Lat
           if (v < vSteps) {
              PVector p2 = proj.get(currIdx + 1);
              vertex(p1.x, p1.y, p1.z); vertex(p2.x, p2.y, p2.z);
           }
           // Long
           int nextURel = (((u + 1) % uSteps) * (vSteps+1)) + v;
           int nextUIdx = ringOffset + nextURel;
           PVector p3 = proj.get(nextUIdx);
           vertex(p1.x, p1.y, p1.z); vertex(p3.x, p3.y, p3.z);
           
           // Path (check wrapping)
           int actualRingIndex = (start + k) % tSteps;
           if (actualRingIndex != tSteps - 1) {
              int nextTIdx = currIdx + vertsPerRing;
              if (nextTIdx < proj.size()) {
                PVector p4 = proj.get(nextTIdx);
                vertex(p1.x, p1.y, p1.z); vertex(p4.x, p4.y, p4.z);
              }
           }
        }
      }
    }
    endShape();
  }
}