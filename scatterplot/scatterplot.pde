/**
 * Scatterplot
 * Author: Charlie Chao
 * Context: Assignment 1 for IAT355 (Spring 2017)
 *
 * Data parsing is tailored for the Iris dataset.
 * UI layout is mostly hard-coded (many magic numbers unfortunately).
 */

import controlP5.*;
import java.util.*;

// Data
final static int NUMERICAL_ATTRIBUTES = 4;
String[] data;
String[][] dataParsed;
String[] dataDimensions;
float[] dataMin;
float[] dataMax;
String[] dataSpecies;

// Visualization
final color[] COLOUR_PALETTE = {
  // Based on http://ksrowell.com/blog-visualizing-data/2012/02/02/optimal-colors-for-graphs/
  color(57, 106, 177),
  color(218, 124, 48),
  color(204, 37, 41),
  color(107, 76, 154),
  color(62, 150, 81),
  color(83, 81, 84)
};
//final color GRADIENT_START = color(255, 0, 0);
//final color GRADIENT_END = color(0, 0, 255);
final color GRAPH_COLOR_LINE = color(225);
final static int SHAPE_CIRCLE = 0;
final static int SHAPE_SQUARE = 1;
final static int SHAPE_DIAMOND = 2;
final static int SHAPE_LINE_CIRCLE = 3;
final static int SHAPE_LINE_SQUARE = 4;
final static int SHAPE_LINE_DIAMOND = 5;
final static int SIZE_MIN = 4;
final static int SIZE_MAX = 48;
final static int SIZE_DEFAULT = 9;
ScatterPlotPoint[] points;
float[] xTickPos;
String[] xTickLabels;
float[] yTickPos;
String[] yTickLabels;
String xAxisLabel;
String yAxisLabel;
String shapeTitle;
String[] shapeLabels;
String colourTitle;
String[] colourLabels;
//float[] gradientTickPos;
//String[] gradientTickLabels;
String sizeTitle;
String[] sizeLabels;

// Metrics
final static int GRAPH_WIDTH = 600;
final static int GRAPH_HEIGHT = 380;
final static int GRAPH_PADDING_LEFT = 80;
final static int LINE_HEIGHT = 12;
//final static int GRADIENT_WIDTH = 20;
//final static int GRADIENT_HEIGHT = GRAPH_HEIGHT - 24;
final static int LEGENDS_SHAPE_SIZE = 10;
final static int LEGENDS_OFFSET_X = 728;
final static int OPTIONS_OFFSET_Y = 516;
final static int OPTIONS_CONTENT_OFFSET_X = 80;
final static int FILTERS_OFFSET_X = 266+58;

// Components
PFont fRegular;
PFont fBold;
color cOptionsBG;
ControlP5 cp5;
ScrollableList sclXAxis;
ScrollableList sclYAxis;
ScrollableList sclColour;
ScrollableList sclSize;
ScrollableList sclShape;
Range rSize;
Range[] rData;
Toggle[] togSpecies;
boolean isInitialized = false;

void setup() {

  int i;
  float val;
  String[] attrs;
  HashSet<String> speciesSet = new HashSet<String>();

  // Load and parse data
  data = loadStrings("IrisDataset.csv");
  dataMin = new float[NUMERICAL_ATTRIBUTES];
  for (i = 0; i < dataMin.length; i++) {
    dataMin[i] = Integer.MAX_VALUE;
  }
  dataMax = new float[NUMERICAL_ATTRIBUTES];
  dataParsed = new String[data.length - 1][NUMERICAL_ATTRIBUTES];
  for (i = 0; i < data.length; i++) {
    attrs = data[i].split(",");
    if (i == 0) {
      // Extract dimension names
      dataDimensions = attrs;
      continue;
    }
    dataParsed[i - 1] = attrs;
    speciesSet.add(attrs[4]);
    // Calculate dataMin/dataMax
    val = parseFloat(attrs[0]);
    if (val < dataMin[0]) {
      dataMin[0] = val;
    }
    if (val > dataMax[0]) {
      dataMax[0] = val;
    }
    val = parseFloat(attrs[1]);
    if (val < dataMin[1]) {
      dataMin[1] = val;
    }
    if (val > dataMax[1]) {
      dataMax[1] = val;
    }
    val = parseFloat(attrs[2]);
    if (val < dataMin[2]) {
      dataMin[2] = val;
    }
    if (val > dataMax[2]) {
      dataMax[2] = val;
    }
    val = parseFloat(attrs[3]);
    if (val < dataMin[3]) {
      dataMin[3] = val;
    }
    if (val > dataMax[3]) {
      dataMax[3] = val;
    }
  }

  // Setup UI
  cp5 = new ControlP5(this);
  fRegular = createFont("Arial", 12);
  fBold = loadFont("Arial-BoldMT-24.vlw");
  cOptionsBG = color(#333333);

  // Add mapping dropdowns
  rSize = cp5.addRange("Mark size")
    .setPosition(OPTIONS_CONTENT_OFFSET_X + 140, OPTIONS_OFFSET_Y + 160)
    .setWidth(128)
    .setHeight(18)
    .setDecimalPrecision(0)
    .setRange(SIZE_MIN, SIZE_MAX)
    .setLowValue(SIZE_DEFAULT)
    .setColorCaptionLabel(cOptionsBG);
  sclSize = cp5.addScrollableList("Size")
    .setPosition(OPTIONS_CONTENT_OFFSET_X + 140, OPTIONS_OFFSET_Y + 136);
  customizeMappingList(sclSize, dataDimensions, 4);
  sclShape = cp5.addScrollableList("Shape")
    .setPosition(OPTIONS_CONTENT_OFFSET_X + 140, OPTIONS_OFFSET_Y + 112);
  customizeMappingList(sclShape, dataDimensions, 5);
  sclColour = cp5.addScrollableList("Colour")
    .setPosition(OPTIONS_CONTENT_OFFSET_X + 140, OPTIONS_OFFSET_Y + 88);
  customizeMappingList(sclColour, dataDimensions, 3);
  sclYAxis = cp5.addScrollableList("y-axis")
    .setPosition(OPTIONS_CONTENT_OFFSET_X + 140, OPTIONS_OFFSET_Y + 64);
  customizeMappingList(sclYAxis, dataDimensions, 2);
  sclXAxis = cp5.addScrollableList("x-axis")
    .setPosition(OPTIONS_CONTENT_OFFSET_X + 140, OPTIONS_OFFSET_Y + 40);
  customizeMappingList(sclXAxis, dataDimensions, 1);

  // Add filters controls
  rData = new Range[NUMERICAL_ATTRIBUTES];
  for (i = 0; i < rData.length; i++) {
    rData[i] = cp5.addRange("data" + i)
      .setPosition(OPTIONS_CONTENT_OFFSET_X + FILTERS_OFFSET_X + 130, OPTIONS_OFFSET_Y + 40 + (24 * i));
    customizeNumberRange(rData[i], floor(dataMin[i]), ceil(dataMax[i]));
  }

  // Add species toggle
  dataSpecies = speciesSet.toArray(new String[speciesSet.size()]);
  togSpecies = new Toggle[dataSpecies.length];
  for (i = 0; i < dataSpecies.length; i++) {
    togSpecies[i] = cp5.addToggle(dataSpecies[i])
      .setPosition(OPTIONS_CONTENT_OFFSET_X + FILTERS_OFFSET_X + (48 + 6) * i, OPTIONS_OFFSET_Y + 136)
      .setSize(48, 18)
      .setValue(true);
  }

  // Setup display
  size(900, 720, P2D);
  pixelDensity(2);

  isInitialized = true;
  updateVis();

}

void customizeMappingList(ScrollableList scl, String[] items, int defaultIndex) {
  ArrayList<String> listItems = new ArrayList<String>(Arrays.asList(items));
  listItems.add(0, "None");
  scl
    .addItems(listItems)
    .setBarHeight(18)
    .setItemHeight(18)
    .setBackgroundColor(color(#002D5A))
    .setValue(defaultIndex)
    .setSize(128, (int)(height - scl.getPosition()[1]));
}

void customizeNumberRange(Range r, int dataMin, int dataMax) {
  r.setWidth(172)
    .setHeight(18)
    .setDecimalPrecision(1)
    .setRange(dataMin, dataMax)
    .setColorCaptionLabel(cOptionsBG);
}

// Updates vis variables based on user input
void updateVis() {

  if (!isInitialized) {
    return;
  }

  int i, index, count, shape,
    indexXAxis, indexYAxis, indexShape, indexColour, indexSize;
  float x, y, size,
    min, max,
    segmentLength, segmentVal,
    value,
    colourMinVal = 0,
    colourSegmentVal = 0,
    shapeMinVal = 0,
    shapeSegmentVal = 0;
  color colour;
  ArrayList<String> speciesList = new ArrayList<String>();
  String[] species;
  ArrayList<ScatterPlotPoint> newPoints = new ArrayList<ScatterPlotPoint>();

  // Reset variables
  xTickPos = new float[0];
  xTickLabels = new String[0];
  yTickPos = new float[0];
  yTickLabels = new String[0];
  xAxisLabel = "";
  yAxisLabel = "";
  points = new ScatterPlotPoint[0];
  shapeTitle = "";
  shapeLabels = new String[0];
  colourTitle = "";
  colourLabels = new String[0];
  //gradientTickPos = new float[0];
  //gradientTickLabels = new String[0];
  sizeTitle = "";
  sizeLabels = new String[0];

  // Get species list
  for (i = 0; i < togSpecies.length; i++) {
    if (togSpecies[i].getValue() == 1) {
      speciesList.add(togSpecies[i].getName());
    }
  }
  species = speciesList.toArray(new String[speciesList.size()]);

  // x-axis
  indexXAxis = (int)sclXAxis.getValue();
  index = indexXAxis - 1;
  switch (indexXAxis) {
    case 1: case 2: case 3: case 4:
      // Numerical
      min = floor(dataMin[index]);
      max = ceil(dataMax[index]);
      count = (int)max - (int)min + 1;
      segmentLength = (float)GRAPH_WIDTH / (count - 1);
      segmentVal = (max - min) / (count - 1);
      xTickPos = new float[count];
      xTickLabels = new String[count];
      for (i = 0; i < count; i++) {
        xTickPos[i] = i * segmentLength;
        xTickLabels[i] = String.format("%.1f", min + segmentVal * i);
      }
      break;
    case 5:
      // Categorical (species)
      count = species.length;
      segmentLength = (float)GRAPH_WIDTH / (count + 1);
      xTickPos = new float[count];
      xTickLabels = new String[count];
      for (i = 0; i < count; i++) {
        xTickPos[i] = segmentLength + i * segmentLength;
        xTickLabels[i] = species[i];
      }
      break;
  }
  if (indexXAxis != 0) {
    xAxisLabel =  sclXAxis.getItem(indexXAxis).get("text").toString();
  }

  // y-axis
  indexYAxis = (int)sclYAxis.getValue();
  index = indexYAxis - 1;
  switch (indexYAxis) {
    case 1: case 2: case 3: case 4:
      // Numerical data
      min = floor(dataMin[index]);
      max = ceil(dataMax[index]);
      count = (int)max - (int)min + 1;
      segmentLength = (float)GRAPH_HEIGHT / (count - 1);
      segmentVal = (max - min) / (count - 1);
      yTickPos = new float[count];
      yTickLabels = new String[count];
      for (i = 0; i < count; i++) {
        yTickPos[i] = GRAPH_HEIGHT - i * segmentLength;
        yTickLabels[i] = String.format("%.1f", min + segmentVal * i);
      }
      break;
    case 5:
      // Categorical (species)
      count = species.length;
      segmentLength = (float)GRAPH_HEIGHT / (count + 1);
      yTickPos = new float[count];
      yTickLabels = new String[count];
      for (i = 0; i < count; i++) {
        yTickPos[i] = segmentLength + i * segmentLength;
        yTickLabels[i] = species[i];
      }
      break;
  }
  if (indexYAxis != 0) {
    yAxisLabel =  sclYAxis.getItem(indexYAxis).get("text").toString();
  }

  // Colour/gradient
  indexColour = (int)sclColour.getValue();
  index = indexColour - 1;
  switch (indexColour) {
    case 1: case 2: case 3: case 4:
      // Numerical
      colourMinVal = min = rData[index].getLowValue();
      max = rData[index].getHighValue();
      count = (int)max - (int)min;
      colourSegmentVal = segmentVal = (max - min) / count;
      colourLabels = new String[count];
      for (i = 0; i < count; i++) {
        colourLabels[i] = String.format("%.1f - %.1f", min + segmentVal * i, min + segmentVal * (i + 1) - 0.1);
      }
      //min = rData[index].getLowValue();
      //max = rData[index].getHighValue();
      //count = (int)max - (int)min + 1;
      //segmentLength = (float)GRADIENT_HEIGHT / (count - 1);
      //segmentVal = (max - min) / (count - 1);
      //gradientTickPos = new float[count];
      //gradientTickLabels = new String[count];
      //for (i = 0; i < count; i++) {
      //  gradientTickPos[i] = GRADIENT_HEIGHT - i * segmentLength;
      //  gradientTickLabels[i] = String.format("%.1f", min + segmentVal * i);
      //}
      break;
    case 5:
      // Categorical (species)
      colourLabels = species;
      break;
  }
  if (indexColour != 0) {
    colourTitle = sclColour.getItem(indexColour).get("text").toString();
  }

  // Shape
  indexShape = (int)sclShape.getValue();
  index = indexShape - 1;
  switch (indexShape) {
    case 1: case 2: case 3: case 4:
      // Numerical
      shapeMinVal = min = rData[index].getLowValue();
      max = rData[index].getHighValue();
      count = (int)max - (int)min;
      shapeSegmentVal = segmentVal = (max - min) / count;
      shapeLabels = new String[count];
      for (i = 0; i < count; i++) {
        shapeLabels[i] = String.format("%.1f - %.1f", min + segmentVal * i, min + segmentVal * (i + 1) - 0.1);
      }
      break;
    case 5:
      // Categorical (species)
      shapeLabels = species;
      break;
  }
  if (indexShape != 0) {
    shapeTitle = sclShape.getItem(indexShape).get("text").toString();
  }

  // Size
  indexSize = (int)sclSize.getValue();
  index = indexSize - 1;
  switch (indexSize) {
    case 1: case 2: case 3: case 4:
      // Numerical
      min = rData[index].getLowValue();
      max = rData[index].getHighValue();
      count = (int)max - (int)min;
      segmentVal = (max - min) / count;
      sizeLabels = new String[count];
      for (i = 0; i < count; i++) {
        sizeLabels[i] = String.format("%.1f - %.1f", min + segmentVal * i, min + segmentVal * (i + 1) - 0.1);
      }
      break;
    case 5:
      // Categorical (species)
      sizeLabels = species;
      break;
  }
  if (indexSize != 0) {
    sizeTitle = sclSize.getItem(indexSize).get("text").toString();
  }

  // Marks
  for (i = 0; i < dataParsed.length; i++) {
    // x position
    x = 0;
    index = indexXAxis - 1;
    switch(indexXAxis) {
      case 1: case 2: case 3: case 4:
        value = parseFloat(dataParsed[i][index]);
        x = map(value, floor(dataMin[index]), ceil(dataMax[index]), 0, GRAPH_WIDTH);
        if (value < rData[index].getLowValue() || value > rData[index].getHighValue()) {
          continue;
        }
        break;
      case 5:
        value = speciesList.indexOf(dataParsed[i][index]);
        if (value == -1) {
          continue;
        }
        segmentLength = (GRAPH_WIDTH / (species.length + 1));
        x = segmentLength + segmentLength * value;
        break;
    }
    // y position
    y = 0;
    index = indexYAxis - 1;
    switch(indexYAxis) {
      case 1: case 2: case 3: case 4:
        value = parseFloat(dataParsed[i][index]);
        y = map(value, floor(dataMin[index]), ceil(dataMax[index]), GRAPH_HEIGHT, 0);
        if (value < rData[index].getLowValue() || value > rData[index].getHighValue()) {
          continue;
        }
        break;
      case 5:
        value = speciesList.indexOf(dataParsed[i][index]);
        if (value == -1) {
          continue;
        }
        segmentLength = (GRAPH_HEIGHT / (species.length + 1));
        y = segmentLength + segmentLength * value;
        break;
    }
    colour = color(0);
    index = indexColour - 1;
    switch(indexColour) {
      case 1: case 2: case 3: case 4:
        value = parseFloat(dataParsed[i][index]);
        if (value < rData[index].getLowValue() || value > rData[index].getHighValue()) {
          continue;
        }
        colour = COLOUR_PALETTE[floor((value - colourMinVal) / colourSegmentVal)];
        //colour = lerpColor(GRADIENT_START, GRADIENT_END, map(value, dataMin[index], dataMax[index], 0, 1));
        break;
      case 5:
        value = speciesList.indexOf(dataParsed[i][index]);
        if (value == -1) {
          continue;
        }
        colour = COLOUR_PALETTE[(int)value];
        break;
    }
    // Shape
    shape = 0;
    index = indexShape - 1;
    switch(indexShape) {
      case 1: case 2: case 3: case 4:
        value = parseFloat(dataParsed[i][index]);
        if (value < rData[index].getLowValue() || value > rData[index].getHighValue()) {
          continue;
        }
        shape = floor((value - shapeMinVal) / shapeSegmentVal);
        break;
      case 5:
        shape = speciesList.indexOf(dataParsed[i][index]);
        if (shape == -1) {
          continue;
        }
        break;
    }
    // Size
    size = (int)rSize.getLowValue();
    index = indexSize - 1;
    switch(indexSize) {
       case 1: case 2: case 3: case 4:
         value = parseFloat(dataParsed[i][index]);
         size = map(value, dataMin[index], dataMax[index], (int)rSize.getLowValue(), (int)rSize.getHighValue());
         if (value < rData[index].getLowValue() || value > rData[index].getHighValue()) {
           continue;
         }
         break;
       case 5:
         value = speciesList.indexOf(dataParsed[i][index]);
         if (value == -1) {
           continue;
         }
         size = map(value, 0, speciesList.size(), (int)rSize.getLowValue(), (int)rSize.getHighValue());
         break;
    }
    if (indexSize != 0) {
      // Make colour transparent to see overlaps
      // https://processing.org/discourse/beta/num_1261125421.html
      colour = (colour & 0xffffff) | (128 << 24);
    }
    newPoints.add(new ScatterPlotPoint(x, y, colour, shape, size));
  }
  points = newPoints.toArray(new ScatterPlotPoint[newPoints.size()]);

}

// Handles user input changes
void controlEvent(ControlEvent event) {
  updateVis();
}

void drawShape(int type, float size, color c) {
  int strokeWeight = 2;
  pushStyle();
    noStroke();
    strokeWeight(strokeWeight);
    fill(c);
    if (type == SHAPE_LINE_SQUARE ||
      type == SHAPE_LINE_DIAMOND ||
      type == SHAPE_LINE_CIRCLE) {
        noFill();
        stroke(c);
        size -= strokeWeight;
    }
    switch (type) {
      case SHAPE_SQUARE:
      case SHAPE_LINE_SQUARE:
        rectMode(CENTER);
        rect(0, 0, size, size);
        break;
      case SHAPE_DIAMOND:
      case SHAPE_LINE_DIAMOND:
        pushMatrix();
          rotate(PI/4);
          rectMode(CENTER);
          rect(0, 0, size * 0.9, size * 0.9);
        popMatrix();
        break;
      case SHAPE_CIRCLE:
      case SHAPE_LINE_CIRCLE:
      default:
        ellipseMode(CENTER);
        ellipse(0, 0, size, size);
        break;
    }
  popStyle();
}

void drawGraph() {

  int i;

  // y-axis label
  pushMatrix();
  pushStyle();
    rotate(-PI/2);
    fill(color(0));
    textAlign(CENTER, TOP);
    text(yAxisLabel, -GRAPH_HEIGHT / 2, 0);
  popStyle();
  popMatrix();

  // x-axis label
  pushMatrix();
  pushStyle();
    translate(GRAPH_PADDING_LEFT + GRAPH_WIDTH / 2, GRAPH_HEIGHT + 36 + LINE_HEIGHT);
    fill(color(0));
    textAlign(CENTER);
    text(xAxisLabel, 0, 0);
  popStyle();
  popMatrix();

  pushStyle();
    fill(color(0));
    stroke(color(0));
    textFont(fRegular, 10);
    // x-axis ticks
    pushMatrix();
      translate(GRAPH_PADDING_LEFT, GRAPH_HEIGHT);
      for (i = 0; i < xTickPos.length; i++) {
        line(xTickPos[i], 0, xTickPos[i], 6);
        pushStyle();
          stroke(color(GRAPH_COLOR_LINE));
          line(xTickPos[i], 0, xTickPos[i], -GRAPH_HEIGHT + 1);
        popStyle();
        textAlign(CENTER, TOP);
        text(xTickLabels[i], xTickPos[i], 10);
      }
    popMatrix();
    // y-axis ticks
    pushMatrix();
      translate(GRAPH_PADDING_LEFT, 0);
      for (i = 0; i < yTickPos.length; i++) {
        line(-6, yTickPos[i], 0, yTickPos[i]);
        pushStyle();
          stroke(color(GRAPH_COLOR_LINE));
          line(1, yTickPos[i], GRAPH_WIDTH - 1, yTickPos[i]);
        popStyle();
        textAlign(RIGHT, CENTER);
        text(yTickLabels[i], -10, yTickPos[i]);
      }
    popMatrix();
  popStyle();

  // Marks
  pushMatrix();
    translate(GRAPH_PADDING_LEFT, 0);
    for (i = 0; i < points.length; i++) {
      points[i].draw();
    }
  popMatrix();

  // Boundary
  pushStyle();
    stroke(color(0));
    strokeWeight(1);
    rect(GRAPH_PADDING_LEFT, 0, GRAPH_WIDTH, GRAPH_HEIGHT);
  popStyle();

}

//void drawGradient(int x, int y, int w, int h, color c1, color c2) {
//  for (int i = y; i <= (y + h); i++) {
//    float inter = map(i, y, (y + h), 0, 1);
//    color c = lerpColor(c1, c2, inter);
//    stroke(c);
//    line(x, i, x + w, i);
//  }
//}

void drawLegends() {

  int i,
    offsetX = 0,
    offsetY = 0;
  float size;

  pushStyle();
    fill(color(0));
    textAlign(LEFT);

    // Gradient mapping
    //if (gradientTickPos.length > 0) {
    //  offsetX = 96;
    //  // Draw title
    //  textFont(fBold, 12);
    //  text(colourTitle, 0, LINE_HEIGHT);
    //  pushMatrix();
    //  pushStyle();
    //    translate(0, 24);
    //    // Gradient
    //    drawGradient(0, 0, GRADIENT_WIDTH, GRADIENT_HEIGHT, GRADIENT_START, GRADIENT_END);
    //    for (i = 0; i < gradientTickPos.length; i++) {
    //      stroke(color(255));
    //      if (i > 0 && i < gradientTickPos.length - 1) {
    //        // Tick
    //        line(GRADIENT_WIDTH - 6, gradientTickPos[i], GRADIENT_WIDTH, gradientTickPos[i]);
    //      }
    //      // Label
    //      textAlign(LEFT, CENTER);
    //      textFont(fRegular, 10);
    //      text(gradientTickLabels[i], GRADIENT_WIDTH + 6, gradientTickPos[i]);
    //    }
    //  popStyle();
    //  popMatrix();
    //}

    // Shape legends
    if (shapeLabels.length > 0) {
      pushMatrix();
        translate(offsetX, offsetY);
        // Title
        textFont(fBold, 12);
        text(shapeTitle, 0, LINE_HEIGHT);
        textFont(fRegular, 12);
        pushMatrix();
          translate(0, 18);
          for (i = 0; i < shapeLabels.length; i++) {
            // Shape
            pushMatrix();
              translate(LEGENDS_SHAPE_SIZE / 2, (18 * i) + (LEGENDS_SHAPE_SIZE / 2) + 4);
              drawShape(i, LEGENDS_SHAPE_SIZE, color(0));
            popMatrix();
            // Label
            text(shapeLabels[i], LEGENDS_SHAPE_SIZE + 6, (18 * i) + LINE_HEIGHT);
          }
        popMatrix();
      popMatrix();
      offsetY += shapeLabels.length * 18 + 24;
    }

    // Colour legends
    if (colourLabels.length > 0) {
      pushMatrix();
        translate(offsetX, offsetY);
        // Title
        textFont(fBold, 12);
        text(colourTitle, 0, LINE_HEIGHT);
        textFont(fRegular, 12);
        pushMatrix();
          translate(0, 18);
          for (i = 0; i < colourLabels.length; i++) {
            // Colour box
            fill(COLOUR_PALETTE[i]);
            rectMode(CORNER);
            rect(0, (18 * i) + 4, 16, 10);
            fill(color(0));
            // Label
            text(colourLabels[i], 22, (18 * i) + LINE_HEIGHT);
          }
        popMatrix();
      popMatrix();
      offsetY += colourLabels.length * 18 + 24;
    }

    // Size legends
    if (sizeLabels.length > 0) {
      pushMatrix();
        translate(offsetX, offsetY);
        // Title
        textFont(fBold, 12);
        text(sizeTitle, 0, LINE_HEIGHT);
        textFont(fRegular, 12);
        pushMatrix();
          translate(0, 18);
          for (i = 0; i < sizeLabels.length; i++) {
            // Size preview
            size = map(i, 0, sizeLabels.length, (int)rSize.getLowValue(), (int)rSize.getHighValue());
            pushMatrix();
              translate(LEGENDS_SHAPE_SIZE / 2, (18 * i) + (LEGENDS_SHAPE_SIZE / 2) + 4);
              drawShape(0, size, color(0, 0, 0, 128));
            popMatrix();
            fill(color(0));
            // Label
            text(sizeLabels[i], LEGENDS_SHAPE_SIZE + 6, (18 * i) + LINE_HEIGHT);
          }
        popMatrix();
      popMatrix();
    }

   popStyle();

}

void drawOptions() {
  pushStyle();
    // Background
    fill(cOptionsBG);
    rect(0, 0, width, 206);
    // Mapping labels
    fill(color(255));
    textAlign(LEFT);
    textFont(fBold, 12);
    text("Mapping", OPTIONS_CONTENT_OFFSET_X + 24, 18 + LINE_HEIGHT);
    textFont(fRegular, 12);
    text("x-axis", OPTIONS_CONTENT_OFFSET_X + 24, 42 + LINE_HEIGHT);
    text("y-axis", OPTIONS_CONTENT_OFFSET_X + 24, 64 + LINE_HEIGHT);
    text("Colour", OPTIONS_CONTENT_OFFSET_X + 24, 86 + LINE_HEIGHT);
    text("Shape", OPTIONS_CONTENT_OFFSET_X + 24, 108 + LINE_HEIGHT);
    text("Size", OPTIONS_CONTENT_OFFSET_X + 24, 134 + LINE_HEIGHT);
    text("Mark size", OPTIONS_CONTENT_OFFSET_X + 24, 160 + LINE_HEIGHT);
    // Filters labels
    textFont(fBold, 12);
    text("Filters", OPTIONS_CONTENT_OFFSET_X + FILTERS_OFFSET_X, 18 + LINE_HEIGHT);
    textFont(fRegular, 12);
    text("Sepal Length range", OPTIONS_CONTENT_OFFSET_X + FILTERS_OFFSET_X, 42 + LINE_HEIGHT);
    text("Sepal Width range", OPTIONS_CONTENT_OFFSET_X + FILTERS_OFFSET_X, 64 + LINE_HEIGHT);
    text("Petal Length range", OPTIONS_CONTENT_OFFSET_X + FILTERS_OFFSET_X, 86 + LINE_HEIGHT);
    text("Petal Width range", OPTIONS_CONTENT_OFFSET_X + FILTERS_OFFSET_X, 108 + LINE_HEIGHT);
  popStyle();
}

void draw() {

  // Clear
  background(255);
  noStroke();
  noFill();
  textAlign(LEFT, BASELINE);
  textFont(fRegular, 12);

  // Title
  pushStyle();
    fill(color(0));
    textAlign(CENTER);
    textFont(fBold, 12);
    text("Iris Dataset", width / 2, 24 + LINE_HEIGHT);
  popStyle();

  // Graph
  pushMatrix();
    translate(24, 60);
    drawGraph();
  popMatrix();

  // Legends
  pushMatrix();
    translate(LEGENDS_OFFSET_X, 60);
    drawLegends();
  popMatrix();

  // Options
  pushMatrix();
    translate(0, OPTIONS_OFFSET_Y);
    drawOptions();
  popMatrix();

}