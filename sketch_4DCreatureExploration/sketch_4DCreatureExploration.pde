/**
 * FourDimensionalCreatureExploration
 * Main Sketch for exploring 4D Geometries.
 */

Shape4D object4D;       
LocalCoordinateSystem coordSys; 
Slider[] sliders = new Slider[6];
VerticalSlider zoomSlider;
RangeSlider rangeSlider; 
Dropdown objectMenu;    

Button resetButton;
Button randomBtn;
Button autoBtn;
Button speedBtn; 
Button axesToggleBtn; 
Button selectiveBtn; 
Button logParamsBtn; 

// Multiplier Sliders
MultiplierSlider m1Slider, m2Slider, m3Slider; 
boolean showLogParams = false;

float[] prevAngles = new float[6]; 
String[] labels = {"XY Plane", "XZ Plane", "YZ Plane", "XW Plane", "YW Plane", "ZW Plane"}; 

boolean isAutoRotating = false;
float[] noiseOffsets = new float[6]; 
int speedMode = 0; 
float speedMultiplier = 1.0;
boolean showObjectAxes = true; 
boolean isSelectiveDisplay = true; 

float isoRotX = 0.9553166;      
float isoRotY = -QUARTER_PI;    
float isoRotZ = 0.4636476;      

Slider activeInputSlider = null;
RangeSlider activeRangeInput = null;
MultiplierSlider activeMultInput = null;

void setup() {
  size(1600, 1000, P3D); 
  smooth(8);
  
  object4D = new FourDShellChamber(); // Default to new chamber
  coordSys = new LocalCoordinateSystem(); 
  
  int startX = 30;
  int startY = 40;
  
  for (int i = 0; i < 6; i++) {
    sliders[i] = new Slider(startX, startY + i * 60, 400, 30, -TWO_PI, TWO_PI, labels[i]);
    noiseOffsets[i] = random(1000); 
  }
  
  m1Slider = new MultiplierSlider(startX + 500, startY, 200, 20, "m1 (GR)");
  m2Slider = new MultiplierSlider(startX + 500, startY + 60, 200, 20, "m2 (E)");
  m3Slider = new MultiplierSlider(startX + 500, startY + 120, 200, 20, "m3 (PI)");
  
  zoomSlider = new VerticalSlider(width - 80, height - 300, 30, 200, 5.0, 100.0, "Zoom");
  zoomSlider.val = 50.0; 
  
  resetButton   = new Button(startX, height - 80, 120, 40, "RESET VIEW");
  randomBtn     = new Button(startX + 140, height - 80, 140, 40, "Random Rotation");
  autoBtn       = new Button(startX + 300, height - 80, 160, 40, "Auto Rotation: Off");
  speedBtn      = new Button(startX + 480, height - 80, 120, 40, "Speed: Slow"); 
  axesToggleBtn = new Button(startX + 620, height - 80, 140, 40, "Show Axes: ON");
  
  selectiveBtn  = new Button(startX + 780, height - 80, 160, 40, "Selective: OFF");
  logParamsBtn  = new Button(startX + 950, height - 80, 160, 40, "Params: OFF");
  
  rangeSlider   = new RangeSlider(startX + 780, height - 140, 300, 30, 2000);
  
  String[] menuOptions = {
    "-- Regular Polytopes --",
    "5-Cell (Pentachoron)", 
    "8-Cell (Tesseract)",
    "16-Cell (Hexadecachoron)",
    "24-Cell (Icositetrachoron)",
    "120-Cell (Hecatonicosachoron)", 
    "600-Cell (Hexacosichoron)",
    "-- Manifolds --",
    "Klein Bottle", 
    "Clifford Torus",
    "Real Projective Plane",
    "Hypersphere Grid",
    "Spherinder",
    "-- Logarithmic --",
    "4D Logarithmic Spiral",
    "4D Spiral Shell", 
    "-- Creatures --",
    "4D Shell Chamber", // <--- NEW
    "True 4D Creature",
    "Creature Test 2 (Composite)" 
  };
  objectMenu = new Dropdown(startX, 420, 200, 25, "Select Object", menuOptions);
  
  resetSimulation();
}

void resetSimulation() {
  isAutoRotating = false;
  autoBtn.label = "Auto Rotation: Off";
  speedMode = 0;
  speedMultiplier = 1.0;
  speedBtn.label = "Speed: Slow";
  showObjectAxes = true;
  axesToggleBtn.label = "Show Axes: ON";
  
  isSelectiveDisplay = true;
  selectiveBtn.label = "Selective: ON";
  
  m1Slider.val = 1.0; m2Slider.val = 1.0; m3Slider.val = 1.0;
  showLogParams = false;
  logParamsBtn.label = "Params: OFF";

  for (int i = 0; i < 6; i++) {
    sliders[i].val = 0;
    prevAngles[i] = 0;
  }
  
  zoomSlider.val = 50.0;
  CAMERA_4D_DISTANCE = 50.0;
  
  object4D.orientation.identity();
  coordSys.orientation.identity();
  
  applyGlobalDeltaRotation(0, isoRotZ);
  applyGlobalDeltaRotation(1, -isoRotY);
  applyGlobalDeltaRotation(2, isoRotX);
  
  // Sync multipliers if applicable
  if (object4D instanceof FourDSpiral) ((FourDSpiral)object4D).updateMultipliers(1.0, 1.0, 1.0);
  if (object4D instanceof FourDSpiralShell) ((FourDSpiralShell)object4D).updateMultipliers(1.0, 1.0, 1.0);
  if (object4D instanceof FourDShellChamber) ((FourDShellChamber)object4D).updateMultipliers(1.0, 1.0, 1.0);
}

void switchObject(String name) {
  if (name.startsWith("--") || name.startsWith("(")) return; 
  
  if (name.equals("8-Cell (Tesseract)")) object4D = new Tesseract();
  else if (name.equals("5-Cell (Pentachoron)")) object4D = new Pentachoron();
  else if (name.equals("16-Cell (Hexadecachoron)")) object4D = new Hexadecachoron(); 
  else if (name.equals("24-Cell (Icositetrachoron)")) object4D = new Icositetrachoron();
  else if (name.equals("120-Cell (Hecatonicosachoron)")) object4D = new Hecatonicosachoron(); 
  else if (name.equals("600-Cell (Hexacosichoron)")) object4D = new Hexacosichoron();
  else if (name.equals("Klein Bottle")) object4D = new KleinBottle();
  else if (name.equals("Clifford Torus")) object4D = new CliffordTorus();
  else if (name.equals("Real Projective Plane")) object4D = new RealProjectivePlane();
  else if (name.equals("Hypersphere Grid")) object4D = new HypersphereGrid();
  else if (name.equals("Spherinder")) object4D = new Spherinder();
  else if (name.equals("4D Logarithmic Spiral")) object4D = new FourDSpiral();
  else if (name.equals("4D Spiral Shell")) object4D = new FourDSpiralShell(); 
  else if (name.equals("4D Shell Chamber")) object4D = new FourDShellChamber();
  else if (name.equals("True 4D Creature")) object4D = new TrueFourDCreature();
  else if (name.equals("Creature Test 2 (Composite)")) object4D = new CreatureComposite(); 
  
  object4D.orientation = coordSys.orientation;
  
  isSelectiveDisplay = true;
  selectiveBtn.label = "Selective: ON";
  showLogParams = false;
  logParamsBtn.label = "Params: OFF";
}

void applyGlobalDeltaRotation(int planeIdx, float angle) {
  object4D.rotateByDelta(planeIdx, angle);
  coordSys.rotateByDelta(planeIdx, angle);
}

void draw() {
  background(20);
  
  zoomSlider.update();
  zoomSlider.display();
  CAMERA_4D_DISTANCE = zoomSlider.val; 
  
  if (isAutoRotating) {
    for(int i=0; i<6; i++) {
      float baseSpeed = map(noise(noiseOffsets[i]), 0, 1, -0.05, 0.05);
      noiseOffsets[i] += 0.02; 
      sliders[i].val += baseSpeed * speedMultiplier;
      if (sliders[i].val > TWO_PI) sliders[i].val -= TWO_PI * 2;
      if (sliders[i].val < -TWO_PI) sliders[i].val += TWO_PI * 2;
    }
  }
  
  for(int i=0; i<6; i++) {
    float currentVal = sliders[i].val;
    float delta = currentVal - prevAngles[i];
    if (abs(delta) > PI) {
       prevAngles[i] = currentVal; 
       continue;
    }
    if (delta != 0) {
      applyGlobalDeltaRotation(i, delta);
      prevAngles[i] = currentVal; 
    }
  }
  
  // Logic for Logarithmic Parameters
  boolean isLog = (object4D instanceof FourDSpiral || object4D instanceof FourDSpiralShell || object4D instanceof FourDShellChamber);
  if (isLog && showLogParams) {
    m1Slider.update(); m1Slider.display();
    m2Slider.update(); m2Slider.display();
    m3Slider.update(); m3Slider.display();
    
    if (object4D instanceof FourDSpiral) ((FourDSpiral)object4D).updateMultipliers(m1Slider.val, m2Slider.val, m3Slider.val);
    else if (object4D instanceof FourDSpiralShell) ((FourDSpiralShell)object4D).updateMultipliers(m1Slider.val, m2Slider.val, m3Slider.val);
    else if (object4D instanceof FourDShellChamber) ((FourDShellChamber)object4D).updateMultipliers(m1Slider.val, m2Slider.val, m3Slider.val);
  }
  
  pushMatrix(); 
  translate(width/2, height/2);
  
  if (showObjectAxes) {
    coordSys.render3DAxes();
  }
  
  boolean canSelect = isLog;
  
  if (canSelect && isSelectiveDisplay) {
    if (object4D instanceof FourDSpiral) {
      rangeSlider.totalSteps = ((FourDSpiral)object4D).steps;
      rangeSlider.update();
      rangeSlider.display();
      ((FourDSpiral)object4D).renderWindow(rangeSlider.startStep, rangeSlider.visibleSteps);
    } else if (object4D instanceof FourDSpiralShell) {
      rangeSlider.totalSteps = ((FourDSpiralShell)object4D).tSteps;
      rangeSlider.update();
      rangeSlider.display();
      ((FourDSpiralShell)object4D).renderWindow(rangeSlider.startStep, rangeSlider.visibleSteps);
    } else if (object4D instanceof FourDShellChamber) {
      rangeSlider.totalSteps = ((FourDShellChamber)object4D).tSteps;
      rangeSlider.update();
      rangeSlider.display();
      ((FourDShellChamber)object4D).renderWindow(rangeSlider.startStep, rangeSlider.visibleSteps);
    }
  } else {
    object4D.render();
  }
  
  popMatrix(); 
  
  camera(); 
  hint(DISABLE_DEPTH_TEST); 
  noLights(); 
  
  coordSys.renderAllSystems(width, height); 
  
  for (Slider s : sliders) {
    s.update();
    s.display();
  }
  
  zoomSlider.display();
  resetButton.update();
  resetButton.display();
  randomBtn.update();
  randomBtn.display();
  autoBtn.update();
  autoBtn.display();
  speedBtn.update();
  speedBtn.display();
  axesToggleBtn.update();
  axesToggleBtn.display();
  
  if (canSelect) {
    selectiveBtn.update();
    selectiveBtn.display();
    
    if (isSelectiveDisplay) {
      rangeSlider.update();
      rangeSlider.display();
    }
    
    logParamsBtn.update();
    logParamsBtn.display();
  }
  
  objectMenu.display();
  
  hint(ENABLE_DEPTH_TEST); 
}

void mousePressed() {
  boolean overMenuHeader = (mouseX >= objectMenu.x && mouseX <= objectMenu.x + objectMenu.w && 
                            mouseY >= objectMenu.y && mouseY <= objectMenu.y + objectMenu.h);

  int selected = objectMenu.handleClick();
  if (selected != -1) {
    String option = objectMenu.options[selected];
    switchObject(option);
    objectMenu.label = option; 
    objectMenu.isOpen = false; 
    return; 
  }
  
  if (overMenuHeader) return;
  
  if (objectMenu.isOpen) {
    objectMenu.isOpen = false;
    return;
  }

  if (resetButton.isClicked()) {
    resetSimulation();
    return;
  }
  
  if (randomBtn.isClicked()) {
    for(int i=0; i<6; i++) sliders[i].val = random(-TWO_PI, TWO_PI);
    return;
  }
  
  if (autoBtn.isClicked()) {
    isAutoRotating = !isAutoRotating;
    autoBtn.label = isAutoRotating ? "Auto Rotation: On" : "Auto Rotation: Off";
    return;
  }
  
  if (speedBtn.isClicked()) {
    speedMode = (speedMode + 1) % 3; 
    if (speedMode == 0) { speedMultiplier = 1.0; speedBtn.label = "Speed: Slow"; } 
    else if (speedMode == 1) { speedMultiplier = 6.0; speedBtn.label = "Speed: Mod"; } 
    else { speedMultiplier = 12.0; speedBtn.label = "Speed: Fast"; }
    return;
  }
  
  if (axesToggleBtn.isClicked()) {
    showObjectAxes = !showObjectAxes;
    axesToggleBtn.label = showObjectAxes ? "Show Axes: ON" : "Show Axes: OFF";
    return;
  }
  
  boolean canSelect = (object4D instanceof FourDSpiral || object4D instanceof FourDSpiralShell || object4D instanceof FourDShellChamber);
  
  if (canSelect && selectiveBtn.isClicked()) {
    isSelectiveDisplay = !isSelectiveDisplay;
    selectiveBtn.label = isSelectiveDisplay ? "Selective: ON" : "Selective: OFF";
    return;
  }
  
  if (canSelect && logParamsBtn.isClicked()) {
    showLogParams = !showLogParams;
    logParamsBtn.label = showLogParams ? "Params: ON" : "Params: OFF";
    return;
  }
  
  activeInputSlider = null;
  activeRangeInput = null;
  activeMultInput = null;
  
  for (Slider s : sliders) {
    if (s.checkFocus()) { activeInputSlider = s; break; }
  }
  
  if (canSelect && showLogParams) {
     if (m1Slider.checkFocus()) activeMultInput = m1Slider;
     else if (m2Slider.checkFocus()) activeMultInput = m2Slider;
     else if (m3Slider.checkFocus()) activeMultInput = m3Slider;
  }
  
  if (canSelect && isSelectiveDisplay && rangeSlider.checkFocus()) {
    activeRangeInput = rangeSlider;
  }
}

void keyPressed() {
  if (activeInputSlider != null) {
    activeInputSlider.handleKey(key, keyCode);
  }
  if (activeRangeInput != null) {
    activeRangeInput.handleKey(key, keyCode);
  }
  if (activeMultInput != null) {
    activeMultInput.handleKey(key, keyCode);
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  float delta = e * 0.2; 
  zoomSlider.val += delta;
  zoomSlider.val = constrain(zoomSlider.val, zoomSlider.min, zoomSlider.max);
}