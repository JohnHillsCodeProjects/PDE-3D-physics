/*///////////////////////////////////////////////////////////////////
Graphics For Games coursework made by John Hills (N0923065)

The controls are as follows:
SPACE to play and pause the simulation
RIGHT MOUSE to move the camera (camera position equats to where the mouse is on the screen)
Use the UI to edit the simulation 
*/

ArrayList<SimSphere> rocks = new ArrayList<SimSphere>();
ArrayList<PVector> velocity = new ArrayList<PVector>();
ArrayList<Float> sizes = new ArrayList<Float>();
ArrayList<Float> elasticity = new ArrayList<Float>();
SimCamera theCamera;
SimpleUI theUI;

void setup() {
  size(1000,500,P3D);
  setZoomLevels();
  rock_init();
  float r = area_size*sqrt(3);
  float center = area_size/2;
  float x = center;
  float y = center;
  float z = r-center;
  theCamera = new SimCamera();
  theCamera.setPositionAndLookat(vec(x,y,z), vec(center,center,-center));
  theCamera.setHUDArea(0,area_size,0,area_size);
  setUI();
}

void testingArrayList() { //Scrap code not used in the main program. Is kept as a reference for how ArrayList works
  int x = 3;
  Integer y = 4;
  println(x);
  println(y);
  ArrayList<Integer> nums = new ArrayList<Integer>();
  nums.add(5); nums.add(2); nums.add(7); nums.add(8); println(nums);
  nums.remove(2); println(nums); //Removes based on index
  nums.add(9);    println(nums);
  nums.remove(1); println(nums);
}

boolean simulate = false;

void keyPressed() {
  if (key == ' ') simulate = !simulate; //Use space bar to start and stop the silmulation
}

void draw() {
  background(128);
  noFill();
  drawBorderLines();
  display_asteroids();
  display_blackHoles();
  mouseCamera();
  if (simulate) {
    simulate_blackHoles();
    move_asteroids();
    detect_collisions();
  } else {
    delete_asteroid();
    display_possible_blackHole();
    theCamera.startDrawHUD(); theUI.update(); UItext(); theCamera.endDrawHUD();
  }
} //Enforce a limit of 100 rocks total for the sake of processing speed and to ensure that there will be space for rocks to be added

///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////
//                                      UI code
///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////

void setUI() {
  theUI = new SimpleUI();
  theUI.addSimpleButton("add new",800,30);
  theUI.addSimpleButton("clear all",800,60);
  theUI.addSimpleButton("velocity",800,90);
  theUI.addSimpleButton("elastic",800,120);
  theUI.addSimpleButton("position",800,150);
  theUI.addSimpleButton("spawn",800,240);
  Slider X_s = theUI.addSlider("x",800,270);
  X_s.setSliderValue(0.5);
  Slider Y_s = theUI.addSlider("y",800,300);
  Y_s.setSliderValue(0.5);
  Slider Z_s = theUI.addSlider("z",800,330);
  Z_s.setSliderValue(0.5);
  Slider G_s = theUI.addSlider("gravity",800,360);
  G_s.setSliderValue(0.5);
  theUI.addSimpleButton("clear",800,400);
}

void UItext() {
  text("Randomise velocities", 865,92,200,200);
  text("Randomise elasticity", 865,122,200,200);
  text("Randomise positons", 865,152,200,200);
  text("Black hole controls", 800,220,200,200);
}

float bhv[] = {0.5,0.5,0.5,0.5}; //Stands for black hole values
void handleUIEvent(UIEventData uied) {
  uied.print(0);
  
  if (uied.eventIsFromWidget("add new"))   if (rocks.size() < 100) new_asteroid(0);
  if (uied.eventIsFromWidget("clear all")) clear_asteroids();
  if (uied.eventIsFromWidget("velocity"))  new_vels();
  if (uied.eventIsFromWidget("elastic"))   new_e();
  if (uied.eventIsFromWidget("position"))  new_pos();
  
  if (uied.eventIsFromWidget("spawn")) create_blackHole(bhv[0],bhv[1],bhv[2],bhv[3]);
  if (uied.eventIsFromWidget("x")) bhv[0] = uied.sliderValue;
  if (uied.eventIsFromWidget("y")) bhv[1] = uied.sliderValue;
  if (uied.eventIsFromWidget("z")) bhv[2] = uied.sliderValue;
  if (uied.eventIsFromWidget("gravity")) bhv[3] = uied.sliderValue; 
  if (uied.eventIsFromWidget("clear")) blackHoles.clear();
}

///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////
//                                    Border code
///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////

//Used in construction of the lines of the the simulation area
int area_size = 1000;
float border_points[][] = { {0,0,0},{1,0,0},{0,1,0},{1,1,0},{0,0,1},{1,0,1},{0,1,1},{1,1,1} }; 
int border_lines[][] = { {0,1},{0,2},{3,1},{3,2},{0,4},{1,5},{2,6},{3,7},{4,5},{4,6},{7,5},{7,6} };

void drawBorderLines() {
  float x0,y0,z0,x1,y1,z1;
  int i; for (i=0;i<12;i++) {
    stroke(128,0,0);
    x0 =  area_size * border_points[ border_lines[i][0] ][0];
    y0 =  area_size * border_points[ border_lines[i][0] ][1];
    z0 = -area_size * border_points[ border_lines[i][0] ][2];
    x1 =  area_size * border_points[ border_lines[i][1] ][0];
    y1 =  area_size * border_points[ border_lines[i][1] ][1];
    z1 = -area_size * border_points[ border_lines[i][1] ][2];
    line(x0,y0,z0,x1,y1,z1);
  }
}

///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////
//                                    Asteroid code
///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////

void rock_init() {
  int i; for (i=0;i<20;i++) new_asteroid(0);
}

void move_asteroids() {
  int i; for (i=0;i<rocks.size();i++) {
    rocks.get(i).setTransformRel(1,0,0,0,velocity.get(i)); 
  }
}

void clear_asteroids() { rocks.clear(); velocity.clear(); sizes.clear(); elasticity.clear(); }

void delete_asteroid() {
  if(mouseButton != LEFT) return; //Only delete rocks that are where the mouse is clicking
  SimRay ray = theCamera.getMouseRay();
  int i; for (i=0;i<rocks.size();i++) { 
    if (ray.calcIntersection(rocks.get(i))) {
      rocks.remove(i);
      velocity.remove(i);
      sizes.remove(i);
      elasticity.remove(i); 
      return; //Only delete one per frame
    }
  }
}

void new_asteroid(float in_size) {  
  //The variables other than position are very simple
  float limit = (new Double(25/Math.sqrt(3)).floatValue()); //Velocity limit since if a rock's velocity magnitude is larger than 25, it could miss a rock.
  float v[] = {0,0,0,0,0}; //V stands for variables
  int i; for (i=0;i<5;i++) v[i] = (new Double(Math.random())).floatValue();
  v[0] = v[0] * limit * 2 - limit; //Velocity should be between -limit and limit
  v[1] = v[1] * limit * 2 - limit;
  v[2] = v[2] * limit * 2 - limit;
  PVector vel = vec(v[0],v[1],v[2]);
  float size;
  if (in_size != 0) size = in_size; //If size shouldn't be randomised
  else size = 50 * v[3] + 25; //Size should be between 25 and 75
  float e = 0.2 * v[4] + 0.8; //Elasticity should be between 0.5 and 1
  
  //For the position, the program loops until it has found a new random position for the rock
  PVector pos = vec(0,0,0); boolean found = false; float x,y,z;
  SimSphere new_rock = new SimSphere(pos,size);
  while (!found) {
    x = (new Double((area_size - 75) * Math.random() + 75)).floatValue();
    y = (new Double((area_size - 75) * Math.random() + 75)).floatValue();
    z = (new Double((area_size - 75) * Math.random() + 75)).floatValue();
    pos = vec(x,y,-z);
    new_rock.setTransformAbs(1,0,0,0,pos);
    found = true; //The loop will look to see if this is untrue
    for (i=0;i<rocks.size();i++) if (new_rock.collidesWith(rocks.get(i))) { found = false; break; }
  }
  
  rocks.add(new_rock);
  sizes.add(size);
  velocity.add(vel);
  elasticity.add(e);
}

void new_vels() {
  float limit = (new Double(25/Math.sqrt(3)).floatValue());
  ArrayList<PVector> newlist = new ArrayList<PVector>();
  int i; for (i=0;i<rocks.size();i++) {
    float x = (new Double(Math.random()* limit * 2 - limit)).floatValue();
    float y = (new Double(Math.random()* limit * 2 - limit)).floatValue();
    float z = (new Double(Math.random()* limit * 2 - limit)).floatValue();
    newlist.add(vec(x,y,z));
  }
  velocity.clear(); velocity.addAll(newlist);
}

void new_e() {
  ArrayList<Float> newlist = new ArrayList<Float>();
  int i; for(i=0;i<rocks.size();i++) newlist.add((new Double(0.5d * Math.random() + 0.5)).floatValue());
  elasticity.clear(); elasticity.addAll(newlist);
}

void new_pos() {
  ArrayList<SimSphere> newlist = new ArrayList<SimSphere>(); 
  float x,y,z; SimSphere newSphere = new SimSphere(); PVector pos; boolean found;
  int i; int j; for (i=0;i<rocks.size();i++) {
    found = false;
    while (!found) {
      x = (new Double((area_size - 75) * Math.random() + 75)).floatValue();
      y = (new Double((area_size - 75) * Math.random() + 75)).floatValue();
      z = (new Double((area_size - 75) * Math.random() + 75)).floatValue();
      pos = vec(x,y,-z);
      newSphere = new SimSphere(pos,sizes.get(i));
      found = true; //The loop will look to see if this is untrue
      for (j=0;j<newlist.size();j++) if (newSphere.collidesWith(newlist.get(j))) { found = false; break; } else {}
    }
    newlist.add(newSphere);
  }
  rocks.clear(); rocks.addAll(newlist);
}

void display_asteroids() { int i; for (i=0;i<rocks.size();i++) rocks.get(i).drawMe(); }

///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////
//                                    Black hole code
///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////

ArrayList <blackHole> blackHoles = new ArrayList<blackHole>();
SimSphere possible_blackHole;

class blackHole {
  public PVector pos;
  public float gravity;
  public SimSphere sphere;
  
  public blackHole(PVector p, float g) {
    this.pos = p;
    this.gravity = g;
    sphere = new SimSphere(p,g);
  }
}

void create_blackHole(float x_in, float y_in, float z_in, float g_in) {
  float x = x_in * area_size;
  float y = y_in * area_size;
  float z = z_in * area_size;
  float g = (100-1) * g_in + 1;
  blackHoles.add(new blackHole(vec(x,y,-z),g));
}

void display_possible_blackHole() {
  float x = bhv[0] * area_size;
  float y = bhv[1] * area_size;
  float z = bhv[2] * area_size;
  float g = (100-1) * bhv[3] + 1;
  stroke(100);
  fill(100);
  possible_blackHole = new SimSphere(vec(x,y,-z),g);
  possible_blackHole.drawMe();
  noFill();
  stroke(128,0,0);
}

void display_blackHoles() {
  stroke(0);
  fill(0);
  int i; for (i=0;i<blackHoles.size();i++) {
    blackHoles.get(i).sphere.drawMe();
  }
  noFill();
  stroke(128,0,0);
}

void simulate_blackHoles() {
  ArrayList<Integer> marked4removal = new ArrayList<Integer>();
  PVector gDir, gForce, a; float s, gMag; //a means acceleration, s means distance
  int i; int j; for (i=0;i<rocks.size();i++) {
    for (j=0;j<blackHoles.size();j++) { //For all blackholes.
      //Delete any rocks that get fully caught in the black hole.
      if (blackHoles.get(j).sphere.collidesWith(rocks.get(i))) marked4removal.add(i);
      
      //Gravity is adapted from the code found in the lab 12 examples.
      //The difference is that here, grvaity is applied using the inverse square rule.
      gDir = PVector.sub(blackHoles.get(j).pos, rocks.get(i).getCentre()).normalize();
      s = blackHoles.get(j).pos.dist(rocks.get(i).getCentre());
      gMag = (1/(s*s)) * 10000 * blackHoles.get(j).gravity; //Inverse square rule
      gForce = PVector.mult(gDir,gMag);
      a = PVector.div(gForce, sizes.get(i));
      velocity.set(i, velocity.get(i).add(a));
    }
  }
  for (i=marked4removal.size()-1;i>=0;i--) rocks.remove(marked4removal.get(i));
}

///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////
//                                    Collision code
///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////

class impact { 
  public int index;
  public boolean isBorder;
  
  public impact(int thing, boolean type) { 
    this.index = thing;  
    this.isBorder = type; 
  }
}

void detect_collisions() { //Currently just for the borders
  ArrayList<impact> collisions = new ArrayList<impact>();
  PVector loc; float rad; //Short for location. Stores the location of the current 
  int i; int j; for(i=0;i<rocks.size();i++) {
    collisions.clear();
    loc = rocks.get(i).getCentre();
    rad = rocks.get(i).getRadius();
    
    if (rad > loc.y)           collisions.add(new impact(0,true)); //Top
    if (loc.y > area_size-rad) collisions.add(new impact(1,true)); //Bottom
    if (rad > loc.x)           collisions.add(new impact(2,true)); //Front
    if (loc.x > area_size-rad) collisions.add(new impact(3,true)); //Back
    if (loc.z < rad-area_size) collisions.add(new impact(4,true)); //Left
    if (-rad < loc.z)          collisions.add(new impact(5,true)); //Right
    
    for (j=i+1;j<rocks.size();j++) { //Start at i to avoid repeating collisions
      if (rocks.get(i).collidesWith(rocks.get(j))) collisions.add(new impact(j,false));
    }
    react_to_collisions(i,collisions);
  }
}

void react_to_collisions(int current, ArrayList<impact> collisions) {
  if (collisions.isEmpty()) return;
  int i; for (i=0;i<collisions.size();i++) {
    impact collide = collisions.get(i);
    if (collide.isBorder) { //For asteroid on borders
      //Set up this way in order to avoid any rocks that may go out of bounds and cannot get back in within one game loop
      //Here, the code won't toggle the velocity of the rock IF the rock is already travelling back to the area.
      if (collide.index == 0 && velocity.get(current).y < 0) velocity.get(current).y *= (-1 * elasticity.get(current)); //Top
      if (collide.index == 1 && velocity.get(current).y > 0) velocity.get(current).y *= (-1 * elasticity.get(current)); //Bottom
      if (collide.index == 2 && velocity.get(current).x < 0) velocity.get(current).x *= (-1 * elasticity.get(current)); //Front
      if (collide.index == 3 && velocity.get(current).x > 0) velocity.get(current).x *= (-1 * elasticity.get(current)); //Back
      if (collide.index == 4 && velocity.get(current).z < 0) velocity.get(current).z *= (-1 * elasticity.get(current)); //Left
      if (collide.index == 5 && velocity.get(current).z > 0) velocity.get(current).z *= (-1 * elasticity.get(current)); //Right
    } else {
      asteroid_collision(current,collide.index);
    }
  }
}

void asteroid_collision(int i, int j) {
      
  //The following code was originally found within the move.pde files used in many examples in this module
  //This code is used with the intention of programming elasticity to the reactions 
  
  PVector v1 = velocity.get(i);
  PVector v2 = velocity.get(j);
  
  float m1 = sizes.get(i);
  float m2 = sizes.get(j);
  
  float e1 = elasticity.get(i);
  float e2 = elasticity.get(j);
  
  PVector cen1 = rocks.get(i).getCentre();
  PVector cen2 = rocks.get(j).getCentre();
  
  //calculate v1New, the new velocity of this mover
  
  float massPart1 = 2*m2 / (m1 + m2);
  PVector v1subv2 = PVector.sub(v1,v2);
  PVector cen1subCen2 = PVector.sub(cen1,cen2);
  float topBit1 = v1subv2.dot(cen1subCen2);
  float bottomBit1 = cen1subCen2.mag()*cen1subCen2.mag();
  
  float multiplyer1 = massPart1 * (topBit1/bottomBit1);
  PVector changeV1 = PVector.mult(cen1subCen2, multiplyer1);
  
  PVector v1New = PVector.sub(v1,changeV1);
  
  // calculate v2New, the new velocity of other mover
  float massPart2 = 2*m1/(m1 + m2);
  PVector v2subv1 = PVector.sub(v2,v1);
  PVector cen2subCen1 = PVector.sub(cen2,cen1);
  float topBit2 = v2subv1.dot(cen2subCen1);
  float bottomBit2 = cen2subCen1.mag()*cen2subCen1.mag();
  
  float multiplyer2 = massPart2 * (topBit2/bottomBit2);
  PVector changeV2 = PVector.mult(cen2subCen1, multiplyer2);
  
  PVector v2New = PVector.sub(v2,changeV2);
  
  velocity.set(i,v1New.mult(e1)); //Include elasticity
  velocity.set(j,v2New.mult(e2)); //Include elasticity
  
  //Ensure no overlap
  float cumulativeRadii = (m1+m2)+2; // extra fudge factor
  float distanceBetween = cen1.dist(cen2);
  
  float overlap = cumulativeRadii - distanceBetween;
  if(overlap > 0){
    // move this away from other
    PVector vectorAwayFromOtherNormalized = PVector.sub(cen1, cen2).normalize();
    PVector amountToMove = PVector.mult(vectorAwayFromOtherNormalized, overlap);
    cen1.add(amountToMove);
  }
}

///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////
//                                     Camera code
///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////

final double mouseSens = 1.6;
double lastMousePos[] = {0,0};
int zoomIndex = 4;
double zoomLevels[] = {0,0,0,0,0,0,0,0,0};

void setZoomLevels() { int i; for (i=0; i<9; i++) zoomLevels[i] = 0.5 * Math.pow(2,i/4.0); }

void cameraCalc(double X_in, double Y_in) {
  double Xpos = (mouseSens/5) * X_in % 360; if (Xpos < 0) Xpos += 360;
  double Ypos = Y_in;
  if (Ypos <= 10) Ypos = -90; //Top
  else if (Ypos >= 490) Ypos = 90; //Bottom
  else Ypos = -90 + (3 * (Ypos - 10) / 8); //In-between
  double r = area_size*sqrt(3)*zoomLevels[zoomIndex];
  float center = area_size/2;
  
  Double x_D = new Double(r * Math.cos(Math.toRadians(Xpos)) + center);
  Double y_D = new Double(r * Math.sin(Math.toRadians(Ypos)) + center);
  Double z_D = new Double(r * Math.sin(Math.toRadians(Xpos)) - center);
  float x = x_D.floatValue();
  float y = y_D.floatValue();
  float z = z_D.floatValue();
  
  theCamera.setPositionAndLookat(vec(x, -y, z), vec(center,center,-center));
}

void mouseCamera() {
  if(mouseButton == RIGHT) {
    cameraCalc(mouseX,mouseY);
    lastMousePos[0] = mouseX;
    lastMousePos[1] = mouseY;
  } theCamera.update();
}

void mouseWheel(MouseEvent event) {
  float DIR = event.getCount();
  if (DIR > 0) { if (zoomIndex < 8) zoomIndex += 1; }
  else { if (zoomIndex > 0) zoomIndex -= 1; }
  cameraCalc(lastMousePos[0],lastMousePos[1]);
}
