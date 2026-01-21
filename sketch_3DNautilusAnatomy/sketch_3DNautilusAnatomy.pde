float rotX = 0, rotY = 0;

// Data structures
int tSteps = 60;           
int vSteps = 40;           
int radialSteps = 10;       

// Arrays
PVector[][] shellPoints = new PVector[tSteps][vSteps];
// We store septa in a list since the count is dynamic (step 2)
ArrayList<PVector[][]> septumList = new ArrayList<PVector[][]>();
PVector[] spinePoints = new PVector[tSteps];

// Cutoff parameter
int shellDrawLimit; 

void setup() {
  size(1000, 800, P3D);
  smooth(8);
  
  shellDrawLimit = tSteps - 2; 
  generateNautilus();
}

void generateNautilus() {
  float spiralGrowth = 0.12; 
  float tubeRatio = 0.55;     
  float globalScale = 150.0;   

  // --- 1. Generate Base Spine and Shell ---
  for (int i = 0; i < tSteps; i++) {
    float t = map(i, 0, tSteps-1, -6.0 * PI, 0.5 * PI);
    float R = exp(spiralGrowth * t) * globalScale;
    float rTube = R * tubeRatio;
    
    spinePoints[i] = new PVector(R * cos(t), 0, R * sin(t));
    
    for (int j = 0; j < vSteps; j++) {
      float v = map(j, 0, vSteps, 0, TWO_PI);
      float dx = rTube * cos(v) * cos(t);
      float dz = rTube * cos(v) * sin(t);
      float dy = rTube * sin(v);
      
      shellPoints[i][j] = new PVector(spinePoints[i].x + dx, dy, spinePoints[i].z + dz);
    }
  }

  // --- 2. Generate Septa every 2 Steps ---
  // Start at 2, stop before the end, increment by 2
  for (int i = 2; i < shellDrawLimit - 2; i += 2) {
    
    // Create new array for this chamber
    PVector[][] currentSeptum = new PVector[radialSteps][vSteps];
    
    float t_base = map(i, 0, tSteps-1, -6.0 * PI, 0.5 * PI);
    float t_next_step = map(i+1, 0, tSteps-1, -6.0 * PI, 0.5 * PI);
    float t_step_size = t_next_step - t_base;
    
    float R_base = exp(spiralGrowth * t_base) * globalScale;
    PVector currentSpine = new PVector(R_base * cos(t_base), 0, R_base * sin(t_base));
    PVector prevSpine = spinePoints[i-1];
    
    // --- Bulge Logic (Midpoint) ---
    // Keep the "Mountain Top" at the midpoint to control protuberance
    PVector mountainTop = PVector.lerp(currentSpine, prevSpine, 0.5);
    PVector bulgeVector = PVector.sub(mountainTop, currentSpine);

    for (int k = 0; k < radialSteps; k++) {
      float rFrac = map(k, 0, radialSteps-1, 0, 1.0);
      float softProfile = 0.5 * (1.0 + cos(PI * rFrac)); 
      
      for (int j = 0; j < vSteps; j++) {
        float v = map(j, 0, vSteps, 0, TWO_PI);
        
        // --- Restored Shear (t+2) ---
        // At v=0 (outer), factor is 1.0 -> 2.0 * t_step_size (2 steps forward)
        // At v=PI (inner), factor is 0.0 -> 0 steps forward
        float shearFactor = 0.5 * (1.0 + cos(v)); 
        float t_rim = t_base + (shearFactor * 2.0 * t_step_size); 
        
        // Calculate dynamic rim point
        float R_rim = exp(spiralGrowth * t_rim) * globalScale;
        float rTube_rim = R_rim * tubeRatio;
        
        float irregularity = 1.0 + 0.05 * sin(3 * v); 
        float r_final = rTube_rim * irregularity;
        
        float rimX = (R_rim * cos(t_rim)) + (r_final * cos(v) * cos(t_rim));
        float rimZ = (R_rim * sin(t_rim)) + (r_final * cos(v) * sin(t_rim));
        float rimY = r_final * sin(v);
        PVector rimPoint = new PVector(rimX, rimY, rimZ);
        
        PVector basePos = PVector.lerp(currentSpine, rimPoint, rFrac);
        
        float bx = bulgeVector.x * softProfile;
        float bz = bulgeVector.z * softProfile;
        
        currentSeptum[k][j] = new PVector(basePos.x + bx, basePos.y, basePos.z + bz);
      }
    }
    septumList.add(currentSeptum);
  }
}

void draw() {
  background(10);
  translate(width/2, height/2);
  rotateX(rotX);
  rotateY(rotY);

  // 1. Draw Outer Shell Mesh
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

  // 2. Draw Septa from List
  strokeWeight(1.5);
  for (PVector[][] septum : septumList) {
    for (int k = 0; k < radialSteps - 1; k++) {
      float alpha = map(k, 0, radialSteps, 180, 20); 
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

  // 3. Draw Siphuncle
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