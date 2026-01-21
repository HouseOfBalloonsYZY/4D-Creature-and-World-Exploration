// "True 3D" Soft Cell Nautilus
// Combines:
// 1. Soft Cell Septa (Midpoint Bulge + Sheared Suture)
// 2. 4D-style Parametric Rotation (Expansion + XY Rot + Z Rot)

float rotX = 0, rotY = 0;

// --- Parameters ---
int tSteps = 80;            // More steps for smoother 3D curves
int vSteps = 40;            // Resolution of the ring
int radialSteps = 12;       // Resolution of the septum mesh

// Shell parameters
float globalScale = 120.0;
float spiralGrowth = 0.12;  // Expansion rate (B)
float tubeRatio = 0.5;      // Thickness of the shell

// Rotation Factors (The "True 3D" Logic)
// Adjust these to change how the shell twists in 3D space
float w1 = 1.0;  // Primary winding (Theta)
float w2 = 0.4;  // Secondary tumbling (Phi) - Makes it "True 3D"

// Data Structures
ArrayList<PVector[][]> septumList = new ArrayList<PVector[][]>();
PVector[][] shellPoints = new PVector[tSteps][vSteps];
PVector[] spinePoints = new PVector[tSteps];
PVector[] spineTangents = new PVector[tSteps]; // Needed for 3D ring orientation

// Cutoff to create the "Hook" aesthetic
int shellDrawLimit;

void setup() {
  size(1000, 800, P3D);
  smooth(8);
  shellDrawLimit = tSteps - 6; // Leave the end open
  generateNautilus();
}

void generateNautilus() {
  // --- 1. Generate the True 3D Spine & Orientation Frames ---
  for (int i = 0; i < tSteps; i++) {
    float t = map(i, 0, tSteps-1, -6.0 * PI, 1.0 * PI);
    
    // Calculate Position using 3D Parametric Math
    spinePoints[i] = calculateSpine(t);
    
    // Calculate Tangent (Forward Vector) for 3D Orientation
    // We look slightly ahead to determine which way is "Forward"
    float t_next = t + 0.01; 
    PVector p_next = calculateSpine(t_next);
    PVector tangent = PVector.sub(p_next, spinePoints[i]).normalize();
    spineTangents[i] = tangent;
    
    // --- Generate Shell Ring (Oriented in 3D) ---
    // We need an arbitrary "Up" vector to build a coordinate system on the curve
    PVector upRef = new PVector(0, 1, 0);
    PVector right = spineTangents[i].cross(upRef).normalize();
    PVector up = right.cross(spineTangents[i]).normalize();
    
    // Calculate Radius at this t
    float R = getRadius(t); 
    float rTube = R * tubeRatio;

    for (int j = 0; j < vSteps; j++) {
      float v = map(j, 0, vSteps, 0, TWO_PI);
      
      // Circle coordinates in local frame
      float cx = rTube * cos(v);
      float cy = rTube * sin(v);
      
      // Transform to World Space: pos + (right * cx) + (up * cy)
      PVector pt = spinePoints[i].copy();
      pt.add(PVector.mult(right, cx));
      pt.add(PVector.mult(up, cy));
      
      shellPoints[i][j] = pt;
    }
  }

  // --- 2. Generate Soft Cell Septa (Every 2 steps) ---
  for (int i = 2; i < shellDrawLimit - 2; i += 2) {
    PVector[][] currentSeptum = new PVector[radialSteps][vSteps];
    
    float t_base = map(i, 0, tSteps-1, -6.0 * PI, 1.0 * PI);
    float t_next_step = map(i+1, 0, tSteps-1, -6.0 * PI, 1.0 * PI);
    float t_step_size = t_next_step - t_base;
    
    PVector currentSpine = spinePoints[i];
    PVector prevSpine = spinePoints[i-1];
    
    // Bulge Apex: Midpoint
    PVector mountainTop = PVector.lerp(currentSpine, prevSpine, 0.5);
    PVector bulgeVector = PVector.sub(mountainTop, currentSpine);
    
    for (int k = 0; k < radialSteps; k++) {
      float rFrac = map(k, 0, radialSteps-1, 0, 1.0);
      float softProfile = 0.5 * (1.0 + cos(PI * rFrac)); // Cosine blend
      
      for (int j = 0; j < vSteps; j++) {
        float v = map(j, 0, vSteps, 0, TWO_PI);
        
        // --- Shear Logic (t+2) ---
        float shearFactor = 0.5 * (1.0 + cos(v)); 
        float t_rim = t_base + (shearFactor * 2.0 * t_step_size); 
        
        // Dynamic Rim Calculation on the 3D Spine
        // 1. Get Spine Pos at t_rim
        PVector spineAtRim = calculateSpine(t_rim);
        
        // 2. Get Orientation at t_rim
        float t_rim_next = t_rim + 0.01;
        PVector p_rim_next = calculateSpine(t_rim_next);
        PVector tanRim = PVector.sub(p_rim_next, spineAtRim).normalize();
        PVector upRef = new PVector(0, 1, 0);
        PVector rightRim = tanRim.cross(upRef).normalize();
        PVector upRim = rightRim.cross(tanRim).normalize();
        
        // 3. Get Radius & Irregularity
        float R_rim = getRadius(t_rim);
        float rTube_rim = R_rim * tubeRatio;
        float irregularity = 1.0 + 0.05 * sin(3 * v); 
        float r_final = rTube_rim * irregularity;
        
        // 4. Construct Rim Point
        float cx = r_final * cos(v);
        float cy = r_final * sin(v);
        PVector rimPoint = spineAtRim.copy();
        rimPoint.add(PVector.mult(rightRim, cx));
        rimPoint.add(PVector.mult(upRim, cy));
        
        // Interpolate & Bulge
        PVector basePos = PVector.lerp(currentSpine, rimPoint, rFrac);
        
        float bx = bulgeVector.x * softProfile;
        float by = bulgeVector.y * softProfile;
        float bz = bulgeVector.z * softProfile;
        
        currentSeptum[k][j] = new PVector(basePos.x + bx, basePos.y + by, basePos.z + bz);
      }
    }
    septumList.add(currentSeptum);
  }
}

// --- The True 3D Math Function ---
PVector calculateSpine(float t) {
  // Parametric rotation angles derived from 4D logic
  float theta = w1 * t;  // Fast winding
  float phi = w2 * t;    // Slow tumble (Z-rotation factor)
  
  // Logarithmic Expansion
  float r = getRadius(t);
  
  // Spherical Projection (3D Slice of 4D Hypersphere)
  // x = r * cos(theta)
  // y = r * sin(theta) * cos(phi)
  // z = r * sin(theta) * sin(phi)
  
  float x = r * cos(theta);
  float y = r * sin(theta) * cos(phi);
  float z = r * sin(theta) * sin(phi);
  
  return new PVector(x, y, z);
}

float getRadius(float t) {
  // r = A * e^(B*t)
  return globalScale * exp(spiralGrowth * t);
}

void draw() {
  background(10);
  translate(width/2, height/2);
  rotateX(rotX);
  rotateY(rotY);

  // 1. Draw Outer Shell (Wireframe Hook)
  strokeWeight(1);
  stroke(255, 255, 255, 30); 
  for (int i = 0; i < shellDrawLimit - 1; i++) {
    for (int j = 0; j < vSteps; j++) {
      int nextJ = (j + 1) % vSteps;
      PVector p1 = shellPoints[i][j];
      PVector p2 = shellPoints[i+1][j];
      PVector p3 = shellPoints[i][nextJ];
      line(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z); 
      line(p1.x, p1.y, p1.z, p3.x, p3.y, p3.z); 
    }
  }

  // 2. Draw Soft Septa
  strokeWeight(1.5);
  for (PVector[][] septum : septumList) {
    for (int k = 0; k < radialSteps - 1; k++) {
      // Fade alpha from center to edge
      float alpha = map(k, 0, radialSteps, 200, 30); 
      stroke(0, 190, 255, alpha); 
      
      for (int j = 0; j < vSteps; j++) {
        int nextJ = (j + 1) % vSteps;
        PVector p1 = septum[k][j];
        PVector p2 = septum[k+1][j];
        PVector p3 = septum[k][nextJ];
        
        line(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z); 
        line(p1.x, p1.y, p1.z, p3.x, p3.y, p3.z); 
      }
    }
  }

  // 3. Draw Siphuncle (Spine)
  stroke(255, 60, 60);
  strokeWeight(3);
  noFill();
  beginShape();
  for (int i = 0; i < shellDrawLimit; i++) {
    vertex(spinePoints[i].x, spinePoints[i].y, spinePoints[i].z);
  }
  endShape();
}

void mouseDragged() {
  rotY += (mouseX - pmouseX) * 0.01;
  rotX -= (mouseY - pmouseY) * 0.01;
}