/**
 * ScatterPlotPoint
 * A drawable scatter plot mark.
 */
 
class ScatterPlotPoint {
  
  float x;
  float y;
  color colour;
  int shape;
  float size;
  
  ScatterPlotPoint(float x, float y, color colour, int shape, float size) {
    this.x = x;
    this.y = y;
    this.colour = colour;
    this.shape = shape;
    this.size = size;
  }
  
  void draw() {
    pushMatrix();
    pushStyle();
      translate(x, y);
      drawShape(shape, size, colour);
    popStyle();
    popMatrix();
  }
  
}