PImage mapimg;
Table sim_file;

float clat = 39.8283;
float clon = -95.5795;

int ww = 1024;
int hh = 512;
float zoom = 3.3;

class ipLocation
{
  float latitude;
  float longitude;
  float x;
  float y;
  float clat = 39.8283;
  float clon = -95.5795;
  float zoom = 3.3;
  float avgRequest;
  int requestCount;
  
  ipLocation(float latitude, float longitude)
  {
    this.latitude = latitude;
    this.longitude = longitude;
    this.x = this.mercX(longitude) - this.mercX(clon);
    this.y =this. mercY(latitude) - this.mercY(clat);
  }
  
  ipLocation(float latitude, float longitude, int requestCount, float avgRequest)
  {
    this.latitude = latitude;
    this.longitude = longitude;
    this.x = this.mercX(longitude) - this.mercX(clon);
    this.y =this. mercY(latitude) - this.mercY(clat);
    this.avgRequest = avgRequest;
    this.requestCount = requestCount;
  }

  float mercX(float lon) {
    lon = radians(lon);
    float a = (256 / PI) * pow(2, zoom);
    float b = lon + PI;
    return a * b;
  }
  
  float mercY(float lat) {
    lat = radians(lat);
    float a = (256 / PI) * pow(2, zoom);
    float b = tan(PI / 4 + lat / 2);
    float c = PI - log(b);
    return a * c;
  }
}

void drawMap()
{
  // The clon and clat in this url are edited to be in the correct order.
  String url = "https://api.mapbox.com/styles/v1/mapbox/dark-v9/static/" +
    clon + "," + clat + "," + zoom + "/" +
    ww + "x" + hh +
    "?access_token=pk.eyJ1IjoiY29kaW5ndHJhaW4iLCJhIjoiY2l6MGl4bXhsMDRpNzJxcDh0a2NhNDExbCJ9.awIfnl6ngyHoB3Xztkzarw";
  mapimg = loadImage(url, "jpg");
  //println(url);

  translate(width / 2, height / 2);
  imageMode(CENTER);
  image(mapimg, 0, 0); 
  
  
  fill(255, 0, 255, 255);
  ellipse(home.x, home.y, 6, 6);
  
  fill(255, 0, 255, 255);
  ellipse(target.x, target.y, 6, 6);
}

void drawCurvePoints(ipLocation base, ipLocation destination, int numPoints, int currentStep, int steps, int r, int g, int b, int a, int sourceOffset, int destOffset, float speed)
{
  for(int i = 0; i < numPoints; i++)
  {
    float t = (currentStep-i) / float(steps) * speed;
    float x = curvePoint(base.x, base.x, destination.x, destination.x, t);
    float y = curvePoint(base.y+sourceOffset, base.y, destination.y, destination.y+destOffset, t);
    noStroke();
    fill(r, g, b, a);
    if (t >= 0 && t <= 1)
    {
      ellipse(x, y, 2, 2);
    }
  }
}

int totalRequests = 0;

ArrayList<ipLocation> getCsv()
{
  totalRequests = 0;
  sim_file = loadTable("C:/Users/Gabe/Desktop/diver_webapp/NoSQL/sim_file.csv");
  
  ArrayList<ipLocation> simVals = new ArrayList<ipLocation>();
  int total_requests = 0;
  
  for (TableRow row : sim_file.rows()) 
  {
    String requests = row.getString(4);
    total_requests += int(requests);
  }
  ipLocation rowData = null;
  for (TableRow row : sim_file.rows()) 
  {  
    //String label = row.getString("label");
    //String ip = row.getString("ip");
    String lat = row.getString(2);
    String lon = row.getString(3);
    String requests = row.getString(4);
    //println(requests);
    totalRequests += int(requests);
    String avgRequest = row.getString(5);
    //println(requests);
    rowData = new ipLocation(float(lat), float(lon), int(requests), float(avgRequest));
    
    noFill();
    float percentage = float(requests) / float(total_requests);
    stroke(255, 0, 255, (255*percentage));
    fill(255, 0, 255);
    simVals.add(rowData);
  }
  return simVals;
}

void setup()
{
  size(1024, 512);
  frameRate(fps);
}

int fps = 30;
boolean csvTrigger = true;
ArrayList<ipLocation> simVals = new ArrayList<ipLocation>();
//simVals = getCsv();
int steps = 750;
int currentStep = 0;
int trailCount = 10;
boolean homeToProxyDone = false;
boolean proxyToDestDone = true;
boolean DestToProxyDone = true;
boolean proxyToHomeDone = true;

ipLocation home = new ipLocation(33.587, -101.865);
ipLocation target = new ipLocation(40.7313, -73.9901);

int[] getRedGreen(int proxyRequests)
{
  int[] rg_arr = new int[2];
  int endNum = int((float(proxyRequests)/float(totalRequests)) * 560);
  //println(float(proxyRequests)/float(totalRequests));
  if (endNum <= 255)
  {
    rg_arr[0] = 255;
    rg_arr[1] = endNum;
  }
  else
  {
    rg_arr[0] = 255 - (endNum - 255);
    rg_arr[1] = 255;
  }
  return rg_arr;
}

void draw()
{
  drawMap();
  //ArrayList<ipLocation> simVals = new ArrayList<ipLocation>();
  if (currentStep > (steps + trailCount))
  {
    currentStep = 0;
    if (homeToProxyDone == false)
    {
      homeToProxyDone = true;
      proxyToDestDone = false;
    }
    else if (proxyToDestDone == false)
    {
      proxyToDestDone = true;
      DestToProxyDone = false;
    }
    else if (DestToProxyDone == false)
    {
      DestToProxyDone = true;
      proxyToHomeDone = false;
    }
    else if (proxyToHomeDone == false)
    {
      proxyToHomeDone = true;
      homeToProxyDone = false;
      csvTrigger = true;
    }
    
  }
  for (ipLocation proxy : simVals)
  {
      fill(255, 0, 255);
      ellipse(proxy.x, proxy.y, 6, 6);
  }
  if (csvTrigger == true)
  {
    simVals = getCsv();
    csvTrigger = false;
  }
  else if (homeToProxyDone == false)
  {
      for (ipLocation proxy : simVals)
      {
          int[] rgVals = getRedGreen(proxy.requestCount);
          //println(rgVals);
          drawCurvePoints(home, proxy, trailCount, currentStep, steps, rgVals[0], rgVals[1], 0, 255, 300, 300, proxy.avgRequest);
          drawCurvePoints(home, proxy, trailCount, currentStep, steps, 0, 0, 0, 55, 0, 0, proxy.avgRequest);
          currentStep ++;
      }
  }
  else if (proxyToDestDone == false)
  {
      for (ipLocation proxy : simVals)
      {
          int[] rgVals = getRedGreen(proxy.requestCount);
          drawCurvePoints(proxy, target, trailCount, currentStep, steps, rgVals[0], rgVals[1], 0, 255, 300, 300, proxy.avgRequest);
          drawCurvePoints(proxy, target, trailCount, currentStep, steps, 0, 0, 0, 55, 0, 0, proxy.avgRequest);
          currentStep ++;
      }   
  }
  else if (DestToProxyDone == false)
  {
      for (ipLocation proxy : simVals)
      {
          int[] rgVals = getRedGreen(proxy.requestCount);
          drawCurvePoints(target, proxy, trailCount, currentStep, steps, rgVals[0], rgVals[1], 0, 255, 300, 300, proxy.avgRequest);
          drawCurvePoints(target, proxy, trailCount, currentStep, steps, 0, 0, 0, 55, 0, 0, proxy.avgRequest);
          currentStep ++;
      }   
  }
  else if (proxyToHomeDone == false)
  {
      for (ipLocation proxy : simVals)
      {
          int[] rgVals = getRedGreen(proxy.requestCount);
          drawCurvePoints(proxy, home, trailCount, currentStep, steps, rgVals[0], rgVals[1], 0, 255, 300, 300, proxy.avgRequest);
          drawCurvePoints(proxy, home, trailCount, currentStep, steps, 0, 0, 0, 55, 0, 0, proxy.avgRequest);
          currentStep ++;
      }   
  }
}
